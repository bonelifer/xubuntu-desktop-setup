#!/usr/bin/bash
# Shared helpers for xubuntu-desktop-setup scripts. Source this near the top of a
# script after setting SCRIPT_DIR, e.g.:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"

log() {
    printf '%s\n' "$*"
}

log_error() {
    printf 'Error: %s\n' "$*" >&2
}

die() {
    log_error "$*"
    exit 1
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        die "This script must be run as root (use sudo)."
    fi
}

require_not_root() {
    if [ "$EUID" -eq 0 ]; then
        die "This script should not be run as root."
    fi
}

require_cmd() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            die "Required command not found: $cmd"
        fi
    done
}

# Prints the distro release codename (e.g. "jammy", "noble"), or "unknown"
# if lsb_release is unavailable.
detect_codename() {
    if command -v lsb_release &>/dev/null; then
        lsb_release -cs
    else
        echo "unknown"
    fi
}

print_usage_and_exit() {
    local usage="$1"
    log "Usage: $usage"
    exit 1
}
