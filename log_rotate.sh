#!/bin/bash
# log_rotate.sh - Compress and remove old log files
# 
# Copyright (C) 2025 Coffey Labs LLC
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the 
# Free Software Foundation, version 3 of the License.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program. If not, see <https://www.gnu.org/licenses/>.
# 
# Usage: log_rotate.sh [--days N] [--purge-days N] [--dry-run] [--yes]
#   --days N         compress .log files older than N days (default 7)
#   --purge-days N   delete .gz archives older than N days (default: never)
#   --dry-run        show what would happen, change nothing
#   --yes            skip the confirmation prompt for --purge-days
# Description: Compresses old .log files under /var/log, and optionally
#   deletes old .gz archives.
#
# NOTE: this is a convenience wrapper, not a logrotate replacement. It
# does not signal daemons or truncate in place, so it only touches files
# nothing currently holds open -- see the comment above compress_logs.

set -euo pipefail

DAYS=7
PURGE_DAYS=""
DRY_RUN=false
ASSUME_YES=false
LOG_DIR=/var/log

while [ $# -gt 0 ]; do
  case "$1" in
    --days)
      [ "${2:-}" ] && [[ "$2" =~ ^[0-9]+$ ]] || { echo "--days needs a number" >&2; exit 1; }
      DAYS="$2"; shift ;;
    --purge-days)
      [ "${2:-}" ] && [[ "$2" =~ ^[0-9]+$ ]] || { echo "--purge-days needs a number" >&2; exit 1; }
      PURGE_DAYS="$2"; shift ;;
    --dry-run) DRY_RUN=true ;;
    --yes)     ASSUME_YES=true ;;
    -h|--help) sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    [0-9]*)
      # Backwards compatibility: the old interface was a bare day count.
      DAYS="$1" ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root to rotate system logs." >&2
  exit 1
fi

# Compressing a log a daemon still holds open loses data: gzip writes
# the .gz and unlinks the original, but the daemon keeps writing to the
# now-unlinked inode, and those writes are unreachable. Real logrotate
# avoids this with copytruncate or a postrotate signal. We have neither,
# so skip any file that is currently open and leave it for logrotate.
file_is_open() {
  command -v lsof >/dev/null 2>&1 || return 1
  lsof -- "$1" >/dev/null 2>&1
}

compress_logs() {
  local count=0 skipped=0 f
  echo "Compressing *.log older than $DAYS days under $LOG_DIR..."
  while IFS= read -r -d '' f; do
    if file_is_open "$f"; then
      echo "  skip (open by a running process): $f"
      skipped=$((skipped + 1))
      continue
    fi
    if [ "$DRY_RUN" = true ]; then
      echo "  would compress: $f"
    else
      gzip -- "$f" && echo "  compressed: $f"
    fi
    count=$((count + 1))
  done < <(find "$LOG_DIR" -type f -name '*.log' -mtime +"$DAYS" ! -name '*.gz' -print0)
  echo "Compressed $count file(s); skipped $skipped still open."
  if ! command -v lsof >/dev/null 2>&1; then
    echo "WARNING: lsof not installed -- could not check whether files were open." >&2
  fi
}

purge_archives() {
  local list count
  list="$(find "$LOG_DIR" -type f -name '*.gz' -mtime +"$PURGE_DAYS" -print)"
  count="$(printf '%s' "$list" | grep -c . || true)"

  if [ "$count" -eq 0 ]; then
    echo "No .gz archives older than $PURGE_DAYS days."
    return 0
  fi

  echo "$count archive(s) older than $PURGE_DAYS days:"
  printf '%s\n' "$list" | head -n 10 | sed 's/^/  /'
  [ "$count" -gt 10 ] && echo "  ... and $((count - 10)) more"

  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: nothing deleted."
    return 0
  fi

  if [ "$ASSUME_YES" != true ]; then
    if [ ! -t 0 ]; then
      echo "Refusing to delete without confirmation; pass --yes for unattended runs." >&2
      exit 1
    fi
    read -r -p "Permanently delete these $count archive(s)? (yes/NO): " reply
    [ "$reply" = "yes" ] || { echo "Cancelled."; return 0; }
  fi

  printf '%s\n' "$list" | while IFS= read -r f; do
    [ -n "$f" ] && rm -f -- "$f"
  done
  echo "Deleted $count archive(s)."
}

compress_logs

# Deletion is opt-in. This previously ran unconditionally at 90 days,
# with no flag, no dry-run and no confirmation -- which quietly destroyed
# archives on hosts with longer retention requirements.
if [ -n "$PURGE_DAYS" ]; then
  purge_archives
else
  echo "No --purge-days given; existing .gz archives left alone."
fi
