#!/bin/bash
# backup.sh - Backup directory to compressed tar archive
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
# Usage: backup.sh <source_directory> <destination_directory>
# Description: Creates a tar.gz archive of the source directory in the destination.
 
SRC="$1"
DEST="$2"
if [ -z "$SRC" ] || [ -z "$DEST" ]; then
  echo "Usage: $0 <source_directory> <destination_directory>"
  exit 1
fi
if [ ! -d "$SRC" ]; then
  echo "Source directory '$SRC' not found!"; exit 1
fi
if [ ! -d "$DEST" ]; then
  # create destination dir if it doesn't exist
  mkdir -p "$DEST" || { echo "Failed to create destination '$DEST'"; exit 1; }
fi

base_name="$(basename "$SRC")"
date_str="$(date +%Y%m%d)"
archive_name="${base_name}-backup-${date_str}.tar.gz"
tar -czf "$DEST/$archive_name" -C "$(dirname "$SRC")" "$base_name"
if [ $? -eq 0 ]; then
  echo "Backup successful: $DEST/$archive_name"
else
  echo "Backup failed for $SRC"
fi
