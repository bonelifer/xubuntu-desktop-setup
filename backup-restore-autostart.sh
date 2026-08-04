#!/usr/bin/bash
#
# Script: backup-restore-autostart.sh
# Description: This script backs up and restores user and system autostart configurations.
#
# Usage:
#   - To backup autostart configurations:
#       ./backup-restore-autostart.sh -b|--backup
#   - To restore autostart configurations:
#       ./backup-restore-autostart.sh -r|--restore
#   - Verbose mode (optional):
#       ./backup-restore-autostart.sh -v|--verbose
#

set -uo pipefail

# Define paths
script_name=$(basename "$0")
backup_dir="$(dirname "$0")/backup/autostart"

# Function to display usage
usage() {
  echo "Usage: $script_name [-b|--backup|-r|--restore] [-v|--verbose]"
  echo "  -b, --backup   Backup autostart configurations"
  echo "  -r, --restore  Restore autostart configurations"
  echo "  -v, --verbose  Verbose mode (optional)"
  exit 1
}

# Function to backup autostart configurations
backup_autostart() {
  # Create backup directory
  mkdir -p "$backup_dir" || { echo "Error: Failed to create backup directory. Exiting."; exit 1; }

  # Backup autostart entries
  cp -R "$HOME/.config/autostart" "$backup_dir/user_autostart" || { echo "Error: Failed to backup autostart configurations."; exit 1; }
  sudo cp -R "/etc/xdg/autostart" "$backup_dir/system_autostart" || { echo "Error: Failed to backup system autostart configurations."; exit 1; }
}

# Function to restore autostart configurations
restore_autostart() {
  # Check if backup directory exists
  if [ ! -d "$backup_dir" ]; then
    echo "Error: Backup directory not found: $backup_dir"
    exit 1
  fi

  # Restore autostart entries
  cp -R "$backup_dir/user_autostart" "$HOME/.config/autostart" || { echo "Error: Failed to restore autostart configurations."; exit 1; }
  sudo cp -R "$backup_dir/system_autostart" "/etc/xdg/autostart" || { echo "Error: Failed to restore system autostart configurations."; exit 1; }
}

# Check command-line arguments
verbose=false
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -b|--backup)
      action="backup"
      ;;
    -r|--restore)
      action="restore"
      ;;
    -v|--verbose)
      verbose=true
      ;;
    *)
      usage
      ;;
  esac
  shift
done

# Perform action based on provided arguments
case "$action" in
  backup)
    backup_autostart
    ;;
  restore)
    restore_autostart
    ;;
  *)
    usage
    ;;
esac

# Print verbose message if in verbose mode
if [ "$verbose" = true ]; then
  echo "Operation completed successfully."
fi

