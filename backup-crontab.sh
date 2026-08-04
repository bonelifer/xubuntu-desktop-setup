#!/usr/bin/bash

#
# Script: backup-crontab.sh
# Description: Backup user and system crontab entries. Backup only -- not
# auto-restored; restoring an old crontab over a live one risks silently
# dropping jobs added since the backup, so that's left to manual review.
# Usage:       ./backup-crontab.sh [-b|--backup]
#

set -uo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
backup_dir="$script_dir/backup/crontab"

# Function to backup crontab entries
backup_crontab() {
    mkdir -p "$backup_dir" # Create backup directory if not exists
    if [ -f "/etc/crontab" ]; then
        cp /etc/crontab "$backup_dir/crontab_system_backup.txt" # Backup system-wide crontab
    fi
    crontab -l > "$backup_dir/crontab_local_backup.txt" 2>/dev/null || true # Backup local crontab (no error if none set)
    echo "Crontab backed up successfully to $backup_dir"
}

# Main function
main() {
    # Parsing command-line arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -b|--backup)
                backup_crontab
                ;;
            *)
                echo "Unknown option: $key"
                exit 1
                ;;
        esac
        shift # past argument or value
    done
}

# Call main function with provided arguments
main "$@"
