#!/usr/bin/bash

# Script: backup-restore-keepassxc.sh
# Description: Backup and Restore the last active KeePassXC database, with a desktop fallback.
#
# Usage: ./backup-restore-keepassxc.sh [-b|--backup|-r|--restore]
#
# Dependencies: basename, cp, grep, pgrep
#
# Notes:
#   - This script checks if KeePassXC is running and performs backup or restore accordingly.
#   - It checks Flatpak, Snap, cache, and config locations for the last active database.
#   - If no valid last active database is found, it uses all desktop .kdbx files.
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
    config_files=(
        "$HOME/.var/app/org.keepassxc.KeePassXC/cache/keepassxc/keepassxc.ini"
        "$HOME/snap/keepassxc/current/.cache/keepassxc/keepassxc.ini"
        "$HOME/.cache/keepassxc/keepassxc.ini"
        "$HOME/.config/keepassxc/keepassxc.ini"
    )
    last_db_path=""

    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            last_db_path=$(grep -m 1 '^LastActiveDatabase=' "$config_file" || true)
            last_db_path=${last_db_path#LastActiveDatabase=}
            if [ -n "$last_db_path" ]; then
                log_message "KeePassXC configuration file found: $config_file"
                break
            fi
        fi
    done

    case "${1:-}" in
        -b | --backup)
            if [ -n "$last_db_path" ] && [ -f "$last_db_path" ]; then
                database_files=("$last_db_path")
            else
                database_files=("$HOME/Desktop/"*.kdbx)
            fi
            if [ "${#database_files[@]}" -eq 0 ]; then
                log_message "No KeePassXC databases found in: $HOME/Desktop/"
                exit 1
            fi
            cp -- "${database_files[@]}" "$backup_dir/"
            log_message "KeePassXC databases copied to: $backup_dir/"
            ;;
        -r | --restore)
            if [ -n "$last_db_path" ] && [ -f "$backup_dir/$(basename "$last_db_path")" ]; then
                database_files=("$backup_dir/$(basename "$last_db_path")")
            else
                database_files=("$backup_dir/"*.kdbx)
            fi
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

