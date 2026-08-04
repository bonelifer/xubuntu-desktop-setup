#!/usr/bin/bash
#
# Script: backup-restore-plank.sh
# Description: Dumps and backs up Plank dock settings to a subdirectory of
# a backup folder (and restores them).
#

set -uo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
backup_dir="$script_dir/backup/plank"
backup_file="$backup_dir/plank_settings.ini"

# Function to dump plank settings to a file
dump_plank_settings() {
    # Dump plank settings to the output file, overwriting if it already exists
    dconf dump /net/launchpad/plank/ > "$backup_file"

    echo "Plank settings dumped to $backup_file"
}

# Function to restore plank settings from a file
restore_plank_settings() {
    # Check if the input file exists
    if [ ! -f "$backup_file" ]; then
        echo "Error: Backup file not found!"
        exit 1
    fi

    # Restore plank settings from the backup file
    dconf load /net/launchpad/plank/ < "$backup_file"

    echo "Plank settings restored from $backup_file"
}

# Main script logic
case "${1:-}" in
    "dump")
        # Create the backup directory if it doesn't exist
        mkdir -p "$backup_dir"
        dump_plank_settings
        ;;
    "restore")
        restore_plank_settings
        ;;
    *)
        echo "Usage: $0 {dump|restore}"
        exit 1
        ;;
esac

