#!/bin/bash
# user_manage.sh - User and Group Management Script
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
# Usage: user_manage.sh <subcommand> [arguments...]
#   Subcommands: adduser <user>, deluser <user>, addgroup <group>, delgroup <group>,
#                addtogroup <user> <group>, lock <user>, unlock <user>,
#                listusers, listgroups
# Description: Automates user/group creation, deletion, and modifications.
# Requires root for everything except listusers/listgroups.
# deluser removes the home directory and asks first; set ASSUME_YES=1 to
# skip that prompt for unattended use.

set -euo pipefail

subcmd="${1:-}"

# The read-only subcommands work for anyone; everything else edits
# /etc/passwd, /etc/group or /etc/shadow. Without this the script ran
# useradd/userdel/usermod as an ordinary user and reported "Failed to
# create user." with no hint that privilege was the problem.
usage() {
  echo "Usage: $0 {adduser|deluser|addgroup|delgroup|addtogroup|lock|unlock|listusers|listgroups}"
}

case "$subcmd" in
  # Read-only: anyone may run these.
  listusers|listgroups) ;;
  # Mutating: gate on root. Checked after the subcommand is recognised,
  # so `user_manage.sh` with no arguments still prints usage instead of
  # complaining about privileges.
  adduser|deluser|addgroup|delgroup|addtogroup|lock|unlock)
    if [ "$EUID" -ne 0 ]; then
      echo "This action requires root. Re-run with sudo." >&2
      exit 1
    fi
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

# Usernames and group names reach useradd/userdel directly. Keep them to
# what a POSIX account name may contain, so nothing surprising is passed
# through as an option or a path.
valid_name() {
  [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

case "$subcmd" in
  adduser)
    user="${2:-}"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 adduser <username>"; exit 1; fi
    valid_name "$user" || { echo "Not a valid username: $user" >&2; exit 1; }
    # Create user with a home directory (-m) and default settings
    useradd -m "$user" && echo "User '$user' created." || echo "Failed to create user."
    ;;
  deluser)
    user="${2:-}"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 deluser <username>"; exit 1; fi
    valid_name "$user" || { echo "Not a valid username: $user" >&2; exit 1; }
    if ! id -u "$user" >/dev/null 2>&1; then echo "No such user: $user" >&2; exit 1; fi
    # -r removes the home directory and mail spool. That is unrecoverable,
    # so show what is about to go and confirm.
    echo "About to delete user '$user' and remove:"
    echo "  home: $(getent passwd "$user" | cut -d: -f6)"
    if [ "${ASSUME_YES:-}" != "1" ]; then
      if [ ! -t 0 ]; then
        echo "Refusing without confirmation; set ASSUME_YES=1 for unattended use." >&2
        exit 1
      fi
      read -r -p "Delete user '$user' and their home directory? (yes/NO): " reply
      [ "$reply" = "yes" ] || { echo "Cancelled."; exit 0; }
    fi
    userdel -r "$user" && echo "User '$user' deleted." || { echo "Failed to delete user." >&2; exit 1; }
    ;;
  addgroup)
    group="${2:-}"
    if [ -z "$group" ]; then echo "Group name required. Usage: $0 addgroup <group>"; exit 1; fi
    valid_name "$group" || { echo "Not a valid group name: $group" >&2; exit 1; }
    groupadd "$group" && echo "Group '$group' created." || echo "Failed to create group."
    ;;
  delgroup)
    group="${2:-}"
    if [ -z "$group" ]; then echo "Group name required. Usage: $0 delgroup <group>"; exit 1; fi
    groupdel "$group" && echo "Group '$group' deleted." || echo "Failed to delete group."
    ;;
  addtogroup)
    user="${2:-}"; group="$3"
    if [ -z "$user" ] || [ -z "$group" ]; then 
      echo "Usage: $0 addtogroup <user> <group>"; exit 1; 
    fi
    usermod -aG "$group" "$user" && echo "Added user '$user' to group '$group'." || echo "Failed to modify group membership."
    ;;
  lock)
    user="${2:-}"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 lock <username>"; exit 1; fi
    usermod -L "$user" && echo "User '$user' account locked." || echo "Failed to lock account."
    ;;
  unlock)
    user="${2:-}"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 unlock <username>"; exit 1; fi
    usermod -U "$user" && echo "User '$user' account unlocked." || echo "Failed to unlock account."
    ;;
  listusers)
    cut -d: -f1 /etc/passwd
    ;;
  listgroups)
    cut -d: -f1 /etc/group
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
