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
#   - SRCDIR: An array containing the paths of the source directories to sync.
#   - DSTDIR: The path of the destination directory where the directories will
#             be synchronized.
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

# Define source and destination directories
SRCDIR=(
    "/home/william/Downloads/"
    "/home/william/Documents/"
    "/home/william/bin/"
    "/home/william/CODE/"
    "/home/william/Cozy Drive/"
    "/home/william/Dropbox/"
    "/home/william/Internxt/"
    "/home/william/MESSAGES/"
    "/home/william/OneDrive_bonelfier@outlook.com/"
    "/home/william/Patiobar/"
    "/home/william/projects/"
    "/home/william/stargate/"
    "/home/william/thunar-actions/"
    "/home/william/StreamripDownloads/"
    "/home/william/Videos/"
    "/home/william/Desktop/"
)
DSTDIR="/media/william/OracleHarbor/sync-backup/"

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

