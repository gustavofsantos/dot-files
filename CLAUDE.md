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

See `.claude/CLAUDE.md` (already loaded as project instructions) for the `~/engineering/` KB retrieval protocol — `kb-index`, `kb-search`, `kb-peek`.
