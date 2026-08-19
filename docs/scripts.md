# Script reference

One-line description of every script in the repo. Descriptions are pulled from each script's own header comment — if a script's behavior changes, update the header there rather than here.

## Orchestrators

| Script | What it does |
|--------|---------------|
| `install-main.sh` | Orchestrates full system setup: repos/PPAs, packages from `packages.conf`, core `install-*.sh` modules, and optional `--with-<name>` modules |
| `perform_backup.sh` | Runs every `backup-restore-*.sh` script in `--backup` mode |
| `perform_restore.sh` | Runs every restore-capable `backup-restore-*.sh` script in restore mode |

## Install scripts

| Script | What it does |
|--------|---------------|
| `install-add-sudoers-no-password.sh` | Adds the current user to sudoers for password-less `sudo` |
| `install-adjust-important-folders.sh` | Updates `user-dirs.dirs` to configure default XDG user directories |
| `install-and-activate-filebot-license.sh` | Activates a FileBot license using a provided license file |
| `install-angryipscanner.sh` | Downloads and installs the latest Angry IP Scanner `.deb` release |
| `install-apart-gtk.sh` | Downloads and installs the apart-gtk package from a GitHub release |
| `install-applauncher.sh` | Installs AppImageLauncher via its PPA |
| `install-apt-select-mirror.sh` | Automates selecting and updating the fastest apt mirror |
| `install-atuin.sh` | Installs Atuin (shell history sync/search) via its official installer |
| `install-communications.sh` | Installs Zoom and Discord via direct `.deb` download |
| `install-docker.sh` | Installs Docker CE on Ubuntu 22.04 |
| `install-drill-search.sh` | Installs and integrates the Drill Search AppImage with AppImageLauncher |
| `install-firefox.sh` | Switches Firefox from the Ubuntu snap to Mozilla's official apt package |
| `install-git-credential-manager.sh` | Installs Git Credential Manager on Linux |
| `install-git.sh` | Configures Git identity and installs GitHub Desktop |
| `install-mergerfs.sh` | Downloads and installs mergerfs from GitHub |
| `install-mouse-pointer-settings.sh` | Manages dconf mouse/pointer settings for a ThinkPad laptop (dump/load) |
| `install-starship.sh` | Installs the Starship terminal prompt for Bash |
| `install-trashy.sh` | Builds and installs the trashy project (safe `rm` replacement) |
| `install-tweaks.sh` | Installs ThinkPad system tweaks (screensaver, TLP, fstrim, touchpad, swap) |
| `install-usb-audio-select.sh` | Automatically selects USB sound devices (third-party script, © Stephen Ostermiller) |
| `install-vboxmanage-nopasswd.sh` | Grants passwordless sudo for `/usr/bin/vboxmanage` |
| `install-vcron.sh` | Installs Zeit CRONTAB (vcron) |
| `install-virtual-machines.sh` | Installs and configures virtualization tools (QEMU, etc.) |
| `install-webmin.sh` | Installs Webmin via its official installer script |
| `install-winehq.sh` | Installs WineHQ and Winetricks |
| `install-yppa-manager.sh` | Installs Y-PPA-Manager via its apt repository |
| `install-zulu-jdk.sh` | Installs Zulu JDK (current LTS) on Ubuntu |

## Uninstall scripts

| Script | What it does |
|--------|---------------|
| `uninstall-zulu-jdk.sh` | Keeps only the latest LTS Zulu JDK, installing it if missing and purging all other installed versions |

## Backup / restore scripts

| Script | What it does |
|--------|---------------|
| `backup-crontab.sh` | Backs up user and system crontab entries (backup-only, not auto-restored) |
| `backup-fstab.sh` | Backs up `/etc/fstab` (backup-only, not auto-restored) |
| `backup-restore-autostart.sh` | Backs up/restores user and system autostart configurations |
| `backup-restore-configs-manager.sh` | Generic backup/restore engine, driven by `backup-restore-configs_paths.sh` |
| `backup-restore-configs_paths.sh` | Manifest of config file/directory paths for the generic backup/restore engine |
| `backup-restore-fonts.sh` | Backs up/restores hand-installed font files |
| `backup-restore-keepassxc.sh` | Backs up/restores the last-opened KeePassXC database |
| `backup-restore-plank.sh` | Dumps/restores Plank dock settings via dconf |
| `backup-restore-trackpoint_touchpad_sensitivity.sh` | Dumps/restores touchpad, TrackPoint, and mouse peripheral settings via dconf |
| `backup-wifi.sh` | Backs up saved WiFi network names and PSKs from NetworkManager (backup-only, not auto-restored) |

## Theme scripts

| Script | What it does |
|--------|---------------|
| `detect-theme.sh` | Detects the current Xfce theme/style and saves a snapshot |
| `apply-theme.sh` | Replays a theme snapshot produced by `detect-theme.sh` |

## Inventory & sync

| Script | What it does |
|--------|---------------|
| `package_inventory.sh` | Lists installed apt/snap/flatpak/pip/npm packages, filtered to user-installed ones |
| `sync-backup.sh` | Syncs an array of directories from a source drive to a destination drive via rsync |

## Shared library

| Script | What it does |
|--------|---------------|
| `lib/common.sh` | Shared logging/error-handling helpers, sourced by other scripts |

## contrib/

| Script | What it does |
|--------|---------------|
| `contrib/filelist.sh` | Lists repo-root directories and backup/restore-named files |
| `contrib/other-file-list.sh` | Lists repo-root directories and non-backup/restore-named files |
| `contrib/output.sh` | Lists repo-root directories and files, unfiltered |
