#!/bin/bash
# service_manager.sh - Start/stop/restart and manage system services
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
# Usage: service_manager.sh <action> <service_name>
#   Actions: start, stop, restart, status, enable, disable, list
# Description: Uses systemctl or service to control services.
#
# status and list are read-only; everything else changes system state
# and needs root.

set -euo pipefail

action="${1:-}"
service="${2:-}"

# Validate up front so an unknown action cannot reach systemctl as a
# bare word, and so the privilege check below has something to gate on.
case "$action" in
  start|stop|restart|status|enable|disable|list) ;;
  "") echo "Usage: $0 {start|stop|restart|status|enable|disable|list} <service_name>" >&2; exit 1 ;;
  *)  echo "Invalid action '$action'. Use start, stop, restart, status, enable, disable, or list." >&2; exit 1 ;;
esac

case "$action" in
  start|stop|restart|enable|disable)
    if [ "$EUID" -ne 0 ]; then
      echo "'$action' changes system state and requires root. Re-run with sudo." >&2
      exit 1
    fi
    ;;
esac

if [ "$action" = "list" ]; then
  # List running services
  if command -v systemctl &> /dev/null; then
    systemctl list-units --type=service --state=running
  elif command -v service &> /dev/null; then
    service --status-all 2>&1 | grep '+'   # shows running services with [+]
  else
    echo "No service management tool available."
  fi
  exit 0
fi

if [ -z "$action" ] || [ -z "$service" ]; then
  echo "Usage: $0 {start|stop|restart|status|enable|disable|list} <service_name>"
  exit 1
fi

if command -v systemctl &> /dev/null; then
  case "$action" in
    start|stop|restart|status|enable|disable)
      # Quoted: $action is validated above, but leaving it bare invites
      # word-splitting the moment anyone passes it through a variable.
      systemctl "$action" "$service"
      ;;
  esac
elif command -v service &> /dev/null; then
  case "$action" in
    start|stop|restart)
      service "$service" "$action"
      ;;
    status)
      service "$service" status
      ;;
    *)
      echo "Action '$action' not supported with legacy service command."
      exit 1
      ;;
  esac
else
  echo "No known service manager found (systemctl/service)."
  exit 1
fi
