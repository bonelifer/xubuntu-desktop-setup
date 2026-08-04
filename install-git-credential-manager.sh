#!/usr/bin/bash

# Script: install-git-credential-manager.sh
# Description: Script to install Git Credential Manager on Linux
# Usage: ./install-git-credential-manager.sh
# Dependencies: curl, jq, wget

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl jq wget

username="git-ecosystem"
repo_name="git-credential-manager"

# Function to get the latest release's .deb download URL from GitHub
get_latest_release() {
    local response
    response="$(curl --silent "https://api.github.com/repos/$username/$repo_name/releases/latest")"
    local download_url
    download_url="$(echo "$response" | jq -r '.assets[] | select(.name | test("\\.deb$")) | .browser_download_url')"
    echo "$download_url"
}

# Download the latest Git Credential Manager package from GitHub releases
latest_release="$(get_latest_release)"
temp_file="$(mktemp)"
wget -O "$temp_file" "$latest_release"
log "Downloaded: $latest_release"

# Install the Git Credential Manager package using dpkg
sudo dpkg -i "$temp_file"

# Cleanup temporary file
rm "$temp_file"

# Configure Git Credential Manager
git-credential-manager-core configure

