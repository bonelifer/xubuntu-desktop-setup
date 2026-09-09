# Completed TODOs archive 1

## Manual installs

*Completed: 09/09/2026*

Claude Desktop, ChatGPT Desktop, and the Claude Code CLI had config
backup/restore wired up via `backup-restore-configs_paths.sh` but no
`install-*.sh` module, so they had to be installed by hand after a
reinstall.

Resolved by adding `install-claude-desktop.sh`, `install-chatgpt.sh`, and
`install-claude-code.sh` (all three registered in `packages.conf`'s
`CORE_MODULES`), using each app's official install method:

- **Claude Desktop** — Anthropic's own apt repo/key
  (`downloads.claude.ai/claude-desktop/apt/stable`)
- **ChatGPT Desktop** — official `.deb` download, which self-configures
  OpenAI's apt repo (`persistent.oaistatic.com/codex-app-prod/linux/deb`)
- **Claude Code CLI** — Anthropic's official installer script
  (`curl -fsSL https://claude.ai/install.sh | bash`), a plain user-level
  install with no apt repo involved
