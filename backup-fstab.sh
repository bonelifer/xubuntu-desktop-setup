#!/usr/bin/bash

#
# Script: backup-fstab.sh
# Description: Backup /etc/fstab. Backup only -- not auto-restored;
# restoring an old fstab over a live one risks silently reverting mount
# changes made since the backup, so that's left to manual review.
# Usage:       ./backup-fstab.sh [-b|--backup]
#

set -uo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
backup_dir="$script_dir/backup/fstab"

# Function to backup fstab
backup_fstab() {
    mkdir -p "$backup_dir" # Create backup directory if not exists
    if [ -f "/etc/fstab" ]; then
        cp /etc/fstab "$backup_dir/fstab_backup.txt"
        echo "fstab backed up successfully to $backup_dir/fstab_backup.txt"
    else
        echo "No /etc/fstab found, skipping."
    fi
}

# Main function
main() {
    # Parsing command-line arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -b|--backup)
                backup_fstab
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
