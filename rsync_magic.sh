#!/bin/bash

# rsync_magic.sh - A smart, feature-rich rsync wrapper for safe and powerful file synchronization.
# 
# Copyright (C) 2025 LINUXexpert.org
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
  echo "Usage: $0 [--dry-run] <source> <destination>"
  echo "Optional: --dry-run to simulate the sync"
  exit 1
}

# ======= Argument Parsing =======
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

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
  --inplace   # update destination files in place
  --backup    # backup overwritten files
  --backup-dir="${DEST}/.backup-${TIMESTAMP}"  # backup location
)

# Add dry-run flag if needed
if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_OPTS+=(--dry-run)
  echo "Running in DRY RUN mode..."
fi

# Add exclude file if it exists
if [[ -f "$EXCLUDES" ]]; then
  RSYNC_OPTS+=(--exclude-from="$EXCLUDES")
fi

# ======= Run Rsync =======
echo "Starting rsync at $TIMESTAMP" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"

rsync "${RSYNC_OPTS[@]}" "$SOURCE/" "$DEST/" 2>&1 | tee -a "$LOG_FILE"

echo "rsync completed at $(date +"%Y-%m-%d_%H-%M-%S")" | tee -a "$LOG_FILE"
