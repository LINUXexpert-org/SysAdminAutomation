#!/bin/bash
# process_monitor.sh - Show top processes and allow killing by name or PID
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
# Usage: process_monitor.sh [kill <process_name|PID>]
# Description: Without args, shows top CPU & memory processes. With "kill", terminates process by name or PID.
 
if [ "$1" = "kill" ]; then
  target="$2"
  if [ -z "$target" ]; then
    echo "Usage: $0 kill <process_name|PID>"; exit 1
  fi
  # If target is numeric (PID), kill that PID, else kill by name
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    kill "$target" && echo "Process $target killed." || echo "Failed to kill process $target."
  else
    # Use pkill to kill by name (match full process name)
    pkill -x "$target" && echo "Processes named '$target' killed." || echo "No process '$target' found or kill failed."
  fi
  exit 0
fi

echo "==== Top 5 CPU-consuming processes ===="
ps -eo pid,user,comm,%cpu --sort=-%cpu | head -n 6

echo -e "\n==== Top 5 Memory-consuming processes ===="
ps -eo pid,user,comm,%mem --sort=-%mem | head -n 6
