#!/usr/bin/bash

# Script: install-firefox.sh
# Description: Switches Firefox from the Ubuntu snap to Mozilla's official
#              apt repository (removes the snap, adds the repo + signing
#              key, and pins the package so a distro update can't silently
#              swap it back to the snap), then restores the Firefox profile.
# Reference: Based on the Ansible playbook at https://www.hackitu.de/firefox_snap_apt/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd wget dpkg

# Not an error if the snap was never installed.
remove_snap_package() {
    sudo snap remove firefox || true
}

# Download the Mozilla repository signing key and trust it.
add_mozilla_repo_key() {
    sudo wget -O /etc/apt/trusted.gpg.d/mozilla.asc https://packages.mozilla.org/apt/repo-signing-key.gpg
    sudo chown root:root /etc/apt/trusted.gpg.d/mozilla.asc
    sudo chmod 0644 /etc/apt/trusted.gpg.d/mozilla.asc
}

# Add the Mozilla repository to the APT sources list and update the package list.
add_mozilla_repository() {
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/mozilla.asc] https://packages.mozilla.org/apt mozilla main" \
        | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    sudo apt update
}

# Pin the Mozilla-repo firefox package above the distro/snap version so
# upgrades can't silently switch it back.
pin_mozilla_packages() {
    cat <<EOF | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
Package: firefox
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
    sudo chown root:root /etc/apt/preferences.d/mozilla
    sudo chmod 0644 /etc/apt/preferences.d/mozilla
}

install_firefox() {
    sudo apt install -y --allow-downgrades firefox
}

# Use files/pngegg.png as Firefox's icon by overriding its desktop entry
# under ~/.local/share/applications, which takes priority over the system
# one and survives package upgrades (which would otherwise reset the icon).
set_firefox_icon() {
    local icon_dir="$HOME/bin/logo"
    local icon_dest="$icon_dir/pngegg.png"
    local icon_src="$SCRIPT_DIR/files/pngegg.png"

    mkdir -p "$HOME/bin" "$icon_dir"
    if [ ! -f "$icon_src" ]; then
        log_error "Icon source not found: $icon_src, skipping icon setup."
        return
    fi
    cp "$icon_src" "$icon_dest"

    local desktop_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_dir/firefox.desktop"
    mkdir -p "$desktop_dir"

    if [ -f /usr/share/applications/firefox.desktop ]; then
        cp /usr/share/applications/firefox.desktop "$desktop_file"
    elif [ ! -f "$desktop_file" ]; then
        cat <<EOF > "$desktop_file"
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF
    fi

    if grep -q '^Icon=' "$desktop_file"; then
        sed -i "s|^Icon=.*|Icon=$icon_dest|" "$desktop_file"
    else
        echo "Icon=$icon_dest" >> "$desktop_file"
    fi

    command -v update-desktop-database &>/dev/null && update-desktop-database "$desktop_dir"
    log "Firefox icon set to $icon_dest"
}

if dpkg -s firefox 2>/dev/null | grep -q "Status: install"; then
    log "Firefox is already installed from the Mozilla repository."
else
    remove_snap_package
    add_mozilla_repo_key
    add_mozilla_repository
    pin_mozilla_packages
    install_firefox
    log "Firefox has been switched from Snap to the Debian package from Mozilla's repository."
fi

set_firefox_icon

# Restore Firefox profile (via the generic config manager; backup-restore-firefox.sh
# was folded into backup-restore-configs_paths.sh, so this restores everything in
# that manifest, not just Firefox).
bash "$SCRIPT_DIR/backup-restore-configs-manager.sh" -r
