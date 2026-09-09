#!/usr/bin/bash
#
# Script: install-chatgpt.sh
# Description: Installs the ChatGPT desktop app (OpenAI's Codex Electron app,
# rebranded as ChatGPT) from the official .deb. Installing the .deb also
# configures OpenAI's own apt repo, so this is the sole owner of that
# repo/key setup; install-main.sh does not duplicate it.
# Reference: https://learn.chatgpt.com/docs/linux/linux-app

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl sudo dpkg

arch="$(dpkg --print-architecture)"
deb_name="chatgpt_${arch}.deb"
deb_url="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/$deb_name"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

curl -fsSL -o "$temp_dir/$deb_name" "$deb_url"
sudo apt install -y "$temp_dir/$deb_name"

log "ChatGPT desktop installed. Launch it from the applications menu or 'chatgpt'."
