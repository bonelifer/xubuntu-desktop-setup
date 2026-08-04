#!/usr/bin/bash
#
# Script: backup-restore-fonts.sh
# Description: Backup and restore hand-installed font files (apt-installed
# fonts don't need this -- apt reinstalls them). Mirrors the actual font
# directories, not just a list of font names, so a restore can recover the
# real font files on a fresh install.
#
# Usage: ./backup-restore-fonts.sh [-b|--backup|-r|--restore]
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd rsync

backup_dir="$SCRIPT_DIR/backup/fonts"

# Hand-installed font directories -- ~/.fonts is the legacy path, current
# apps use ~/.local/share/fonts.
font_dirs=(
    "$HOME/.fonts"
    "$HOME/.local/share/fonts"
)

backup_fonts() {
    mkdir -p "$backup_dir"
    for dir in "${font_dirs[@]}"; do
        local rel="${dir#"$HOME"/}"
        local dest="$backup_dir/$rel"
        if [ -d "$dir" ]; then
            mkdir -p "$dest"
            if rsync -a --delete "$dir/" "$dest/"; then
                log "Backup created for directory: $dir"
            else
                log_error "Failed to back up directory: $dir"
            fi
        else
            log "Path not found, skipping: $dir"
        fi
    done
}

restore_fonts() {
    for dir in "${font_dirs[@]}"; do
        local rel="${dir#"$HOME"/}"
        local src="$backup_dir/$rel"
        if [ -d "$src" ]; then
            mkdir -p "$dir"
            if rsync -a "$src/" "$dir/"; then
                log "Restored directory: $dir"
            else
                log_error "Failed to restore directory: $dir"
            fi
        else
            log "No backup found for: $dir, skipping."
        fi
    done
}

case "${1:-}" in
    -b|--backup)
        backup_fonts
        ;;
    -r|--restore)
        restore_fonts
        ;;
    *)
        log "Usage: $0 {-b|--backup|-r|--restore}"
        exit 1
        ;;
esac
