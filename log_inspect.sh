#!/bin/bash
# log_inspect.sh - Search or tail system log files
# 
# Copyright (C) 2025 Coffey Labs LLC
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
#
# Most of /var/log is root-only. Run this with sudo, or results will be
# quietly partial -- see the note on the search branch.

set -euo pipefail

if [ "${1:-}" = "search" ]; then
  pattern="${2:-}"
  if [ -z "$pattern" ]; then
    echo "Usage: $0 search <pattern>"; exit 1
  fi
  echo "Searching for '$pattern' in /var/log..."
  # 2>/dev/null hid permission errors, so an unprivileged run looked like
  # "no matches" rather than "could not read most of /var/log". Say so
  # explicitly instead. grep exits 1 on no match, which is not an error.
  # grep distinguishes three outcomes and they mean different things
  # here: 0 matched, 1 matched nothing, 2 could not read everything. The
  # original discarded stderr and ignored the status, so an unprivileged
  # run over root-owned logs was indistinguishable from a clean search.
  status=0
  grep -R -i --color=auto -- "$pattern" /var/log 2>/dev/null || status=$?
  case "$status" in
    0) ;;
    1) echo "No matches found." ;;
    *)
      echo "Search was incomplete -- some files under /var/log could not be read." >&2
      [ "$EUID" -ne 0 ] && echo "Re-run with sudo for a complete search." >&2
      exit "$status"
      ;;
  esac
  exit 0
elif [ "${1:-}" = "tail" ]; then
  logfile="${2:-}"
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
