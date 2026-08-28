#!/usr/bin/bash
#
# Script: backup-restore-configs-manager.sh
# Description: Backs up and restores individual configuration files/directories
#              (backup-restore-configs_paths.sh) and the installed-packages list.
#
# Example:
#   To backup configurations:
#   ./backup-restore-configs-manager.sh -b
#
#   To restore configurations:
#   ./backup-restore-configs-manager.sh -r
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

backup_dir="$SCRIPT_DIR/backup/backup_configs"
packages_file="$SCRIPT_DIR/backup/installed_packages.txt"

# shellcheck source=backup-restore-configs_paths.sh
source "$SCRIPT_DIR/backup-restore-configs_paths.sh"

require_cmd rsync

# Backup an individual config file or directory, mirroring its path (relative
# to $HOME) under backup_dir so restore can reverse the mapping symmetrically.
backup_config() {
    local path="${1%/}"
    local rel="${path#"$HOME"/}"
    local dest="$backup_dir/$rel"

    if [ -d "$path" ]; then
        mkdir -p "$dest"
        if rsync -a --delete "$path/" "$dest/"; then
            log "Backup created for directory: $path"
        else
            log_error "Failed to back up directory: $path"
        fi
    elif [ -f "$path" ]; then
        mkdir -p "$(dirname "$dest")"
        if cp "$path" "$dest"; then
            log "Backup created for file: $path"
        else
            log_error "Failed to back up file: $path"
        fi
    else
        log "Path not found, skipping: $path"
    fi
}

restore_config() {
    local path="${1%/}"
    local rel="${path#"$HOME"/}"
    local src="$backup_dir/$rel"

    if [ -d "$src" ]; then
        mkdir -p "$path"
        if rsync -a "$src/" "$path/"; then
            log "Restored directory: $path"
        else
            log_error "Failed to restore directory: $path"
        fi
    elif [ -f "$src" ]; then
        mkdir -p "$(dirname "$path")"
        if cp "$src" "$path"; then
            log "Restored file: $path"
        else
            log_error "Failed to restore file: $path"
        fi
    else
        log "No backup found for: $path, skipping."
    fi
}

backup_installed_packages() {
    mkdir -p "$(dirname "$packages_file")"
    dpkg --get-selections >"$packages_file"
    log "Installed packages list backed up to: $packages_file"
}

perform_backup() {
    log "Starting backup process..."
    mkdir -p "$backup_dir"
    for config in "${software_configs[@]}"; do
        backup_config "$config"
    done
    backup_installed_packages
    log "Backup process completed. Backup files are stored in: $backup_dir"
}

perform_restore() {
    log "Starting restore process..."
    for config in "${software_configs[@]}"; do
        restore_config "$config"
    done
    log "Restore process completed."
}

case "${1:-}" in
    -b|--backup)
        perform_backup
        ;;
    -r|--restore)
        perform_restore
        ;;
    *)
        log "Usage: $0 {-b|--backup|-r|--restore}"
        exit 1
        ;;
esac
