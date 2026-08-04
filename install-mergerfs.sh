#!/usr/bin/bash

# Script: install-mergerfs.sh
# Description: Download and install mergerfs from GitHub.
#
# Usage: ./install-mergerfs.sh
#
# Dependencies: curl, jq (for parsing JSON), lsb_release
#
# Notes:
#   - This script detects the Ubuntu version and downloads the appropriate release for that version from a GitHub repository.
#   - Ensure that curl, jq, and lsb_release are installed and accessible in your environment.
#   - This script assumes that the GitHub release assets contain the Ubuntu version in their names.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl jq lsb_release

# Function to get the release information and download the specified package
# for the detected Ubuntu version.
get_release_for_ubuntu_version() {
    local gh_user="$1"
    local gh_repo="$2"
    local package_name="$3"

    local ubuntu_version
    ubuntu_version="$(detect_codename)"

    local latest_release
    latest_release="$(curl -s "https://api.github.com/repos/$gh_user/$gh_repo/releases/latest")"

    local download_url
    download_url="$(echo "$latest_release" | jq -r ".assets[] | select(.name | contains(\"$package_name\")) | select(.name | contains(\"$ubuntu_version\")) | .browser_download_url")"

    if [ -z "$download_url" ]; then
        die "No matching asset found for $package_name for Ubuntu version $ubuntu_version."
    fi

    local download_path
    download_path="$(mktemp)"
    if ! curl -L -o "$download_path" "$download_url"; then
        die "Failed to download $package_name for Ubuntu version $ubuntu_version."
    fi

    echo "$download_path"
}

MERGERFS_USER="trapexit"
MERGERFS_NAME="mergerfs"
MERGERFS_FILE="_amd64.deb"

mergerfs_file_path="$(get_release_for_ubuntu_version "$MERGERFS_USER" "$MERGERFS_NAME" "$MERGERFS_FILE")"
sudo dpkg -i "$mergerfs_file_path"
sudo apt-get install -y -f  # Install dependencies
