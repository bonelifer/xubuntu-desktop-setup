# xubuntu-desktop-setup

Personal provisioning toolkit for a Xubuntu/XFCE desktop: install software, then back up and restore configuration around a reinstall.

## Requirements

- Xubuntu/Ubuntu (tested on 22.04)
- `bash`, `sudo`

## Install

```bash
./install-main.sh                      # core modules only
./install-main.sh --with-webmin        # core + one optional module
./install-main.sh --with-webmin --with-mergerfs
```

`install-main.sh` is a thin orchestrator — it installs packages/PPAs/snaps/flatpaks from `packages.conf`, then runs each core `install-*.sh` module. Optional modules (hardware-specific, security-sensitive, or dependent on external files) only run when explicitly requested:

| Flag | Script | What it does |
|------|--------|---------------|
| `--with-webmin` | `install-webmin.sh` | Installs Webmin via its official installer script (own apt repo/key) |
| `--with-mergerfs` | `install-mergerfs.sh` | Downloads and installs mergerfs from GitHub |
| `--with-sudoers-nopasswd` | `install-add-sudoers-no-password.sh` | Adds the current user to sudoers for password-less `sudo` |
| `--with-vboxmanage-nopasswd` | `install-vboxmanage-nopasswd.sh` | Grants the sudo group passwordless sudo for `vboxmanage`, so VirtualBox VMs can be managed without a password prompt |
| `--with-xdg-user-dirs` | `install-adjust-important-folders.sh` | Configures default XDG user directories (`user-dirs.dirs`) |
| `--with-filebot-license` | `install-and-activate-filebot-license.sh` | Activates a FileBot license from a provided license file |
| `--with-apt-mirror` | `install-apt-select-mirror.sh` | Selects and configures the fastest US apt mirror via `apt-select` |

## Backup / restore

```bash
./perform_backup.sh     # back up everything, before a reinstall
./perform_restore.sh    # restore everything, on the new install
```

Most application config is backed up generically via `backup-restore-configs-manager.sh`, driven by the path list in `backup-restore-configs_paths.sh` — add a new app there instead of writing a dedicated script. A handful of scripts stay standalone because they need real logic (dconf dumps, gsettings, a dynamically-resolved path, or a live command's output instead of a file) — see the header comments in `perform_backup.sh` and `perform_restore.sh` for the current list.

`backup-crontab.sh` and `backup-fstab.sh` are backup-only by design: restoring an old crontab or fstab over a live one risks silently reverting changes made since the backup, so those are left to manual review rather than automatic restore.

## Configuration

`packages.conf` is the single source of truth for what gets installed — apt packages, PPAs, snaps, flatpaks, and the core/optional module lists. Add a new package there instead of editing `install-main.sh` directly.

## Structure

- `install-*.sh` — one script per app/tool, called by `install-main.sh`
- `backup-restore-*.sh` — per-app backup/restore logic (standalone cases only)
- `lib/common.sh` — shared logging/error-handling helpers
- `contrib/` — small utility scripts (repo file listings), not part of install/backup
- `backup/` — generated backup output (gitignored, kept via `.gitkeep`)

See [docs/scripts.md](docs/scripts.md) for a one-line description of every script in the repo.

## Acknowledgments

- Code review, bug fixes, and documentation assisted by [Claude](https://www.anthropic.com/claude).

## Contributing

Contributions are welcome!

- **Bug reports**: [Open an issue](https://github.com/bonelifer/xubuntu-desktop-setup/issues).
- **Everything else** (questions, feature requests, ideas, general discussion): [Use Discussions](https://github.com/bonelifer/xubuntu-desktop-setup/discussions).
- Pull requests are welcome for bug fixes or discussed features.

## License

This project is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for more information.
