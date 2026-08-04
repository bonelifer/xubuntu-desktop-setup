#!/usr/bin/bash

# Script: other-file-list.sh
# Description: Lists files and folders in the repo root in separate sections in alphabetical order and outputs them to other-file-list.txt (written alongside this script, in contrib/)
# Only outputs filenames that do not contain "backup" or "restore".
# Usage: ./other-file-list.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OUT_FILE="$SCRIPT_DIR/other-file-list.txt"

# Get the list of directories in the repo root (excluding the root itself) and sort them alphabetically
directory_list=$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

# Get the list of files that do not contain "backup" or "restore" in the repo root and sort them alphabetically
file_list=$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -type f ! \( -iname "*backup*" -o -iname "*restore*" \) -exec basename {} \; | sort)

# Output the sorted lists to other-file-list.txt
{
    echo "Directories:"
    echo "$directory_list"
    echo ""
    echo "Files:"
    echo "$file_list"
} > "$OUT_FILE"

# List of files to exclude from other-file-list.txt (scaffolding/output files)
files_to_remove=(
    "filelist.sh"
    "filelist.txt"
    "other-file-list.sh"
    "other-file-list.txt"
    "output.sh"
    "output.txt"
    "backup-restore-configs_paths.sh"
)

# Loop through each file to remove
tmp_file="$(mktemp)"
for file_to_remove in "${files_to_remove[@]}"; do
    grep -vF "$file_to_remove" "$OUT_FILE" > "$tmp_file" || true
    mv "$tmp_file" "$OUT_FILE"
done

# Inform the user that the operation is complete
echo "File list has been saved to $OUT_FILE"
