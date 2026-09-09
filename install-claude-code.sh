#!/usr/bin/bash
#
# Script: install-claude-code.sh
# Description: Installs the Claude Code CLI via Anthropic's official
# installer script. Installs to $HOME/.local/bin and auto-updates itself in
# the background; no apt repo involved.
# Reference: https://code.claude.com/docs/en/terminal-guide

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl

if command -v claude &>/dev/null; then
    log "Claude Code is already installed."
else
    log "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi
