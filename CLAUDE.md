# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow. Running `./setup.sh` is the only install step.

## Setup

```bash
./setup.sh          # links all files, merges Claude settings, installs skills/agents
```

`setup.sh` delegates to six scripts in `scripts/`:

| Script | What it does |
|--------|--------------|
| `link-home-files.sh` | Symlinks dotfiles (`.zshrc`, `.gitconfig`, etc.) into `$HOME` |
| `create-local-files.sh` | Touches `~/.gitconfig.local` and `~/.zshlocal` if missing |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-skills.sh` | Symlinks Claude skills/agents/themes; merges `.claude/settings.json` into `~/.claude/settings.json` |
| `install-cursor.sh` | Merges `.cursor/hooks.json` (session-tracking hooks) into `~/.cursor/hooks.json`, absolute-pathed |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`
- `.claude/` — Claude Code config: `skills/`, `agents/`, `themes/`, `settings.json`, `sync-pipeline.py`
- `.cursor/` — Cursor Agent config: `hooks.json` (session-tracking hooks merged into `~/.cursor/hooks.json`)

## Claude skills & agents

Skills live in `.claude/skills/<name>/` and agents in `.claude/agents/`. `install-skills.sh` symlinks them into `~/.claude/`. When adding a new skill, create the directory here and re-run `./setup.sh` (or just `./scripts/install-skills.sh`).

The `.claude/settings.json` merges into the global `~/.claude/settings.json` on install. Global settings win on scalar/object conflicts; `permissions.allow/deny/ask` arrays are unioned.

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. After every agent turn the `Stop` hook fires `checks-snapshot`, which (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status` (taught by the `checks` skill). `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks. `create-local-files.sh` seeds an empty `~/.checks.yml`.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `checks-snapshot` | `Stop` hook: version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks, and spans both Claude Code and Cursor Agent. A `SessionStart`/`UserPromptSubmit` hook (`claude-hook-session-track`) registers *every* Claude session — however launched — into `~/.agent-sessions/<id>.json` with the exact tmux pane it runs in; `SessionEnd` (`claude-hook-session-end`) marks it ended. Cursor mirrors this: `~/.cursor/hooks.json` wires `sessionStart`/`beforeSubmitPrompt` → `cursor-hook-session-track` and `sessionEnd` → `cursor-hook-session-end`, which translate Cursor's `conversation_id`/`workspace_roots` into the *same* `~/.agent-sessions/<id>.json` schema (tagged `agent:"cursor"`). `beforeSubmitPrompt` creates-if-missing, so a session registers on its first prompt even if `sessionStart` is a no-op. Each agent turn also appends structured events to `~/.agent-sessions/<id>.jsonl` via `claude-hook-session-log` (`turn_end`, `message`, `file_change`, `session_start`, `session_end`). `claude-sessions` (`bind a` in tmux) lists both tools in one picker (a `cc`/`cu` tag distinguishes them), keys liveness on whether that pane still exists, previews the session log (plus live pane), and Enter jumps straight to the pane running the agent. Works for a bare `claude` or `cursor-agent` in any pane.

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
