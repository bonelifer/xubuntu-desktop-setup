#!/usr/bin/bash
#
# Script: install-communications.sh
# Description: Installs Zoom and Discord on Xubuntu systems by downloading
# their deb files directly (neither publishes an official apt repo/PPA).
#
# Note: Skype and Caprine were dropped from this script -- Skype because
# Microsoft shut down the service (retired May 2025), and Caprine because
# its apt repo (caprine-releases.now.sh, a legacy Vercel/Zeit domain) is dead.
# Discord was previously installed via snap; switched to the direct deb here
# for consistency with Zoom, since Discord has no official apt repo either.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd wget dpkg

# Function to install a package from a deb file
install_package() {
    local package_name="$1"
    local deb_file="$2"
    local download_url="$3"
    wget -qO "$deb_file" "$download_url" || die "Failed to download $package_name from $download_url"
    sudo apt install -y ./"$deb_file" || die "Failed to install $package_name"
    rm "$deb_file"
}

# The stock Discord .deb's desktop entry doesn't always pass the clicked
# URL through to the discord:// handler -- fix the Exec line so URI clicks
# (invite/join links) actually open the app, and register it as the
# handler for the discord:// scheme.
fix_discord_url_handler() {
    local desktop_file="/usr/share/applications/discord.desktop"
    if [ -f "$desktop_file" ]; then
        sudo sed -i 's|^Exec=.*|Exec=/usr/bin/discord --url -- %u|' "$desktop_file"
        command -v xdg-mime &>/dev/null && xdg-mime default discord.desktop x-scheme-handler/discord
        command -v update-desktop-database &>/dev/null && sudo update-desktop-database /usr/share/applications
        log "Registered discord.desktop as the discord:// URL handler"
    else
        log_error "discord.desktop not found, skipping URL handler registration"
    fi
}

## Install Zoom
if ! dpkg -s zoom &>/dev/null; then
    install_package "Zoom" "zoom.deb" "https://zoom.us/client/latest/zoom_amd64.deb"
fi

## Install Discord
if ! dpkg -s discord &>/dev/null; then
    install_package "Discord" "discord.deb" "https://discord.com/api/download?platform=linux&format=deb"
fi
fix_discord_url_handler
