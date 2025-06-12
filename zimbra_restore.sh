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

# Ensure script is run as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo."
    exit 1
fi

# Prompt for email and backup directory
read -p "Enter Zimbra username to restore to (email address): " EMAIL
read -p "Enter backup directory (absolute path) [/opt/zimbra/backups]: " BACKUP_DIR

# Use default if none provided
BACKUP_DIR=${BACKUP_DIR:-/opt/zimbra/backups}

# Check if directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

# List available backups for that user
echo "📁 Available backups for $EMAIL:"
ls "$BACKUP_DIR" | grep "$EMAIL" | grep '\.tgz$'
echo

# Prompt for filename
read -p "Enter the exact filename of the backup to restore (e.g., user@example.com_2024-06-11_10-20-30.tgz): " FILENAME
FULL_PATH="${BACKUP_DIR}/${FILENAME}"

# Validate file exists
if [ ! -f "$FULL_PATH" ]; then
    echo "❌ Backup file not found: $FULL_PATH"
    exit 1
fi

# Confirm before restoring
echo "⚠️  You are about to restore $FULL_PATH into $EMAIL's mailbox."
read -p "Proceed? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Restore cancelled."
    exit 0
fi

# Run the restore command as zimbra user
echo "🔄 Restoring backup..."
sudo -u zimbra bash -c "/opt/zimbra/bin/zmmailbox -z -m '$EMAIL' postRestURL '/?fmt=tgz&resolve=skip' --file '$FULL_PATH'"

# Check result
if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully for $EMAIL"
else
    echo "❌ Restore failed. Please verify mailbox exists and backup file integrity."
    exit 1
fi
