# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow. Running `./setup.sh` is the only install step.

## Setup

```bash
./setup.sh          # links all files, merges Claude settings, installs skills/agents
```

`setup.sh` delegates to seven scripts in `scripts/`:

| Script | What it does |
|--------|--------------|
| `link-home-files.sh` | Symlinks dotfiles (`.zshrc`, `.gitconfig`, etc.) into `$HOME` |
| `create-local-files.sh` | Touches `~/.gitconfig.local` and `~/.zshlocal` if missing |
| `init-engineering-repo.sh` | Idempotently `git init`s `~/engineering`, writes its `.gitignore`, seeds the first commit |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-claude.sh` | Registers the `personal` plugin marketplace and installs the four plugins for Claude Code; links agents/commands/themes/rules/workflows; merges `.claude/settings.json` into `~/.claude/settings.json` |
| `install-cursor.sh` | Symlinks the four plugins into `~/.cursor/plugins/local/`; merges `.cursor/hooks.json` (session-tracking hooks) into `~/.cursor/hooks.json`, absolute-pathed |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`
- `agents/plugins/` — the four personal plugins (`bruno`, `clojure`, `engineering`, `productivity`), each bundling its skills/hooks/rules. Shared by Claude Code and Cursor.
- `.claude/` — Claude Code config: `commands/`, `themes/`, `rules/`, `workflows/`, `settings.json`, `sync-pipeline.py`
- `.cursor/` — Cursor Agent config: `hooks.json` (session-tracking hooks merged into `~/.cursor/hooks.json`)

## Plugins (skills, hooks, rules)

Skills no longer live under `.claude/skills/`. They ship as **plugins** under
`agents/plugins/<name>/`, grouped into four: `bruno`, `clojure`, `engineering`,
`productivity`. Each plugin is a directory with `.claude-plugin/plugin.json` (Claude) and
`.cursor-plugin/plugin.json` (Cursor) plus auto-discovered `skills/`, `hooks/`, `rules/`,
`scripts/`. The two marketplace manifests — `agents/plugins/.claude-plugin/marketplace.json`
and `agents/plugins/.cursor-plugin/marketplace.json` — list all four under a marketplace
named `personal`.

Install (run by `setup.sh`):
- **Claude Code** — `install-claude.sh` runs `claude plugin marketplace add agents/plugins`
  then `claude plugin install <name>@personal` for each. Claude **copies** the plugin into
  `~/.claude/plugins/cache/personal/<name>/<version>/` from the repo's committed HEAD (not
  the working tree). After **committing** a skill change, run
  `claude plugin update <name>@personal` (or re-run `setup.sh`) for it to take effect —
  uncommitted edits are **not** loaded.
- **Cursor** — `install-cursor.sh` symlinks each plugin into `~/.cursor/plugins/local/<name>`.
  Edits are live; reload Cursor to pick them up.

Skills are namespaced once installed: `/engineering:checks`, `/productivity:issue`, etc.

When adding a new skill, drop it under the right plugin's `skills/` dir and re-run
`./setup.sh`. When adding a whole new plugin, also add it to both `marketplace.json` files
and the `PLUGINS` list in `install-claude.sh`.

The `.claude/settings.json` merges into the global `~/.claude/settings.json` on install.
Global settings win on scalar/object conflicts; `permissions.allow/deny/ask` arrays are
unioned.

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

## AI session token stats

`ai-stats` visualizes token spend across AI sessions as terminal bar charts, reading a tailored per-session store at `~/.agent-sessions/stats/<id>.json` that `ai-stats-import` derives from the original Claude Code transcripts (`~/.claude/projects/*/*.jsonl`). This store is separate from — and never touches — the hook-managed `<id>.json`/`<id>.jsonl` files.

Correctness is the point: a single assistant message is split across many JSONL lines that each repeat the same `usage`, so naive summing 3× overcounts. The importer dedupes by `message.id` (verified lossless: every line for an id reports identical usage, and ids never repeat across transcripts). Categories — input / output / cache-read / cache-write — are tracked separately because they aren't cost-equivalent; the default `io` metric (input+output) is the meaningful headline, with the full breakdown shown under each bar.

| Script | What it does |
|--------|--------------|
| `ai-stats-import` | Scan transcripts → per-model token aggregates in `~/.agent-sessions/stats/`. Idempotent rewrite; `--project NAME` to scope. |
| `ai-stats` | Terminal charts. Defaults: last `30d`, `--by model`, `--metric io`. Filters: `--since 7d\|2w\|all\|YYYY-MM-DD`, `--until`, `--project`, `--model`, `--by model\|session\|project`, `--metric io\|total\|input\|output\|cache_read\|cache_write`, `--top N`. |

Re-run `ai-stats-import` to refresh (live sessions whose transcript is still growing will show as stale until re-imported).

## Engineering vault auto-commit

`~/engineering` is a git repo whose changes are committed automatically after every agent turn — the commit never depends on the agent remembering to do it. `engineering-autocommit` is a `turn_end` hook (registered in `~/.agent-hooks.yml`, run by `hooks-runner` for both Claude and Cursor). It targets the **fixed** vault path (not the session cwd, since the vault is an additional working dir editable from any session): if the tree is dirty it `git add -A` + commits with a `vault: auto-commit N file(s) — <stamp>` message tagged with the harness and session id; if clean it no-ops fast. Concurrent turn-end hooks across sessions are serialised by an atomic `mkdir` lock under `.git/` (stale locks >60s reclaimed); a contender just bails, since the holder's commit or the next turn covers its changes.

`init-engineering-repo.sh` (part of `setup.sh`) idempotently creates the repo, writes `.gitignore` (`.trash/`, Obsidian `workspace*.json`/`cache`, `.DS_Store`), and seeds the first commit. Commits stay local — nothing is pushed. To pause auto-commit on a machine, disable the hook via `~/.agent-hooks.local.yml` (`- name: engineering-autocommit` / `enabled: false`).

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
