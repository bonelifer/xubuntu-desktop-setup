#!/usr/bin/bash
#
# Script: apply-theme.sh
# Description: Replays a theme snapshot produced by detect-theme.sh
#              (backup/theme.conf): installs any resolved apt packages, then
#              applies the GTK/icon/window-manager/cursor theme, cursor size,
#              and font via xfconf-query.
#
# Usage: ./apply-theme.sh
#
# This is a manual, standalone tool, runnable on its own. For themes with no
# resolved apt package (hand-installed themes), make sure their files are
# already restored to ~/.themes / ~/.icons (e.g. via
# backup-restore-configs-manager.sh -r) before running this, or the theme
# name will be set but Xfce will have nothing on disk to render it with.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd xfconf-query

THEME_CONF="$SCRIPT_DIR/backup/theme.conf"
if [ ! -f "$THEME_CONF" ]; then
    die "No theme snapshot found at $THEME_CONF. Run detect-theme.sh (on the source machine) first."
fi

# theme.conf is generated at runtime by detect-theme.sh (not a tracked
# file), so shellcheck can't follow it statically.
# shellcheck disable=SC1090,SC1091
source "$THEME_CONF"

install_theme_packages() {
    local packages=()
    for pkg in "$GTK_THEME_PACKAGE" "$ICON_THEME_PACKAGE" "$WM_THEME_PACKAGE" "$CURSOR_THEME_PACKAGE"; do
        [ -n "$pkg" ] && packages+=("$pkg")
    done
    if [ "${#packages[@]}" -eq 0 ]; then
        log "No theme packages to install (all themes are file-based or unresolved)."
        return
    fi
    # Packages can repeat (e.g. one theme providing both GTK and WM themes).
    mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)
    log "Installing theme packages: ${packages[*]}"
    sudo apt update
    sudo apt install -y "${packages[@]}"
}

xfconf_set() {
    # xfconf_set <channel> <property> <type> <value>
    local channel="$1" property="$2" type="$3" value="$4"
    if [ -z "$value" ]; then
        return
    fi
    xfconf-query -c "$channel" -p "$property" -n -t "$type" -s "$value" 2>/dev/null \
        || xfconf-query -c "$channel" -p "$property" -s "$value"
}

apply_theme_settings() {
    xfconf_set xsettings /Net/ThemeName string "$GTK_THEME_NAME"
    xfconf_set xsettings /Net/IconThemeName string "$ICON_THEME_NAME"
    xfconf_set xfwm4 /general/theme string "$WM_THEME_NAME"
    xfconf_set xsettings /Gtk/CursorThemeName string "$CURSOR_THEME_NAME"
    xfconf_set xsettings /Gtk/CursorThemeSize int "$CURSOR_THEME_SIZE"
    xfconf_set xsettings /Gtk/FontName string "$FONT_NAME"
    log "Theme settings applied."
}

for name_var_pkg_var in "GTK_THEME_NAME:GTK_THEME_PACKAGE" "ICON_THEME_NAME:ICON_THEME_PACKAGE" \
    "WM_THEME_NAME:WM_THEME_PACKAGE" "CURSOR_THEME_NAME:CURSOR_THEME_PACKAGE"; do
    name_var="${name_var_pkg_var%%:*}"
    pkg_var="${name_var_pkg_var##*:}"
    name_val="${!name_var}"
    pkg_val="${!pkg_var}"
    if [ -n "$name_val" ] && [ -z "$pkg_val" ]; then
        log "Note: $name_var ($name_val) has no apt package -- make sure its files are already restored."
    fi
done

install_theme_packages
apply_theme_settings
