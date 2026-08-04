#!/usr/bin/bash
#
# Script: install-atuin.sh
# Description: Installs Atuin (shell history sync/search) via its official
# install script and wires up bash shell integration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl

if ! command -v atuin &>/dev/null && [ ! -x "$HOME/.atuin/bin/atuin" ]; then
    log "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
else
    log "Atuin is already installed."
fi

BASHRC="$HOME/.bashrc"
ENV_LINE=". \"\$HOME/.atuin/bin/env\""
# shellcheck disable=SC2016 # intentionally literal -- this gets written into .bashrc verbatim
INIT_LINE='eval "$(atuin init bash)"'

if ! grep -qF "$ENV_LINE" "$BASHRC" 2>/dev/null; then
    echo "$ENV_LINE" >> "$BASHRC"
    log "Added Atuin env sourcing to $BASHRC"
fi

if ! grep -qF "$INIT_LINE" "$BASHRC" 2>/dev/null; then
    echo "$INIT_LINE" >> "$BASHRC"
    log "Added Atuin shell init to $BASHRC"
fi

log "Atuin installation complete."
