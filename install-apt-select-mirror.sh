#!/usr/bin/bash
#
# Script: install-apt-select-mirror.sh
# Description: Automates selecting and updating Debian package mirrors for
# the United States using apt-select.
#

set -euo pipefail

# Check if pip is installed, if not, install it
if ! command -v pip3 &>/dev/null; then
    echo "Installing pip..."
    sudo apt update
    sudo apt install -y python3-pip
fi

# Check if apt-select is installed, if not, install it
if ! command -v apt-select &>/dev/null; then
    echo "Installing apt-select..."
    pip3 install apt-select
fi

# Set the country code for the United States
COUNTRY="US"

# Get the current date and time for creating a backup file
CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")

# Backup the original sources.list file
echo "Backing up the original sources.list file..."
sudo cp /etc/apt/sources.list "/etc/apt/sources.list.backup_$CURRENT_DATE" # Backup the original sources.list file with timestamp

# Run apt-select for the specified country
echo "Selecting mirrors for the United States..."
apt-select -C "$COUNTRY"

# Move the newly created sources.list file to /etc/apt directory
sudo mv sources.list /etc/apt/sources.list

# Update APT to reflect the changes made to sources.list
echo "Updating APT..."
sudo apt update

echo "Mirror selection and update completed."

