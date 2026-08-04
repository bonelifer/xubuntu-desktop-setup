#!/usr/bin/bash
#
# Script: install-add-sudoers-no-password.sh
# Description: Add current user to sudoers for password-less sudo
# Purpose: This script adds the current user to the sudoers list to allow password-less sudo
# Usage: Run the script with sudo privileges
#
# References:
#   - https://askubuntu.com/questions/334318/sudoers-file-enable-nopasswd-for-user-all-commands
#   - https://linuxtect.com/how-to-run-sudo-command-without-password-with-nopasswd/

set -euo pipefail

# Check if the script is being run with sudo privileges
if [ "$(id -u)" != "0" ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Add current user to sudoers for password-less sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"

