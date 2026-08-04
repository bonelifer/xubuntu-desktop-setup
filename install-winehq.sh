#!/usr/bin/bash

# Script: install-winehq.sh
# Description: Automates the installation of WineHQ and Winetricks on Ubuntu.
# This is the sole owner of the WineHQ repo/key setup; install-main.sh does
# not duplicate it and relies on this module being run first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

keyring="/etc/apt/keyrings/winehq.gpg"

# Add architecture for 32-bit packages
sudo dpkg --add-architecture i386

# Update package lists
sudo apt update

# Install necessary packages
sudo apt install -y software-properties-common curl

# Add the WineHQ signing key to a dedicated keyring (apt-key is deprecated)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o "$keyring"

release="$(detect_codename)"

# Add WineHQ repository
echo "deb [signed-by=$keyring] https://dl.winehq.org/wine-builds/ubuntu/ $release main" \
    | sudo tee /etc/apt/sources.list.d/winehq.list >/dev/null

# Update package lists again
sudo apt update

# Install WineHQ stable version
sudo apt install -y --install-recommends winehq-stable

# Install winetricks
sudo apt-get install -y winetricks

