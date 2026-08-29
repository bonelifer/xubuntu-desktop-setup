# shellcheck shell=bash disable=SC2034
# backup-restore-configs_paths.sh
# Manifest of files/directories backed up and restored by
# backup-restore-configs-manager.sh. Add a new app here instead of writing
# a dedicated backup-restore-<app>.sh script.
#
# Anything that is a static path under $HOME belongs here. Config backups
# that need real logic (a live command's output, a non-file store like
# dconf/gsettings, or a dynamically-resolved path) stay as their own
# standalone backup-restore-*.sh script -- see the comment at the top of
# perform_backup.sh for the current list.
#
# Sourced only by backup-restore-configs-manager.sh, which defines SCRIPT_DIR
# before sourcing this file.

# shellcheck source=packages.conf
source "$SCRIPT_DIR/packages.conf"

software_configs=(
    "$HOME/.config/atuin"                          # Atuin shell history config (incl. sync encryption key)
    "$HOME/.local/share/atuin"                     # Atuin shell history database
    "$HOME/.config/spotify/"                       # Spotify config
    "$HOME/.config/tilda/"                         # Tilda terminal config
    "$HOME/.config/variety/"                       # Variety config
    "$HOME/.config/pithos.ini"                     # Pithos config
    "$HOME/.config/onedrive/"                      # OneDrive config
    "$HOME/.config/libreoffice"                    # LibreOffice config
    "$HOME/.config/user-dirs.dirs"                 # User directories config
    "$HOME/.config/starship.toml"                  # Starship prompt config
    "$HOME/.config/world_clock_plugin@hanzala123/" # World clock plugin config
    "$HOME/.config/Thunar"                         # Thunar file manager config
    "$HOME/thunar-actions"                         # Thunar custom action scripts
    "$HOME/.config/streamrip"                      # Streamrip config
    "$HOME/.config/spicetify"                      # Spicetify config
    "$HOME/.config/solaar"                         # Solaar config
    "$HOME/.config/radiotray-ng"                   # Radiotray-ng config
    "$HOME/.config/puddletag"                      # Puddletag config
    "$HOME/.config/pluma"                          # Pluma text editor config
    "$HOME/.config/pianobar"                       # Pianobar config
    "$HOME/.config/mpd"                            # MPD (Music Player Daemon) config
    "$HOME/.config/keepassxc"                      # KeePassXC config
    "$HOME/.config/GitHub Desktop"                 # GitHub Desktop config
    "$HOME/.config/ghostwriter"                    # Ghostwriter config
    "$HOME/.config/cod-ibroadcast/"                # cod-ibroadcast config
    "$HOME/.config/cherrytree"                     # Cherrytree note-taking app config
    "$HOME/.config/acsm-get"                       # acsm-get config
    "$HOME/.config/xfce4"                          # Xfce4 desktop environment settings
    "$HOME/.xmltv"                                 # XMLTV configuration and data
    "$HOME/.imapfilter"                            # IMAPFilter configuration
    "$HOME/.filebot"                               # FileBot configuration and data

    # Absorbed from backup-restore-persona-settings.sh:
    "$HOME/.ssh"                                   # SSH config, keys, and authorized keys
    "$HOME/.gnupg"                                 # GnuPG keys and configuration
    "$HOME/.password-store"                        # pass password store
    "$HOME/.local/share/keyrings"                  # GNOME Keyring data
    "$HOME/.local/share/kwalletd"                  # KDE Wallet data
    "$HOME/.config/systemd/user"                   # User services and timers
    "$HOME/.local/share/applications"              # Custom desktop launchers
    "$HOME/.bashrc"                                # Bash rc
    "$HOME/.bash_aliases"                          # Bash aliases
    "$HOME/.bash_history"                          # Bash history
    "$HOME/.bash_profile"                          # Bash profile
    "$HOME/.bash_login"                            # Bash login
    "$HOME/Applications"                           # User-installed applications
    "$HOME/bin"                                    # Custom scripts/binaries

    # Absorbed from backup-restore-misc.sh:
    "$HOME/.gitconfig"                             # Git config
    "$HOME/.msmtprc"                               # msmtp config
    "$HOME/.pgpass"                                # PostgreSQL password file
    "$HOME/.mailrc"                                # mailrc config
    "$HOME/.git-credentials"                       # Git credential store
    "$HOME/.smbcredentials"                        # Samba credentials

    # Absorbed from backup-restore-firefox.sh / backup-restore-thunderbird.sh:
    "$HOME/.mozilla/firefox"                       # Firefox profile
    "$HOME/.thunderbird"                           # Thunderbird profile

    # Absorbed from backup-restore-faces-avatar-whisker-menu.sh:
    "$HOME/.face"                                  # User avatar/face file

    # Hand-installed (non-apt-package) GTK/icon/cursor themes -- needed by
    # apply-theme.sh for any theme detect-theme.sh couldn't resolve to a
    # package. Apt-resolved themes don't need this; they're reinstalled by
    # apply-theme.sh from backup/theme.conf instead.
    "$HOME/.themes"                                # Hand-installed GTK/WM themes
    "$HOME/.icons"                                 # Hand-installed icon/cursor themes

    # Apt-installed apps with real config dirs not previously covered.
    # Audacity and VeraCrypt have version-dependent config locations --
    # both candidate paths are listed; the backup engine silently skips
    # whichever one doesn't exist.
    "$HOME/.config/audacity/"                      # Audacity (newer versions)
    "$HOME/.audacity-data/"                        # Audacity (older versions)
    "$HOME/.config/brasero"                        # Brasero disc burning config
    "$HOME/.config/Clementine"                     # Clementine music player config
    "$HOME/.config/deluge"                         # Deluge torrent client config
    "$HOME/.config/filezilla"                      # FileZilla config
    "$HOME/.config/gpodder"                        # gPodder config
    "$HOME/.config/Kid3"                           # Kid3 tag editor config
    "$HOME/.config/kritarc"                        # Krita config
    "$HOME/.config/mc"                             # Midnight Commander config
    "$HOME/.config/MusicBrainz/Picard.conf"        # MusicBrainz Picard config
    "$HOME/.putty"                                 # PuTTY config
    "$HOME/.config/sqlitebrowser"                  # DB Browser for SQLite config
    "$HOME/.VeraCrypt"                             # VeraCrypt config (older versions)
    "$HOME/.config/VeraCrypt"                      # VeraCrypt config (newer versions)
    "$HOME/.config/vlc"                            # VLC config
    "$HOME/.config/winff"                          # WinFF config
    "$HOME/.config/font-manager"                   # Font Manager config

    # Installed via install-communications.sh / install-virtual-machines.sh
    "$HOME/.config/zoomus.conf"                    # Zoom config
    "$HOME/.config/discord"                        # Discord config
    "$HOME/.config/libvirt"                        # libvirt client config
    "$HOME/.config/virt-manager"                   # virt-manager config

    # Add more paths as needed
)

# Flatpak apps sandbox their config under ~/.var/app/<app-id>/config instead
# of ~/.config -- derive those paths from FLATPAK_PACKAGES (packages.conf)
# rather than hand-maintaining a second copy of the app list that would drift
# out of sync. Only config/ is backed up, not data/ (caches and downloaded
# media, e.g. VueScan scans or Deezer/Telegram cache, live there and aren't
# worth preserving); back up a specific app's data/ as a manual static entry
# above if needed.
for flatpak_entry in "${FLATPAK_PACKAGES[@]}"; do
    software_configs+=("$HOME/.var/app/${flatpak_entry#*:}/config")
done
