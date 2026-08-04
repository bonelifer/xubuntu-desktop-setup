#!/bin/bash
#
# Script: configs-restore.sh
# Description: This script restores individual configuration files from backups.
#
# Example:
#   ./configs-restore.sh
#
# Notes:
#   - This script restores configuration files from backups stored in a designated directory.
#   - The backup directory is assumed to be within the base backup directory.
#

# Get the directory of the script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define base backup directory
base_backup_dir="$HOME/backup"

# Define backup directory for this script
backup_dir="$base_backup_dir/backup_configs"

# Restore individual config files
restore_config() {
    local config_backup="$1"
    local config_name="$(basename "$config_backup" .backup)"
    local original_path="$HOME/.config/$config_name"

    if [ -f "$config_backup" ]; then
        cp "$config_backup" "$original_path"
        echo "Restored: $config_name"
    else
        echo "Backup file not found: $config_backup"
    fi
}

# Restore each configuration file
for config_backup in "$backup_dir"/*.backup; do
    restore_config "$config_backup"
done

echo "Restore process completed."

