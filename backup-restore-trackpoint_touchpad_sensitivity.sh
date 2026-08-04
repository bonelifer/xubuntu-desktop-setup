#!/usr/bin/bash

#
# Script: backup-restore-trackpoint_touchpad_sensitivity.sh
# Description: Script to manage settings for touchpad, pointing stick, and mouse peripherals on a ThinkPad laptop
#
# Note: this dumps/loads via `dconf`, not `gsettings list-recursively`.
# `gsettings list-recursively` only ever reads current values -- it has no
# way to load values back in from a file, so a `load_settings` built on it
# would silently do nothing on restore.

set -uo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"  # Get the directory of the script
backup_dir="$script_dir/backup/gsettings"    # Define the backup directory

# Function to dump dconf settings for a peripheral
# Arguments:
#   $1: dconf path (e.g. /org/gnome/desktop/peripherals/touchpad/)
#   $2: label used for the backup filename
dump_settings() {
    local dconf_path="$1"
    local label="$2"
    local filename="$backup_dir/${label}_settings.conf"

    mkdir -p "$(dirname "$filename")"
    dconf dump "$dconf_path" > "$filename"
    echo "Settings dumped to: $filename"
}

# Function to load dconf settings for a peripheral
# Arguments:
#   $1: dconf path (e.g. /org/gnome/desktop/peripherals/touchpad/)
#   $2: label used for the backup filename
load_settings() {
    local dconf_path="$1"
    local label="$2"
    local filename="$backup_dir/${label}_settings.conf"

    if [ -f "$filename" ]; then
        dconf load "$dconf_path" < "$filename"
        echo "Settings loaded from: $filename"
    else
        echo "No backup file found for $label"
    fi
}

# Print usage message if no arguments provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [-d|--dump] [-l|--load]"
    exit 1
fi

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--dump)
            dump_settings "/org/gnome/desktop/peripherals/touchpad/" "touchpad"
            dump_settings "/org/gnome/desktop/peripherals/pointingstick/" "pointingstick"
            dump_settings "/org/gnome/desktop/peripherals/mouse/" "mouse"
            shift
            ;;
        -l|--load)
            load_settings "/org/gnome/desktop/peripherals/touchpad/" "touchpad"
            load_settings "/org/gnome/desktop/peripherals/pointingstick/" "pointingstick"
            load_settings "/org/gnome/desktop/peripherals/mouse/" "mouse"
            shift
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done
