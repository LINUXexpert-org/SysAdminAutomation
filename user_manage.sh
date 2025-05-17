#!/bin/bash
# user_manage.sh - User and Group Management Script
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
# Usage: user_manage.sh <subcommand> [arguments...]
#   Subcommands: adduser <user>, deluser <user>, addgroup <group>, delgroup <group>,
#                addtogroup <user> <group>, lock <user>, unlock <user>,
#                listusers, listgroups
# Description: Automates user/group creation, deletion, and modifications.
# Requires root privileges for most operations.
 
subcmd="$1"
case "$subcmd" in
  adduser)
    user="$2"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 adduser <username>"; exit 1; fi
    # Create user with a home directory (-m) and default settings
    useradd -m "$user" && echo "User '$user' created." || echo "Failed to create user."
    ;;
  deluser)
    user="$2"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 deluser <username>"; exit 1; fi
    # Delete user and remove home directory (-r)
    userdel -r "$user" && echo "User '$user' deleted." || echo "Failed to delete user."
    ;;
  addgroup)
    group="$2"
    if [ -z "$group" ]; then echo "Group name required. Usage: $0 addgroup <group>"; exit 1; fi
    groupadd "$group" && echo "Group '$group' created." || echo "Failed to create group."
    ;;
  delgroup)
    group="$2"
    if [ -z "$group" ]; then echo "Group name required. Usage: $0 delgroup <group>"; exit 1; fi
    groupdel "$group" && echo "Group '$group' deleted." || echo "Failed to delete group."
    ;;
  addtogroup)
    user="$2"; group="$3"
    if [ -z "$user" ] || [ -z "$group" ]; then 
      echo "Usage: $0 addtogroup <user> <group>"; exit 1; 
    fi
    usermod -aG "$group" "$user" && echo "Added user '$user' to group '$group'." || echo "Failed to modify group membership."
    ;;
  lock)
    user="$2"
    if [ -z "$user" ]; then echo "Username required. Usage: $0 lock <username>"; exit 1; fi
    usermod -L "$user" && echo "User '$user' account locked." || echo "Failed to lock account."
    ;;
  unlock)
    user="$2"
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
    echo "Usage: $0 {adduser|deluser|addgroup|delgroup|addtogroup|lock|unlock|listusers|listgroups}"
    exit 1
    ;;
esac
