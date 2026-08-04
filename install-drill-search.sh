#!/usr/bin/bash
#
# Script: install-drill-search.sh
# Description: Installs and integrates an AppImage with AppImageLauncher.
# It assumes the AppImage file is located in a folder named "apps" within
# the current working directory of the script.
#

set -uo pipefail

# Define the path to the AppImage file
appimage_file="apps/Drill-1.0.0-GTK.AppImage"

# Ensure the AppImage file exists
if [ ! -f "$appimage_file" ]; then
    echo "Error: AppImage file not found at $appimage_file"
    exit 1
fi

# Make the AppImage file executable
chmod +x "$appimage_file"

# Integrate the AppImage with AppImageLauncher
if ail-cli integrate "$appimage_file"; then
    echo "AppImage $appimage_file installed and integrated successfully"
else
    echo "Error: Failed to install and integrate AppImage $appimage_file"
    exit 1
fi

