#!/bin/bash
# restore.sh - Restore files from a backup archive
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
# 
# Usage: restore.sh <backup_archive.tar.gz> [target_directory]
# Description: Extracts the tar.gz archive into the target directory (current dir if not specified).
#   Lists the archive contents and asks before extracting, since it
#   overwrites whatever is already there. Set ASSUME_YES=1 to skip the
#   prompt for unattended use.
#
# Extraction options are deliberately conservative -- see the tar call.

set -euo pipefail

ARCHIVE="${1:-}"
TARGET="${2:-}"
if [ -z "$ARCHIVE" ]; then
  echo "Usage: $0 <archive.tar.gz> [target_directory]"
  exit 1
fi
if [ ! -f "$ARCHIVE" ]; then
  echo "Backup archive '$ARCHIVE' not found!"; exit 1
fi

if [ -z "$TARGET" ]; then
  TARGET="."
else
  if [ ! -d "$TARGET" ]; then
    mkdir -p "$TARGET" || { echo "Failed to create target directory '$TARGET'"; exit 1; }
  fi
fi

# An archive is untrusted input: whoever produced it chooses the paths,
# the ownership and the modes inside it.
#   --no-same-owner       do not let the archive pick uid/gid. Extracting
#                         as root previously handed files to whatever
#                         owner the tarball named.
#   --no-same-permissions apply the umask rather than restoring setuid
#                         bits straight out of the archive.
#   -P is NOT used, so tar strips leading "/" and refuses ".." members.
echo "Contents to be extracted into $TARGET:"
tar -tzf "$ARCHIVE" | head -n 20
total="$(tar -tzf "$ARCHIVE" | grep -c . || true)"
[ "$total" -gt 20 ] && echo "  ... and $((total - 20)) more entries"

if [ "${ASSUME_YES:-}" != "1" ]; then
  if [ ! -t 0 ]; then
    echo "Refusing to extract without confirmation; set ASSUME_YES=1 for unattended use." >&2
    exit 1
  fi
  read -r -p "Extract $total entries into $TARGET, overwriting existing files? (yes/NO): " reply
  [ "$reply" = "yes" ] || { echo "Cancelled."; exit 0; }
fi

if tar -xzf "$ARCHIVE" -C "$TARGET" --no-same-owner --no-same-permissions; then
  echo "Restore successful to directory: $TARGET"
else
  echo "Restore failed" >&2
  exit 1
fi
