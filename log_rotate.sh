#!/bin/bash
# log_rotate.sh - Compress and remove old log files
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
# Usage: log_rotate.sh [days]
#   days: rotate logs older than this many days (default 7).
# Description: Compresses .log files older than X days in /var/log and deletes archives older than 90 days.
 
DAYS="$1"
if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  DAYS=7
fi
if [ $EUID -ne 0 ]; then
  echo "Please run as root to rotate system logs."
  exit 1
fi

echo "Rotating logs older than $DAYS days..."
# Compress uncompressed .log files older than $DAYS days
find /var/log -type f -name "*.log" -mtime +$DAYS ! -name "*.gz" -exec gzip {} \;
echo "Compressed logs older than $DAYS days."

# Remove very old compressed logs (older than 90 days)
find /var/log -type f -name "*.gz" -mtime +90 -exec rm -f {} \;
echo "Removed log archives older than 90 days."
