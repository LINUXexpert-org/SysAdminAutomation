#!/bin/bash
# log_inspect.sh - Search or tail system log files
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
# Usage: log_inspect.sh [search <pattern> | tail <logfile>]
# Description: Searches across /var/log for a pattern, or tails a specific log file.
 
if [ "$1" = "search" ]; then
  pattern="$2"
  if [ -z "$pattern" ]; then
    echo "Usage: $0 search <pattern>"; exit 1
  fi
  echo "Searching for '$pattern' in /var/log..."
  grep -R -i --color=auto "$pattern" /var/log 2>/dev/null
  exit 0
elif [ "$1" = "tail" ]; then
  logfile="$2"
  if [ -z "$logfile" ]; then
    echo "Usage: $0 tail <log_file_path>"; exit 1
  fi
  if [ ! -f "$logfile" ]; then
    echo "Log file '$logfile' not found."; exit 1
  fi
  echo "== Last 100 lines of $logfile =="
  tail -n 100 "$logfile"
  exit 0
else
  # Default: tail the main system log (syslog or messages)
  if [ -f /var/log/syslog ]; then
    echo "== Last 50 lines of /var/log/syslog =="
    tail -n 50 /var/log/syslog
  elif [ -f /var/log/messages ]; then
    echo "== Last 50 lines of /var/log/messages =="
    tail -n 50 /var/log/messages
  else
    echo "No syslog or messages log found."
  fi
fi
