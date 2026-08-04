#!/usr/bin/bash
#
# Script: install-angryipscanner.sh
# Description: Downloads and installs the latest Angry IP Scanner .deb release.
# Reference: https://github.com/angryip/ipscan/releases
#

set -euo pipefail

# Set the URL of the latest Angry IP Scanner DEB package
DOWNLOAD_URL="https://github.com/angryip/ipscan/releases/latest/download/ipscan_amd64.deb"

# Create a temporary directory to store the downloaded DEB package
TEMP_DIR=$(mktemp -d)

# Download the DEB package
curl -s -L "$DOWNLOAD_URL" -o "$TEMP_DIR/ipscan.deb"

# Install the DEB package
sudo dpkg -i "$TEMP_DIR/ipscan.deb"

# Clean up
rm -rf "$TEMP_DIR"

echo "Angry IP Scanner has been installed successfully."

