#!/bin/bash
# disk_cleanup.sh - Show disk usage and optionally clean temporary files
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
# Usage: disk_cleanup.sh [--clean]
# Description: Without --clean, displays disk usage and largest files. With --clean, performs cleanup of caches and /tmp.
 
if [ "$1" != "--clean" ]; then
  echo "==== Disk Usage Overview ===="
  df -h -x tmpfs -x devtmpfs
  
  echo -e "\n==== Top 10 Largest Files ===="
  # List top 10 largest files (size in MB)
  find / -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head -n 10 | awk '{size=$1/1024/1024; printf("%.1f MB - ", size); $1=""; print $0;}'
  
  echo -e "\n(To actually free space, run: $0 --clean)"
  exit 0
fi

# If --clean is specified:
echo "Cleaning package caches and temporary files..."
# Package manager cache cleanup
if [ $EUID -ne 0 ]; then
  echo "Run as root to perform cleanup."; exit 1
fi
if command -v apt-get &> /dev/null; then
  apt-get clean
elif command -v dnf &> /dev/null; then
  dnf clean all
elif command -v yum &> /dev/null; then
  yum clean all
elif command -v pacman &> /dev/null; then
  pacman -Scc --noconfirm
fi

# Clean /tmp and /var/tmp files older than 7 days
find /tmp -type f -mtime +7 -exec rm -f {} \;
find /tmp -type d -empty -mtime +7 -exec rmdir {} \;
find /var/tmp -type f -mtime +7 -exec rm -f {} \;
echo "Temporary files older than 7 days removed from /tmp and /var/tmp."

echo "Disk cleanup completed."
