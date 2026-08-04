#!/usr/bin/bash

# Script: backup-restore-keepassxc.sh
# Description: Backup and Restore the last opened KeePassXC database.
#
# Usage: ./backup-restore-keepassxc.sh [-b|--backup|-r|--restore]
#
# Dependencies: cp, grep, pgrep
#
# Notes:
#   - This script checks if KeePassXC is running and performs backup or restore accordingly.
#   - For backup, it copies the last opened database to a backup directory.
#   - For restore, it copies the last opened database from the backup directory to the current user's desktop.
#   - The backup directory is created within the directory where the script is located.
#   - Ensure that the required dependencies are installed and accessible in your environment.
#

set -uo pipefail

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %T") - $message"
}

# Define backup directory
script_dir="$(cd "$(dirname "$0")" && pwd)"
backup_dir="$script_dir/backup/keepassxc"

# Create backup directory if it doesn't exist
mkdir -p "$backup_dir"

# Check if KeePassXC is running
if pgrep -x "keepassxc" > /dev/null; then
    log_message "KeePassXC is running."

    # Check the cache directory for the KeePassXC configuration
    CONFIG_FILE="$HOME/.cache/keepassxc/keepassxc.ini"
    
    # Check if the configuration file exists
    if [ -f "$CONFIG_FILE" ]; then
        log_message "KeePassXC configuration file found: $CONFIG_FILE"

        # Extract the path of the last active database
        LAST_DB_PATH=$(grep -oP '^LastActiveDatabase=\K.*' "$CONFIG_FILE")
        
        # Debugging: Print the extracted last active database path
        log_message "Extracted LastActiveDatabase path: $LAST_DB_PATH"

        # Check if the path is not empty
        if [ -n "$LAST_DB_PATH" ]; then
            case "${1:-}" in
                -b | --backup)
                    # Backup: Copy the last opened database to the backup directory
                    cp "$LAST_DB_PATH" "$backup_dir/"
                    log_message "Last opened KeePassXC database copied to: $backup_dir/"
                    ;;
                -r | --restore)
                    # Restore: Copy the last opened database from the backup directory to the user's desktop
                    cp "$backup_dir/$(basename "$LAST_DB_PATH")" "$HOME/Desktop/"
                    log_message "Last opened KeePassXC database restored to: $HOME/Desktop/"
                    ;;
                *)
                    log_message "Invalid argument. Usage: $0 [-b|--backup|-r|--restore]"
                    exit 1
                    ;;
            esac
        else
            log_message "No last opened KeePassXC database path found."
        fi
    else
        log_message "KeePassXC configuration file not found: $CONFIG_FILE"
        exit 1
    fi
else
    log_message "KeePassXC is not running."
    exit 1
fi

