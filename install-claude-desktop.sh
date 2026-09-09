#!/usr/bin/bash
#
# Script: install-claude-desktop.sh
# Description: Installs Claude Desktop via Anthropic's official apt repo.
# This is the sole owner of the Claude Desktop repo/key setup; install-main.sh
# does not duplicate it.
# Reference: https://support.claude.com/en/articles/10065433-install-claude-desktop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl sudo

keyring="/usr/share/keyrings/claude-desktop-archive-keyring.asc"

sudo curl -fsSLo "$keyring" https://downloads.claude.ai/claude-desktop/key.asc
echo "deb [signed-by=$keyring] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null

sudo apt update
sudo apt install -y claude-desktop

log "Claude Desktop installed. Launch it from the applications menu or 'claude-desktop'."
