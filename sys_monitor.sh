#!/bin/bash
# sys_monitor.sh - System resource monitoring script
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
# Usage: sys_monitor.sh    (no arguments)
# Description: Prints system uptime, memory, disk usage, and top CPU/mem processes.
 
echo "==== System Uptime and Load ===="
uptime

echo -e "\n==== Memory Usage ===="
free -h

echo -e "\n==== Disk Usage ===="
# Exclude temporary filesystems (tmpfs) for clarity
df -h -x tmpfs -x devtmpfs

echo -e "\n==== Top 5 Processes by CPU Usage ===="
# Display header and top 5 CPU-consuming processes
ps -eo pid,user,comm,%cpu --sort=-%cpu | head -n 6

echo -e "\n==== Top 5 Processes by Memory Usage ===="
ps -eo pid,user,comm,%mem --sort=-%mem | head -n 6
