#!/usr/bin/bash

# Script: output.sh
# Description: Lists files and folders in the repo root in separate sections in alphabetical order and outputs them to output.txt (written alongside this script, in contrib/)

# Usage: ./output.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OUT_FILE="$SCRIPT_DIR/output.txt"

# Get the list of directories in the repo root (excluding the root itself) and sort them alphabetically
directory_list=$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort)

# Get the list of files in the repo root (excluding dotfiles) and sort them alphabetically
file_list=$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -type f -not -name '.*' -printf '%P\n' | sort)

# Output the sorted lists to output.txt
{
    echo "Directories:"
    echo "$directory_list"
    echo ""
    echo "Files:"
    echo "$file_list"
} > "$OUT_FILE"

# Inform the user that the operation is complete
echo "File list has been saved to $OUT_FILE"
