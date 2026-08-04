#!/usr/bin/bash
#
# Script: perform_restore.sh
# Description: Runs every restore-capable backup-restore-*.sh script in
#              restore mode. Mirrors perform_backup.sh.
#
# Most apps are restored generically via backup-restore-configs-manager.sh,
# driven by the path list in backup-restore-configs_paths.sh -- add a new
# app there instead of writing a new backup-restore-<app>.sh script.
#
# backup-crontab.sh and backup-fstab.sh are deliberately NOT called here --
# both are backup-only by design (see their own headers for why): restoring
# an old crontab or fstab over a live one risks silently reverting changes
# made since the backup, so that's left to manual review instead of an
# automatic restore.
#
# Usage: ./perform_restore.sh
#
# Each step is independent and best-effort: one component being unavailable
# (e.g. no KeePassXC backup found) shouldn't stop the rest of the restore
# from running, so this intentionally does not use `set -e`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_step() {
    "$@" || echo "Warning: '$*' exited with a non-zero status." >&2
}

run_step bash "$SCRIPT_DIR/backup-restore-autostart.sh" --restore
run_step bash "$SCRIPT_DIR/backup-restore-fonts.sh" --restore
run_step bash "$SCRIPT_DIR/backup-restore-keepassxc.sh" --restore
run_step bash "$SCRIPT_DIR/backup-restore-plank.sh" restore
run_step bash "$SCRIPT_DIR/backup-restore-trackpoint_touchpad_sensitivity.sh" --load
run_step bash "$SCRIPT_DIR/backup-restore-configs-manager.sh" --restore
