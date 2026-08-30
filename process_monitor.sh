#!/bin/bash
# process_monitor.sh - Show top processes and allow killing by name or PID
# 
# Copyright (C) 2025 Coffey Labs
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
#   The kill path prints what it matched and asks first -- pkill by name
#   can match more than one process. Set FORCE=1 to skip the prompt.

set -euo pipefail

if [ "${1:-}" = "kill" ]; then
  target="$2"
  if [ -z "$target" ]; then
    echo "Usage: $0 kill <process_name|PID>"; exit 1
  fi
  # Show what will be signalled and confirm first. pkill -x by name can
  # match several processes at once, and as root that is an easy way to
  # take down more than intended with no warning.
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    if ! ps -p "$target" -o pid,user,comm >/dev/null 2>&1; then
      echo "No process with PID $target."; exit 1
    fi
    ps -p "$target" -o pid,user,comm
  else
    if ! pgrep -x "$target" >/dev/null 2>&1; then
      echo "No process named '$target'."; exit 1
    fi
    pgrep -x -a "$target"
  fi

  if [ "${FORCE:-}" != "1" ]; then
    if [ ! -t 0 ]; then
      echo "Refusing to kill without confirmation; set FORCE=1 for unattended use." >&2
      exit 1
    fi
    read -r -p "Send SIGTERM to the above? (yes/NO): " reply
    [ "$reply" = "yes" ] || { echo "Cancelled."; exit 0; }
  fi

  if [[ "$target" =~ ^[0-9]+$ ]]; then
    kill "$target" && echo "Process $target signalled." || echo "Failed to signal process $target."
  else
    pkill -x "$target" && echo "Processes named '$target' signalled." || echo "Failed to signal '$target'."
  fi
  exit 0
fi

echo "==== Top 5 CPU-consuming processes ===="
ps -eo pid,user,comm,%cpu --sort=-%cpu | head -n 6 || true

echo -e "\n==== Top 5 Memory-consuming processes ===="
ps -eo pid,user,comm,%mem --sort=-%mem | head -n 6 || true
