#!/bin/bash
# security_audit.sh - Check for common security issues (permissions, open ports)
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
# Usage: security_audit.sh   (no arguments)
# Description: Lists world-writable files/dirs, SUID/SGID files, and listening ports.
#
# Run as root for a complete picture: as an unprivileged user, find
# cannot descend into directories it may not read, so a clean report
# below is not the same as a clean system.

set -euo pipefail

# Each find below ends in `|| true`. find exits non-zero when it could
# not read some directory -- routine here, since we deliberately walk the
# whole filesystem -- and without this, set -e would abort the audit part
# way through and still look like it had finished.

# World-writable files (perm bits: others have write)
echo "==== World-Writable Files (potentially unsafe) ===="
find / -xdev -type f -perm -0002 -printf '%M %u %g %p\n' 2>/dev/null || true

# World-writable directories without sticky bit
echo -e "\n==== World-Writable Directories (no sticky bit) ===="
find / -xdev -type d -perm -0002 ! -perm -1000 -printf '%M %u %g %p\n' 2>/dev/null || true

# SUID/SGID files (files with setuid or setgid bits)
echo -e "\n==== SUID/SGID Files ===="
find / -xdev \( -perm -4000 -o -perm -2000 \) -printf '%M %u %g %p\n' 2>/dev/null || true

# Open listening ports
echo -e "\n==== Listening Network Ports ===="
if command -v ss &> /dev/null; then
  ss -tulwn
elif command -v netstat &> /dev/null; then
  netstat -tuln
else
  echo "No command available to list network ports."
fi
