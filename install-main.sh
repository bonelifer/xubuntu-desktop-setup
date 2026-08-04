#!/usr/bin/bash
#
# Script: install-main.sh
# Description:
# Orchestrates the setup of a new Ubuntu/Xubuntu system by:
# 1. Enabling universe/multiverse/partner repositories and third-party PPAs/repos.
# 2. Refreshing package lists and performing a full upgrade.
# 3. Installing the core package set (packages.conf), PHP, DVD codecs, fonts,
#    topgrade, and Node.js.
# 4. Installing Snap and Flatpak packages (packages.conf).
# 5. Running each core install-*.sh module (packages.conf: CORE_MODULES).
# 6. Optionally running hardware-specific/security-sensitive modules when
#    explicitly requested with --with-<name> (packages.conf: OPTIONAL_MODULES).
#
# Usage:
#   ./install-main.sh [--with-<optional-module> ...] [--list] [-h|--help]
#
# Run --list to see available optional modules.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=packages.conf
source "$SCRIPT_DIR/packages.conf"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--with-<optional-module> ...] [--list] [-h|--help]

Optional modules (skipped unless requested):
$(for key in "${!OPTIONAL_MODULES[@]}"; do echo "  --with-$key  (${OPTIONAL_MODULES[$key]})"; done | sort)
EOF
}

with_modules=()
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        --list)
            usage
            exit 0
            ;;
        --with-*)
            key="${arg#--with-}"
            if [ -z "${OPTIONAL_MODULES[$key]+set}" ]; then
                die "Unknown optional module: $key (see --list)"
            fi
            with_modules+=("$key")
            ;;
        *)
            die "Unknown argument: $arg (see --help)"
            ;;
    esac
done

require_not_root
require_cmd sudo lsb_release curl wget

codename="$(detect_codename)"

add_apt_source() {
    # add_apt_source <list-name> <deb-line...>
    local list_name="$1"
    shift
    printf '%s\n' "$@" | sudo tee "/etc/apt/sources.list.d/${list_name}.list" >/dev/null
}

add_keyed_repo() {
    # add_keyed_repo <name> <key-url> <deb-line>
    local name="$1" key_url="$2" deb_line="$3"
    local keyring="/etc/apt/keyrings/${name}.gpg"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL "$key_url" | sudo gpg --dearmor --yes -o "$keyring"
    add_apt_source "$name" "${deb_line/signed-by:/signed-by=$keyring}"
}

enable_base_repos() {
    log "Enabling universe/multiverse/partner repositories..."
    # A dedicated sources.list.d file instead of appending to the shared
    # /etc/apt/sources.list: re-running this (e.g. a second install-main.sh
    # pass) overwrites the file with the same content instead of piling up
    # duplicate active "deb" lines in sources.list on every run.
    {
        echo "deb http://archive.ubuntu.com/ubuntu $codename universe"
        echo "deb http://archive.ubuntu.com/ubuntu $codename multiverse"
        echo "deb http://archive.ubuntu.com/ubuntu ${codename}-updates multiverse"
        echo "deb http://archive.ubuntu.com/ubuntu ${codename}-backports main restricted universe multiverse"
        echo "deb http://security.ubuntu.com/ubuntu/ ${codename}-security multiverse"
        echo "deb http://archive.canonical.com/ubuntu $codename partner"
    } | sudo tee /etc/apt/sources.list.d/ubuntu-extra-components.list >/dev/null
}

add_ppas() {
    log "Adding PPAs..."
    for ppa in "${PPAS[@]}"; do
        sudo add-apt-repository -y "$ppa"
    done
}

add_third_party_repos() {
    log "Adding third-party keyed repositories..."
    # Note: WineHQ and Webmin repos are intentionally NOT added here.
    # install-winehq.sh and install-webmin.sh (both CORE_MODULES) own those
    # repos end-to-end so there is exactly one place each is configured.

    add_keyed_repo yarn https://dl.yarnpkg.com/debian/pubkey.gpg \
        "deb [signed-by:] https://dl.yarnpkg.com/debian/ stable main"

    add_keyed_repo onedrive https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_20.04/Release.key \
        "deb [signed-by:] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/Ubuntu_22.04/ ./"

    add_keyed_repo systray-x https://download.opensuse.org/repositories/home:/Ximi1970/xUbuntu_20.04/Release.key \
        "deb [signed-by:] https://download.opensuse.org/repositories/home:/Ximi1970:/Mozilla:/Add-ons/xUbuntu_20.04 ./"

    add_apt_source spotify "deb http://repository.spotify.com stable non-free"
}

install_core_packages() {
    log "Refreshing package list and performing full upgrade..."
    sudo apt update && sudo apt -y full-upgrade

    log "Installing core packages..."
    sudo apt install -y --install-recommends "${APT_PACKAGES[@]}"

    local version_id
    version_id="$(. /etc/os-release && echo "$VERSION_ID")"
    if dpkg --compare-versions "$version_id" ge "22.04"; then
        sudo apt install -y webp-pixbuf-loader
    else
        log "OS version $version_id predates 22.04; skipping webp-pixbuf-loader."
    fi

    log "Installing PHP 8.4..."
    sudo apt install -y "${PHP_PACKAGES[@]}"
    sudo systemctl restart php8.4-fpm.service

    log "Installing DVD integration..."
    sudo apt install -y libdvd-pkg libdvdread7
    sudo dpkg-reconfigure libdvd-pkg

    log "Accepting ttf-mscorefonts-installer EULA and installing..."
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
    sudo apt-get install -y ttf-mscorefonts-installer

    log "Installing topgrade via Cargo..."
    cargo install topgrade
    export PATH="$PATH:$HOME/.cargo/bin"

    log "Installing Node.js via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -

    log "Purging unwanted packages..."
    sudo apt purge -y "${APT_PURGE_PACKAGES[@]}"
}

install_snaps() {
    log "Installing snap packages..."
    sudo snap refresh
    sudo snap install "${SNAP_PACKAGES[@]}"
    for entry in "${SNAP_CLASSIC_PACKAGES[@]}"; do
        IFS=':' read -r name channel flags <<<"$entry"
        # shellcheck disable=SC2086
        sudo snap install "$name" ${channel:+--channel="$channel"} $flags
    done
}

install_flatpaks() {
    log "Installing flatpak packages..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    for entry in "${FLATPAK_PACKAGES[@]}"; do
        IFS=':' read -r remote app <<<"$entry"
        flatpak install -y "$remote" "$app"
    done
    flatpak install -y flathub org.keepassxc.KeePassXC --user
    flatpak override --user org.keepassxc.KeePassXC raw-usb
}

run_core_modules() {
    log "Running core install modules..."
    for module in "${CORE_MODULES[@]}"; do
        local module_path="$SCRIPT_DIR/$module"
        if [ -x "$module_path" ] || [ -f "$module_path" ]; then
            log "--- $module ---"
            bash "$module_path"
        else
            log_error "Module not found, skipping: $module"
        fi
    done
}

run_optional_modules() {
    for key in "${with_modules[@]}"; do
        local module="${OPTIONAL_MODULES[$key]}"
        local module_path="$SCRIPT_DIR/$module"
        log "--- optional: $module ---"
        bash "$module_path"
    done
}

install_grub_customizer() {
    log "Installing GRUB Customizer..."
    sudo apt update
    sudo apt install -y grub-customizer
}

install_gotify_tray() {
    log "Installing Gotify Tray..."
    pip3 install gotify-tray
}

main() {
    enable_base_repos
    add_ppas
    add_third_party_repos
    install_core_packages
    install_snaps
    install_flatpaks
    run_core_modules
    run_optional_modules
    install_grub_customizer
    install_gotify_tray

    if command -v thunar &>/dev/null && [ -n "${DISPLAY:-}" ]; then
        thunar "$SCRIPT_DIR/notes" &
    fi

    log "install-main.sh complete."
}

main
