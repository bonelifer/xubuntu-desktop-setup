#!/usr/bin/bash

#
# Script: install-git.sh
# Description: Configure Git and install GitHub Desktop on Ubuntu.
# Reference: https://itsfoss.com/install-git-ubuntu/
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

GIT_CONF="$SCRIPT_DIR/git.conf"
GIT_CONF_EXAMPLE="$SCRIPT_DIR/git.conf.example"

if [ -f "$GIT_CONF" ]; then
    # shellcheck source=git.conf
    source "$GIT_CONF"
else
    if [ ! -f "$GIT_CONF_EXAMPLE" ]; then
        die "Missing $GIT_CONF (and no git.conf.example to seed it from) -- create it with GIT_USER_NAME and GIT_USER_EMAIL set."
    fi
    cp "$GIT_CONF_EXAMPLE" "$GIT_CONF"
    log "Seeded $GIT_CONF from git.conf.example -- enter your git identity now."

    read -r -p "Git user.name: " GIT_USER_NAME
    read -r -p "Git user.email: " GIT_USER_EMAIL

    # Persist what was entered so future runs don't ask again.
    sed -i "s|^GIT_USER_NAME=.*|GIT_USER_NAME=\"$GIT_USER_NAME\"|" "$GIT_CONF"
    sed -i "s|^GIT_USER_EMAIL=.*|GIT_USER_EMAIL=\"$GIT_USER_EMAIL\"|" "$GIT_CONF"
fi

# Install git and GitHub Desktop
echo "ppa:git-core/ppa" | sudo tee /etc/apt/sources.list.d/git-core.list
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/mwt-desktop.gpg > /dev/null
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list'
if ! { sudo apt update && sudo apt install -y git github-desktop; }; then
    echo "Failed to install Git or GitHub Desktop. Exiting."
    exit 1
fi

# Check if Git is installed
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Please install Git before running this script."
    exit 1
fi

# Configure Git Credentials
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global color.ui auto
sudo git config --system core.editor nano
git config --global core.autocrlf input
git config --global core.excludesfile ~/bin/staging/.gitignore_global

