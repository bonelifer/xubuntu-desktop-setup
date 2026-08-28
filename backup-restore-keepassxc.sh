#!/usr/bin/bash

# Script: backup-restore-keepassxc.sh
# Description: Backup and Restore KeePassXC databases stored on the desktop.
#
# Usage: ./backup-restore-keepassxc.sh [-b|--backup|-r|--restore]
#
# Dependencies: cp, pgrep
#
# Notes:
#   - This script checks if KeePassXC is running and performs backup or restore accordingly.
#   - For backup, it copies all desktop .kdbx files to a backup directory.
#   - For restore, it copies all backed-up .kdbx files to the current user's desktop.
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

    shopt -s nullglob

    case "${1:-}" in
        -b | --backup)
            database_files=("$HOME/Desktop/"*.kdbx)
            if [ "${#database_files[@]}" -eq 0 ]; then
                log_message "No KeePassXC databases found in: $HOME/Desktop/"
                exit 1
            fi
            cp -- "${database_files[@]}" "$backup_dir/"
            log_message "KeePassXC databases copied to: $backup_dir/"
            ;;
        -r | --restore)
            database_files=("$backup_dir/"*.kdbx)
            if [ "${#database_files[@]}" -eq 0 ]; then
                log_message "No KeePassXC databases found in: $backup_dir/"
                exit 1
            fi
            cp -- "${database_files[@]}" "$HOME/Desktop/"
            log_message "KeePassXC databases restored to: $HOME/Desktop/"
            ;;
        *)
            log_message "Invalid argument. Usage: $0 [-b|--backup|-r|--restore]"
            exit 1
            ;;
    esac
else
    log_message "KeePassXC is not running."
    exit 1
fi

