#!/usr/bin/bash
#
# Script: backup-restore-personal-data.sh
# Description: Backup and restore personal data directories under $HOME.
#
# Usage: ./backup-restore-personal-data.sh [-b|--backup|-r|--restore]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd rsync

personal_data_dir="$SCRIPT_DIR/personal-data"
personal_dirs=(
    "Desktop"
    "Documents"
    "Downloads"
    "EBOOKS"
    "Calibre Library"
    "CODE"
    "MESSAGES"
    "Patiobar"
    "Pictures"
    "projects"
    "Videos"
    "Music"
    "Worktree"
)
personal_files=(
    ".gist"
    ".googledrive.conf"
    ".my.cnf"
    ".netrc"
    ".pgpass"
    "audac.sh"
    "favicon.ico"
    "Willie Nelson-audio.zip"
)

backup_personal_data() {
    local name source_dir destination_dir

    mkdir -p "$personal_data_dir"
    for name in "${personal_dirs[@]}"; do
        source_dir="$HOME/$name"
        destination_dir="$personal_data_dir/$name"
        if [ -d "$source_dir" ]; then
            mkdir -p "$destination_dir"
            if rsync -a "$source_dir/" "$destination_dir/"; then
                log "Personal data backed up: $source_dir"
            else
                log_error "Failed to back up personal data: $source_dir"
            fi
        else
            log "Personal data directory not found, skipping: $source_dir"
        fi
    done

    for name in "${personal_files[@]}"; do
        source_dir="$HOME/$name"
        destination_dir="$personal_data_dir/$name"
        if [ -f "$source_dir" ]; then
            if rsync -a "$source_dir" "$destination_dir"; then
                log "Personal data file backed up: $source_dir"
            else
                log_error "Failed to back up personal data file: $source_dir"
            fi
        else
            log "Personal data file not found, skipping: $source_dir"
        fi
    done
}

restore_personal_data() {
    local name source_dir destination_dir

    for name in "${personal_dirs[@]}"; do
        source_dir="$personal_data_dir/$name"
        destination_dir="$HOME/$name"
        if [ -d "$source_dir" ]; then
            mkdir -p "$destination_dir"
            if rsync -a "$source_dir/" "$destination_dir/"; then
                log "Personal data restored: $destination_dir"
            else
                log_error "Failed to restore personal data: $destination_dir"
            fi
        else
            log "Personal data backup not found, skipping: $source_dir"
        fi
    done

    for name in "${personal_files[@]}"; do
        source_dir="$personal_data_dir/$name"
        destination_dir="$HOME/$name"
        if [ -f "$source_dir" ]; then
            if rsync -a "$source_dir" "$destination_dir"; then
                log "Personal data file restored: $destination_dir"
            else
                log_error "Failed to restore personal data file: $destination_dir"
            fi
        else
            log "Personal data file backup not found, skipping: $source_dir"
        fi
    done
}

case "${1:-}" in
    -b|--backup)
        backup_personal_data
        ;;
    -r|--restore)
        restore_personal_data
        ;;
    *)
        log "Usage: $0 {-b|--backup|-r|--restore}"
        exit 1
        ;;
esac
