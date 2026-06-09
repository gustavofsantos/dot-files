# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow. Running `./setup.sh` is the only install step.

## Setup

```bash
./setup.sh          # links all files, merges Claude settings, installs skills/agents
```

`setup.sh` delegates to five scripts in `scripts/`:

| Script | What it does |
|--------|--------------|
| `link-home-files.sh` | Symlinks dotfiles (`.zshrc`, `.gitconfig`, etc.) into `$HOME` |
| `create-local-files.sh` | Touches `~/.gitconfig.local` and `~/.zshlocal` if missing |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-skills.sh` | Symlinks Claude skills/agents/themes; merges `.claude/settings.json` into `~/.claude/settings.json` |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`
- `.claude/` — Claude Code config: `skills/`, `agents/`, `themes/`, `settings.json`, `sync-pipeline.py`

## Claude skills & agents

Skills live in `.claude/skills/<name>/` and agents in `.claude/agents/`. `install-skills.sh` symlinks them into `~/.claude/`. When adding a new skill, create the directory here and re-run `./setup.sh` (or just `./scripts/install-skills.sh`).

The `.claude/settings.json` merges into the global `~/.claude/settings.json` on install. Global settings win on scalar/object conflicts; `permissions.allow/deny/ask` arrays are unioned.

## Agent checks

A repo can carry a `.checks.yml` (root, committed) defining named checks — each a `name` + a `command`, modeled on the hooks shape. After every agent turn the `Stop` hook fires `checks-snapshot`, which hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status` (taught by the `checks` skill). `.checks.local.yml` (gitignored) overlays by name for machine-specific checks; worktrees inherit both via `git-add-worktree`.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-snapshot` | `Stop` hook: version changes, fire the runner (no-op if unchanged) |
| `checks-runner` | Run `.checks.yml` checks for a snapshot; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation (`claude-sessions`, `bind a` in tmux) lists running agent sessions with their last checks result, previews the live agent pane, and jumps straight to the pane running the agent.

## Neovim config

Entry point: `config/nvim/init.lua` → loads `config/options`, `pack`, `config/keymaps`, `config/autocmds`, `config/lazy`.

Plugin configs live in `config/nvim/lua/plugins/*.config.lua`. Leader is `<Space>`, local leader is `,`.

## Key environment variables (set in `.zshenv`)

| Variable | Purpose |
|----------|---------|
| `NOTES_HOME` | Daily notes dir |
| `JOURNALS_HOME` | Obsidian vault |
| `WORKLOG_PATH` | Obsidian worklog file |
| `HORSES_PATH` / `KNOWLEDGE_KB_PATH` | Horses knowledge-base engine |
| `PERSONAL_SESSIONS_DIR` | AI session artifacts (`~/engineering/.ai-sessions`) |

## Engineering knowledge base

See `.claude/CLAUDE.md` (already loaded as project instructions) for the `~/engineering/` KB retrieval protocol.
