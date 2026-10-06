#!/bin/bash
# update_system.sh - Apply system package updates
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
# Usage: update_system.sh    (no arguments, run as root)
# Description: Detects the Linux distro's package manager and installs all updates.
#
# Unattended: every branch below passes -y or --noconfirm, so this will
# apply whatever the configured repositories offer without asking.

set -euo pipefail

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root to apply system updates."
  exit 1
fi

if command -v apt-get &> /dev/null; then
  echo "Updating with apt-get..."
  apt-get update && apt-get upgrade -y
elif command -v apt &> /dev/null; then
  echo "Updating with apt..."
  apt update && apt upgrade -y
elif command -v dnf &> /dev/null; then
  echo "Updating with dnf..."
  dnf upgrade -y
elif command -v yum &> /dev/null; then
  echo "Updating with yum..."
  yum update -y
elif command -v zypper &> /dev/null; then
  echo "Updating with zypper..."
  zypper refresh && zypper update -y
elif command -v pacman &> /dev/null; then
  echo "Updating with pacman..."
  # Arch has no supported partial-upgrade path: -Syuu on a stale mirror
  # list or a half-updated system can leave unbootable library mismatches,
  # and --noconfirm answers away the prompts that would have warned. Kept
  # for parity with the other package managers, but this is the branch to
  # be most careful with.
  pacman -Syuu --noconfirm
else
  echo "Error: No supported package manager found on this system."
  exit 1
fi
