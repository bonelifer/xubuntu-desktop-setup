#!/usr/bin/bash

#
# Script: backup-wifi.sh
# Description: Backup saved WiFi network names and pre-shared keys (PSKs)
# from NetworkManager. Backup only -- not auto-restored; a running system
# already has its own live connection profiles, and unattended restore of
# plaintext keys is not something to automate. The backup file contains
# plaintext passwords, so it's written with 600 permissions.
# Usage:       ./backup-wifi.sh [-b|--backup]
#

set -uo pipefail

# Define paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
backup_dir="$script_dir/backup/wifi"
connections_dir="/etc/NetworkManager/system-connections"

# Function to backup WiFi network names and PSKs
backup_wifi() {
    mkdir -p "$backup_dir" # Create backup directory if not exists
    if [ -d "$connections_dir" ]; then
        local out_file="$backup_dir/wifi_psk_backup.txt"
        sudo grep -r '^psk=' "$connections_dir/" \
            | sed 's|.nmconnection| |g' \
            | sed "s|$connections_dir/||g" \
            | sed 's|psk=| |g' \
            > "$out_file"
        chmod 600 "$out_file"
        echo "WiFi PSKs backed up successfully to $out_file (permissions set to 600 -- contains plaintext passwords)"
    else
        echo "No $connections_dir found, skipping."
    fi
}

# Main function
main() {
    # Parsing command-line arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -b|--backup)
                backup_wifi
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
