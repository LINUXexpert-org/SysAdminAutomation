#!/bin/bash

# rsync_magic.sh - A smart, feature-rich rsync wrapper for safe and powerful file synchronization.
# 
# Copyright (C) 2025 Coffey Labs
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

set -euo pipefail

# ======= Configuration =======
LOG_FILE="/var/log/rsync_magic.log"
EXCLUDES="/etc/rsync_magic_excludes.txt"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# ======= Help Function =======
usage() {
  echo "Usage: $0 [--dry-run] [--inplace] [--yes] <source> <destination>"
  echo "  --dry-run   simulate the sync, change nothing"
  echo "  --inplace   write into destination files directly (see note below)"
  echo "  --yes       skip the confirmation prompt for --delete"
  exit 1
}

# ======= Argument Parsing =======
DRY_RUN=0
INPLACE=0
ASSUME_YES=0

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --inplace) INPLACE=1 ;;
    --yes)     ASSUME_YES=1 ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
  shift
done

SOURCE="${1:-}"
DEST="${2:-}"

if [[ -z "$SOURCE" || -z "$DEST" ]]; then
  usage
fi

if [[ ! -d "$SOURCE" ]]; then
  echo "Error: Source directory '$SOURCE' not found!"
  exit 2
fi

mkdir -p "$DEST"

# ======= Construct Rsync Command =======
RSYNC_OPTS=(
  -a          # archive mode (recursive, preserve symlinks, perms, times, groups, etc.)
  -v          # verbose
  -z          # compress during transfer
  -h          # human-readable output
  -u          # skip files that are newer on the receiver
  -P          # show progress during transfer and allow partial transfer resume
  -c          # compare files using checksum
  -x          # don't cross filesystem boundaries
  -A          # preserve ACLs
  -X          # preserve extended attributes
  --delete    # delete extraneous files from destination
  --numeric-ids  # don't map uid/gid numbers to usernames
  --backup    # backup overwritten files
  --backup-dir="${DEST}/.backup-${TIMESTAMP}"  # backup location
)

# --inplace was previously always on. It writes directly into the
# destination file rather than to a temporary and renaming, so an
# interrupted transfer leaves the destination partially overwritten and
# corrupt -- the opposite of what a backup should guarantee. rsync's
# default (temp file, atomic rename) costs extra space on the target and
# is worth it here, so --inplace is now opt-in for the cases that need
# it, such as very large files on space-constrained targets.
if [[ "$INPLACE" -eq 1 ]]; then
  RSYNC_OPTS+=(--inplace)
  echo "WARNING: --inplace means an interrupted run can leave corrupt files at the destination."
fi

# Add dry-run flag if needed
if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_OPTS+=(--dry-run)
  echo "Running in DRY RUN mode..."
fi

# Add exclude file if it exists
if [[ -f "$EXCLUDES" ]]; then
  RSYNC_OPTS+=(--exclude-from="$EXCLUDES")
fi

# The log lives under /var/log, which needs root. Every echo below pipes
# through `tee -a`, so with set -o pipefail an unprivileged run died on
# the first line with a bare "Permission denied" and no explanation.
# Fall back to stdout instead of failing the sync over its logging.
if ! { [ -w "$LOG_FILE" ] || { [ ! -e "$LOG_FILE" ] && [ -w "$(dirname "$LOG_FILE")" ]; }; }; then
  echo "NOTE: cannot write $LOG_FILE (need root); logging to stdout only." >&2
  LOG_FILE=/dev/null
fi

# --delete removes anything at the destination that is not in the source.
# Reversing the two arguments therefore erases the backup. --backup-dir
# above catches the deleted files, but confirm anyway -- the prompt is
# cheaper than discovering the mistake later.
if [[ "$DRY_RUN" -ne 1 && "$ASSUME_YES" -ne 1 ]]; then
  echo "About to sync with --delete:"
  echo "  FROM: $SOURCE/"
  echo "  TO:   $DEST/   (extraneous files here will be removed)"
  if [ ! -t 0 ]; then
    echo "Refusing to run unattended without --yes." >&2
    exit 1
  fi
  read -r -p "Proceed? (yes/NO): " reply
  [ "$reply" = "yes" ] || { echo "Cancelled."; exit 0; }
fi

# ======= Run Rsync =======
echo "Starting rsync at $TIMESTAMP" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"

rsync "${RSYNC_OPTS[@]}" "$SOURCE/" "$DEST/" 2>&1 | tee -a "$LOG_FILE"

echo "rsync completed at $(date +"%Y-%m-%d_%H-%M-%S")" | tee -a "$LOG_FILE"
