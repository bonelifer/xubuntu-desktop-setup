#!/usr/bin/bash
#
# Script: perform_backup.sh
# Description: Runs every backup-restore-*.sh script in --backup mode.
#
# Most apps are backed up generically via backup-restore-configs-manager.sh,
# driven by the path list in backup-restore-configs_paths.sh -- add a new
# app there instead of writing a new backup-restore-<app>.sh script.
#
# These stay as standalone scripts because they don't just copy a static
# file/directory:
#   - backup-restore-autostart.sh: needs sudo for /etc/xdg/autostart
#   - backup-crontab.sh: reads via the `crontab` command, not files; backup
#     only, not auto-restored (see its own header for why)
#   - backup-fstab.sh: system file under /etc, not $HOME; backup only, not
#     auto-restored (see its own header for why)
#   - backup-restore-fonts.sh: mirrors hand-installed font directories
#   - backup-restore-keepassxc.sh: resolves a dynamic DB path at runtime
#   - backup-restore-plank.sh: dconf dump, not a file
#   - backup-restore-trackpoint_touchpad_sensitivity.sh: gsettings, not files
#
# Usage: ./perform_backup.sh
#
# Each step is independent and best-effort: one component being unavailable
# (e.g. KeePassXC not running) shouldn't stop the rest of the backups from
# running, so this intentionally does not use `set -e`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_step() {
    "$@" || echo "Warning: '$*' exited with a non-zero status." >&2
}

run_step bash "$SCRIPT_DIR/backup-restore-autostart.sh" --backup
run_step bash "$SCRIPT_DIR/backup-crontab.sh" --backup
run_step bash "$SCRIPT_DIR/backup-fstab.sh" --backup
run_step bash "$SCRIPT_DIR/backup-restore-fonts.sh" --backup
run_step bash "$SCRIPT_DIR/backup-restore-keepassxc.sh" --backup
run_step bash "$SCRIPT_DIR/backup-restore-plank.sh" dump
run_step bash "$SCRIPT_DIR/backup-restore-trackpoint_touchpad_sensitivity.sh" --dump
run_step bash "$SCRIPT_DIR/backup-restore-configs-manager.sh" --backup
