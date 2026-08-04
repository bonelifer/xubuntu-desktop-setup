#!/usr/bin/bash
#
# Script: install-mouse-pointer-settings.sh
# Description: Manages dconf settings for a ThinkPad laptop -- dumps and
# loads dconf settings for the touchpad and pointing stick.
#

set -euo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"  # Get the directory of the script
backup_dir="$script_dir/backup/dconf"        # Define the backup directory

# Function to dump dconf settings
# Arguments:
#   $1: dconf key
dump_settings() {
    local key="$1"
    local filename="$backup_dir/${key}_settings.conf"
    
    # Ensure the directory exists
    mkdir -p "$(dirname "$filename")"
    
    # Dump dconf settings to a file
    dconf dump "$key" > "$filename"
    
    # Print a message indicating where the settings were dumped
    echo "Settings dumped to: $filename"
}

# Function to load dconf settings
# Arguments:
#   $1: dconf key
load_settings() {
    local key="$1"
    local filename="$backup_dir/${key}_settings.conf"
    
    # Check if the backup file exists
    if [ -f "$filename" ]; then
        # Load dconf settings from the file
        dconf load "$key" < "$filename"
        
        # Print a message indicating where the settings were loaded from
        echo "Settings loaded from: $filename"
    else
        # Print an error message if the backup file doesn't exist
        echo "Error: No backup file found for $key"
    fi
}

# Default to --load with no arguments (e.g. when run unattended as a core
# install module) -- load_settings() is a no-op-but-successful if there's no
# backup yet, so this is safe to run on a fresh machine.
if [[ $# -eq 0 ]]; then
    set -- --load
fi

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--dump)
            # Dump touchpad settings
            dump_settings "/org/gnome/desktop/peripherals/touchpad/"
            # Dump pointing stick settings
            dump_settings "/org/gnome/desktop/peripherals/pointingstick/"
            shift
            ;;
        -l|--load)
            # Load touchpad settings
            load_settings "/org/gnome/desktop/peripherals/touchpad/"
            # Load pointing stick settings
            load_settings "/org/gnome/desktop/peripherals/pointingstick/"
            shift
            ;;
        *)
            # Print an error message for unknown options
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

