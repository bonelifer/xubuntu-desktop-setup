#!/usr/bin/bash

# -----------------------------------------------------------------------------
# Script: sync-backup.sh
# Description:
#   This Bash script synchronizes an array of directories from a source drive
#   to a destination drive using rsync. It ensures that directory structures
#   are preserved and files are not just dumped into the destination directory.
#
# Usage:
#   ./sync-backup.sh [-d|--delete]
#     -d, --delete: Optional argument to enable deletion of extraneous files from
#                   the destination directory. If not provided, deletions are disabled.
#
# Inputs:
#   - sync-backup.conf (gitignored, copy from sync-backup.conf.example): sets
#     SRCDIR (array of source directory paths to sync) and DSTDIR (the
#     destination directory where they'll be synchronized).
#   - RSYNC_OPTS: Extra rsync flags built from CLI args (currently just --delete).
#
# Outputs:
#   - Synchronized directories in the destination directory.
#
# Dependencies:
#   - rsync
#
# Notes:
#   - Ensure that rsync is installed on your system before running this script.
#   - The script will create directories in the destination path if they don't
#     already exist and will preserve the directory structure.
#   - Progress of the synchronization process will be displayed.
#
# -----------------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/sync-backup.conf"
CONF_EXAMPLE="$SCRIPT_DIR/sync-backup.conf.example"

if [ -f "$CONF_FILE" ]; then
    # shellcheck source=sync-backup.conf
    source "$CONF_FILE"
else
    if [ ! -f "$CONF_EXAMPLE" ]; then
        echo "Missing $CONF_FILE (and no sync-backup.conf.example to seed it from) -- create it with SRCDIR and DSTDIR set." >&2
        exit 1
    fi
    cp "$CONF_EXAMPLE" "$CONF_FILE"
    echo "Seeded $CONF_FILE from sync-backup.conf.example -- edit SRCDIR/DSTDIR for your system, then re-run." >&2
    exit 1
fi

# Parse command line arguments
RSYNC_OPTS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--delete)
            RSYNC_OPTS+=("--delete")
            shift
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
done

# Loop through each source directory and synchronize it with the destination
for dir in "${SRCDIR[@]}"; do
    # Ensure source directory exists
    if [ -d "$dir" ]; then
        echo "Syncing $dir to $DSTDIR..."
        if rsync -av --progress --relative "${RSYNC_OPTS[@]}" "$dir" "$DSTDIR"; then
            echo "Sync completed for $dir."
        else
            echo "Error: Sync failed for $dir."
        fi
    else
        echo "Error: Source directory $dir does not exist."
    fi
done

echo "All directories synced successfully."

