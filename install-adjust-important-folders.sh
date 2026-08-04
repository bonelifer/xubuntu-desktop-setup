#!/usr/bin/bash
#
# Script: install-adjust-important-folders.sh
# Description: This script updates the user-dirs.dirs file to configure default directories for user data in the XDG user directory specification.
#
# Notes:
#   - Before running the script, ensure that you review and remove the specified code block.
#   - After execution, log out and log back in or restart your desktop environment for changes to take effect.
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Must run as the actual desktop user, not root -- otherwise $HOME resolves
# to /root and this would silently edit root's user-dirs.dirs instead of
# the person who's actually running it.
require_not_root

# Path to user-dirs.dirs file
USER_DIRS_FILE="$HOME/.config/user-dirs.dirs"

# Backup existing user-dirs.dirs file
backup_file="$SCRIPT_DIR/user-dirs.dirs.bak"
cp "$USER_DIRS_FILE" "$backup_file" 2>/dev/null || { echo "Error: Failed to create backup file. Exiting."; exit 1; }


# Check if the script has been modified
grep -q '# REMOVE_THIS_CODE_BLOCK_START' "$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")" && \
echo "ERROR: Please remove the code block marked with comments (between '# REMOVE_THIS_CODE_BLOCK_START' and '# REMOVE_THIS_CODE_BLOCK_END') before running the script." && \
exit 1

# Hardcoded paths for default XDG user directories
DESKTOP_DIR="$HOME/Desktop"
DOWNLOAD_DIR="$HOME/Downloads"
TEMPLATES_DIR="$HOME/Templates"
PUBLICSHARE_DIR="$HOME/Public"
DOCUMENTS_DIR="$HOME/Documents"
MUSIC_DIR="$HOME/Music"
PICTURES_DIR="$HOME/Pictures"
VIDEOS_DIR="$HOME/Videos"

# Set (or update in place, if already present) a single XDG_*_DIR entry in
# user-dirs.dirs, instead of blindly appending -- otherwise re-running this
# script piles up duplicate, simultaneously-active XDG_*_DIR keys forever.
set_xdg_dir() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$USER_DIRS_FILE"; then
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$USER_DIRS_FILE"
  else
    echo "${key}=\"${value}\"" >> "$USER_DIRS_FILE"
  fi
}

# Check for confirmation before proceeding
read -r -p "This script will modify user-dirs.dirs. Are you sure you want to proceed? (y/n): " confirmation
if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo "Script execution aborted."
    exit 1
fi

# User must remove the following code block before running the script
: '
# REMOVE_THIS_CODE_BLOCK_START
echo "ERROR: The specified code block has not been removed. Please review the script and remove the code block marked with comments (between '# REMOVE_THIS_CODE_BLOCK_START' and '# REMOVE_THIS_CODE_BLOCK_END') before executing."
exit 1
# REMOVE_THIS_CODE_BLOCK_END
'

# Set (or update) the XDG user directory paths.
set_xdg_dir "XDG_DESKTOP_DIR" "$DESKTOP_DIR"
set_xdg_dir "XDG_DOWNLOAD_DIR" "$DOWNLOAD_DIR"
set_xdg_dir "XDG_TEMPLATES_DIR" "$TEMPLATES_DIR"
set_xdg_dir "XDG_PUBLICSHARE_DIR" "$PUBLICSHARE_DIR"
set_xdg_dir "XDG_DOCUMENTS_DIR" "$DOCUMENTS_DIR"
set_xdg_dir "XDG_MUSIC_DIR" "$MUSIC_DIR"
set_xdg_dir "XDG_PICTURES_DIR" "$PICTURES_DIR"
set_xdg_dir "XDG_VIDEOS_DIR" "$VIDEOS_DIR"

echo "User directories updated. A backup of the original file has been created: $backup_file"
echo "Please log out and log back in or restart your desktop environment for the changes to take effect."

