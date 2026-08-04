#!/usr/bin/bash
#
# Script: install-and-activate-filebot-license.sh
# Description: Activates FileBot license using the provided license file.
#
# Example:
#   ./install-and-activate-filebot-license.sh
#
# Notes:
#   - This script activates a FileBot license using the provided license file.
#   - The license file should be located in a folder named "files" in the same directory as this script.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
LICENSE_FILE="$SCRIPT_DIR/files/FileBot_License_PX44657928.psm"

# Check if the license file exists
if [ ! -f "$LICENSE_FILE" ]; then
  echo "Error: License file not found: $LICENSE_FILE"
  exit 1
fi

# Install filebot
sudo apt install -y --install-suggests --install-recommends filebot

# Activate FileBot license
filebot --license "$LICENSE_FILE"

echo "FileBot license activated successfully."

