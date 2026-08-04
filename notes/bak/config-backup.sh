#!/bin/bash
#
# Script: backup-configs.sh
# Description: This script backs up individual configuration files for various software.
#
# Example:
#   ./backup-configs.sh
#
# Notes:
#   - This script backs up configuration files for various software to a designated backup directory.
#   - The backup directory is created within the base backup directory.
#

# Get the directory of the script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the config file
source "$script_dir/config_paths.sh"

# Define base backup directory
base_backup_dir="$HOME/backup"

# Define backup directory for this script
backup_dir="$base_backup_dir/backup_configs"
mkdir -p "$backup_dir"

# Backup individual config files
backup_config() {
    local config_path="$1"
    local config_name="$(basename "$config_path")"
    local backup_path="$backup_dir/$config_name.backup"

    if [ -f "$config_path" ]; then
        cp "$config_path" "$backup_path"
        echo "Backup created for: $config_path"
    else
        echo "Config file not found: $config_path"
    fi
}

# Backup each configuration file
for config in "${software_configs[@]}"; do
    backup_config "$config"
done

echo "Backup process completed. Backup files are stored in: $backup_dir"

