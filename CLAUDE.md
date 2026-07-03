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
| `init-engineering-repo.sh` | Idempotently `git init`s `~/engineering`, writes its `.gitignore`, seeds the first commit |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-claude.sh` | Symlinks `.claude/` skills/agents/commands/themes/rules/workflows into `~/.claude/`; merges `.claude/settings.json` into `~/.claude/settings.json` |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`
- `.claude/` — Claude Code config: `skills/`, `themes/`, `rules/`, `workflows/`, `settings.json`

## Skills

Skills live under `.claude/skills/<name>/` — a `SKILL.md` plus optional `references/`
and `scripts/`. No plugins, no marketplace: `install-claude.sh` (run by `setup.sh`)
symlinks each skill directory into `~/.claude/skills/`, so edits in the working tree
take effect immediately (new/removed skills need a `./setup.sh` re-run to add/prune
symlinks).

Conventions the skills follow (keep them when editing):
- **Trigger is deliberate.** Skills the model should auto-load (format references like
  `bruno`, `clojure-datomic`; context-triggered workflows like `create-pull-request`)
  have rich trigger descriptions. Explicit-command skills set
  `disable-model-invocation: true` and keep the description to one line — it's only
  shown to the human.
- **Steps in `SKILL.md`, bulk reference behind pointers.** Branch-specific or
  phase-specific material lives in `references/*.md`, loaded only when that path runs
  (e.g. `bruno` detects the collection format and loads one of two format files).
- **No dead pointers.** A skill may only reference skills, scripts, and agents that
  exist in this repo.

Cursor reuses these same skills/agents by loading Claude's config directly (configured
outside this repo).

The `.claude/settings.json` merges into the global `~/.claude/settings.json` on install.
Global settings win on scalar/object conflicts; `permissions.allow/deny/ask` arrays are
unioned.

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. After every agent turn the `Stop` hook fires `checks-snapshot`, which (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status`; enrollment is managed by the `setup-checks` skill. `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks. `create-local-files.sh` seeds an empty `~/.checks.yml`.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `checks-snapshot` | `Stop` hook: version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks, and spans both Claude Code and Cursor Agent. A `SessionStart`/`UserPromptSubmit` hook (`claude-hook-session-track`) registers *every* Claude session — however launched — into `~/.agent-sessions/<id>.json` with the exact tmux pane it runs in; `SessionEnd` (`claude-hook-session-end`) marks it ended. Cursor can mirror this: the `cursor-hook-session-track`/`cursor-hook-session-end` scripts (kept in `bin/`, dispatched via `hooks-runner cursor <event>`) translate Cursor's `conversation_id`/`workspace_roots` into the *same* `~/.agent-sessions/<id>.json` schema (tagged `agent:"cursor"`), with `beforeSubmitPrompt` creating-if-missing so a session registers on its first prompt. The dotfiles no longer ship a `~/.cursor/hooks.json` to wire this — Cursor loads Claude's config instead, so wire those hooks there if you want Cursor sessions tracked. Each agent turn also appends structured events to `~/.agent-sessions/<id>.jsonl` via `claude-hook-session-log` (`turn_end`, `message`, `file_change`, `session_start`, `session_end`). `claude-sessions` (`bind a` in tmux) lists both tools in one picker (a `cc`/`cu` tag distinguishes them), keys liveness on whether that pane still exists, previews the session log (plus live pane), and Enter jumps straight to the pane running the agent. Works for a bare `claude` or `cursor-agent` in any pane.

## GitButler provenance hooks

Two hooks in `bin/`, wired via `.claude/settings.json` (merged into the global settings on install), enforce the `gitbutler-provenance` skill in repos with a `.git/gitbutler/` dir — and no-op instantly everywhere else. `claude-hook-gitbutler-stop` (`Stop`) blocks a turn from ending while the tree is dirty, at most once per turn (`stop_hook_active`), so a lane question can still reach the user. `claude-hook-gitbutler-git` (`PreToolUse` on Bash) denies raw git write commands (`commit`, `add`, `push`, `checkout`, `rebase`, …) — mutations must go through the `but` CLI; read-only git passes.

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

`~/engineering/` is the local KB vault (markdown + `[[wikilinks]]`). The `eng-search` skill defines the retrieval protocol; `issue`, `spike`, and `tidy-kb` manage its contents.
