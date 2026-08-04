#!/usr/bin/bash

# Script: install-apart-gtk.sh
# Description: Download and install the apart-gtk package from a GitHub release.
#
# Usage: ./install-apart-gtk.sh
#
# Dependencies: curl, jq (for parsing JSON)
#
# Notes:
#   - This script retrieves the latest release of the apart-gtk package from a GitHub repository,
#     downloads the corresponding .deb file, and installs it using dpkg.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl jq

# Function to get the latest release information and download the specified package
get_release() {
    local gh_user="$1"
    local gh_repo="$2"
    local package_name="$3"

    local latest_release
    latest_release="$(curl -s "https://api.github.com/repos/$gh_user/$gh_repo/releases/latest")"

    local download_url
    download_url="$(echo "$latest_release" | jq -r ".assets[] | select(.name | contains(\"$package_name\")) | .browser_download_url")"

    curl -LO "$download_url"

    echo "$(pwd)/$package_name"
}

APARTGTK_USER="alexheretic"
APARTGTK_NAME="apart-gtk"
APARTGTK_FILE="apart-gtk_0.28_amd64.deb"

apartgtk_file_path="$(get_release "$APARTGTK_USER" "$APARTGTK_NAME" "$APARTGTK_FILE")"

sudo dpkg -i "$apartgtk_file_path"
sudo apt-get install -y -f  # Install dependencies
