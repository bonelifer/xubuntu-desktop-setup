#!/usr/bin/bash
#
# Script: backup-restore-cherrytree.sh
# Description: Backup and restore CherryTree databases stored on the desktop.
#
# Usage: ./backup-restore-cherrytree.sh [-b|--backup|-r|--restore]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

backup_dir="$SCRIPT_DIR/backup/cherrytree"

shopt -s nullglob

case "${1:-}" in
    -b|--backup)
        database_files=("$HOME/Desktop/"*.ctb)
        if [ "${#database_files[@]}" -eq 0 ]; then
            log "No CherryTree databases found in: $HOME/Desktop/"
            exit 1
        fi
        mkdir -p "$backup_dir"
        cp -- "${database_files[@]}" "$backup_dir/"
        log "CherryTree databases copied to: $backup_dir/"
        ;;
    -r|--restore)
        database_files=("$backup_dir/"*.ctb)
        if [ "${#database_files[@]}" -eq 0 ]; then
            log "No CherryTree databases found in: $backup_dir/"
            exit 1
        fi
        mkdir -p "$HOME/Desktop"
        cp -- "${database_files[@]}" "$HOME/Desktop/"
        log "CherryTree databases restored to: $HOME/Desktop/"
        ;;
    *)
        log "Usage: $0 {-b|--backup|-r|--restore}"
        exit 1
        ;;
esac
