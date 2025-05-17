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
 
ARCHIVE="$1"
TARGET="$2"
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

tar -xzf "$ARCHIVE" -C "$TARGET"
status=$?
if [ $status -eq 0 ]; then
  echo "Restore successful to directory: $TARGET"
else
  echo "Restore failed with error code $status"
fi
