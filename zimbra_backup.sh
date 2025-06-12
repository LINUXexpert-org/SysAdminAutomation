#!/bin/bash
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

# Ensure script is run as root or sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo."
    exit 1
fi

# Prompt for email and backup directory
read -p "Enter Zimbra username (email address): " EMAIL
read -p "Enter backup directory (absolute path) [/opt/zimbra/backups]: " BACKUP_DIR

# Use default if none provided
BACKUP_DIR=${BACKUP_DIR:-/opt/zimbra/backups}

# Ensure directory exists
mkdir -p "$BACKUP_DIR"
chown zimbra:zimbra "$BACKUP_DIR"

# Generate timestamped filename
TIMESTAMP=$(date +%F_%H-%M-%S)
BACKUP_FILE="${BACKUP_DIR}/${EMAIL}_${TIMESTAMP}.tgz"

# Confirm action
echo "Backing up mailbox for $EMAIL to $BACKUP_FILE"
read -p "Proceed? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Backup cancelled."
    exit 0
fi

# Run zmmailbox command as zimbra user
echo "📦 Starting backup..."
sudo -u zimbra bash -c "/opt/zimbra/bin/zmmailbox -z -m '$EMAIL' getRestURL '//?fmt=tgz'" > "$BACKUP_FILE"

# Verify success
if [ $? -eq 0 ]; then
    echo "✅ Backup completed: $BACKUP_FILE"
else
    echo "❌ Backup failed. Check if the user exists or zmmailbox is working."
    rm -f "$BACKUP_FILE"
    exit 1
fi
