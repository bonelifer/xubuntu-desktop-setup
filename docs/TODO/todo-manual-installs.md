# Manual installs

Apps whose config is already covered by `backup-restore-configs_paths.sh`, but
that aren't wired into `packages.conf` / `install-main.sh` yet. Install these
by hand after a reinstall until each gets a proper `install-*.sh` module.

## Claude Desktop

- Download: <https://claude.ai/download> (Linux `.deb`, x64 or arm64)
- Config backed up/restored via `$HOME/.config/Claude`
- The `.deb` adds its own apt repo (`downloads.claude.ai/claude-desktop/apt/stable`)
  and keyring, so `apt upgrade` picks up new versions automatically afterward
- Future: script as `install-claude-desktop.sh`, same pattern as
  `install-webmin.sh` (official installer script / own apt repo)

## ChatGPT Desktop

- Download: <https://chatgpt.com/download> (Linux `.deb`)
- Config backed up/restored via `$HOME/.config/ChatGPT` and
  `$HOME/.config/Codex` (see `backup-restore-configs_paths.sh` for why both
  are listed)
- The installed package is named `chatgpt`, but it's OpenAI's Codex desktop
  app rebranded -- the download page says "Existing Codex app users can
  update to ChatGPT and open Codex"
- The `.deb` adds its own apt repo (`persistent.oaistatic.com/codex-app-prod/linux/deb`)
  and keyring, so `apt upgrade` picks up new versions automatically afterward
- Future: script as `install-chatgpt.sh`

## Claude Code (CLI)

- Install: `curl -fsSL https://claude.ai/install.sh | bash`
- Docs: <https://code.claude.com/docs/en/terminal-guide>
- Installs to `$HOME/.local/bin/claude` and auto-updates itself in the
  background -- no apt repo involved
- Config backed up/restored via `$HOME/.claude` and `$HOME/.claude.json`
- Future: could be scripted as `install-claude-code.sh` (a plain `curl | bash`,
  no packages.conf entry needed)
