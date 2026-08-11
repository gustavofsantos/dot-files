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
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` (hook scripts live there too, prefixed `hooks-*`) |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-agents.sh` | Single source of truth for installing agent config: compiles `agents/{agents,commands,hooks}` via its own embedded `agents-sync`/`hooks-sync` subcommands, symlinks each `agents/plugins/<name>/` into `~/.claude/skills/` and `~/.cursor/plugins/local/`, then symlinks agents/commands/themes/workflows into `~/.claude/` and hooks into `~/.cursor/`; merges `.claude/settings.json` into `~/.claude/settings.json` |
| `set-caps-lock-ctrl.sh` | Sets the GNOME "Caps Lock as Ctrl" `xkb-options` key (`ctrl:nocaps`) via `gsettings`, no `gnome-tweaks` package needed. No-ops if `gsettings` is absent. |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`, including hook scripts (`hooks-*`)
- `agents/` — harness-generic agent config: `agents/`, `commands/`, `hooks/`, `plugins/`. This is the source of truth; `.claude/` and `.cursor/` are compiled from it (see "Skills and plugins", "Hooks" below). `agents/hooks/` holds only the per-harness wiring config (`claude.settings.json`, `cursor.hooks.json`) — the hook scripts themselves live in `bin/`
- `test_bin/` — bats tests for `bin/` scripts, one `<script>.bats` per script
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`, `vale/`
- `.claude/` — compiled/hand-maintained Claude Code config: `themes/`, `agents/`, `commands/`, `workflows/`, `settings.json`

## Skills and plugins

Every skill lives inside a plugin, under `agents/plugins/<name>/skills/<skill>/` — a
`SKILL.md` plus optional `references/`, `scripts/`, and `assets/`. There is no loose
`agents/skills/` anymore: a plugin is the only unit a skill installs through.

A plugin directory is self-contained: its own `.claude-plugin/plugin.json` and
`.cursor-plugin/plugin.json`, plus `skills/`, `agents/`, and `commands/` subdirectories at
the plugin root. `install-agents.sh` (run by `setup.sh`) is the only install step for it:
it symlinks the whole plugin directory into `~/.claude/skills/<name>` (Claude Code's
skills-directory plugin mechanism — auto-discovered next session as `<name>@skills-dir`,
no marketplace, no copy) and into `~/.cursor/plugins/local/<name>` (Cursor's local-plugin
path, read by both the desktop app and the `cursor-agent`/`agent` CLI). Both are loaded in
place, not copied, so editing a file under `agents/plugins/<name>/` is the only step —
`SKILL.md` edits apply live in Claude Code mid-session; edits to `agents/`, `commands/`,
or a manifest need `/reload-plugins` there. The CLI has no equivalent reload command, but
needs none: every invocation is a fresh process, so it re-reads the plugin directory from
scratch each time.

There is no separate "rules" mechanism anymore — every rule (including the always-apply
`way-of-work`/`way-of-planning`/`way-of-communication` trio) is now a skill like any other,
converted with the same eager, trigger-rich description style. Trading a rule's guaranteed
always-on loading for a skill's model-decided invocation is a real trade-off, not a free
repackaging — see "Conventions skills follow" below. Hooks alone are not part of either
plugin format (Claude Code's plugin schema has no "rules" component either way, and
Cursor's plugin-hook support is unconfirmed), so they stay on `install-agents.sh`'s
`hooks-sync` compile pipeline — see "Hooks" below. A command not yet moved into a plugin
still goes through `agents-sync`'s Claude-only compile step.

An agent or command shipped inside a plugin uses the same frontmatter shape as
`agents-sync`'s compiled `.claude/agents/`/`.claude/commands/` *output* — flat keys, no
nested `claude:`/`cursor:` overlay block — since a plugin has no compile step of its own
to flatten one.

Conventions skills follow (keep them when editing):
- **Trigger is deliberate.** Skills the model should auto-load (format references like
  `bruno`, `clojure-datomic`; context-triggered workflows like `create-pull-request`)
  have rich trigger descriptions. The former always-apply rules (`way-of-work`,
  `way-of-planning`, `way-of-communication`) need the eagerest descriptions of all, since a
  skill has no guaranteed always-on loading the way a rule did — the description is the
  only thing standing between "always followed" and "silently skipped this time."
  Explicit-command skills set `disable-model-invocation: true` and keep the description to
  one line — it's only shown to the human.
- **Steps in `SKILL.md`, bulk reference behind pointers.** Branch-specific or
  phase-specific material lives in `references/*.md`, loaded only when that path runs
  (e.g. `bruno` detects the collection format and loads one of two format files).
- **No dead pointers.** A skill may only reference skills, scripts, and agents that
  exist in this repo.
- **Skill scripts test in place.** A script under a plugin's `skills/<name>/scripts/`
  keeps its bats tests beside it as `<script>_test.bats` — the skill directory stays
  self-contained, and the symlink into `~/.claude/skills/`/`~/.cursor/plugins/local/`
  carries the tests with it. `test_bin/` is only for `bin/` scripts, whose tests cannot
  travel with them.

Both test locations run under `bats` (`brew install bats-core`), and neither is
discovered by `listchangedtests`, which matches only `py|js|ts|clj`:

```bash
bats test_bin/                                              # all bin/ script tests
bats agents/plugins/gustavofsantos/skills/spike/scripts/new_test.bats    # one skill script
```

Every SKILL.md now ships to both harnesses byte-for-byte — there is no per-harness
frontmatter transform anymore. Claude's plugin skills accept the full frontmatter
(`disable-model-invocation`, `allowed-tools`, `context: fork`, …); Cursor's own documented
fields are narrower (`name`/`description`/`paths`/`disable-model-invocation`/`metadata`),
and it is not yet confirmed whether Cursor tolerates the extra Claude-only keys or trips
on them, so avoid the Claude-only keys on any skill you actually need working in Cursor
until that's verified. Keep bodies harness-agnostic regardless: don't name a specific
subagent (say "use a subagent to explore X" so each harness picks the agent that fits) or
a Claude-only tool.

Hooks still go through `install-agents.sh hooks-sync` to generate `.cursor/hooks.json`
from `agents/hooks/` — see "Hooks" below. A command not yet moved into a plugin still
goes through `agents-sync`'s Claude-only compile step, since Cursor has no subagent-tool
equivalent and Cursor command support wasn't built out this round.

## Hooks

Hook scripts live under `bin/`, prefixed `hooks-*` (e.g. `hooks-vale-lint`) — the prefix
is what marks a script as hook-wired rather than a general personal command; the harness
is still passed as an argument, not baked into the name. Every hook accepts `--harness
claude|cursor`, which selects how it reads stdin and, where applicable, what shape it
writes to stdout — Claude and Cursor have different native hook payloads and response
contracts, and a hook parses its harness's own shape directly, with no shared envelope or
translation layer in between. A hook with no Cursor implementation yet rejects `--harness
cursor` with a clear stderr message rather than silently no-op'ing. `bin/hooks-session-log`
additionally takes `--event <name>`, since a harness's payload doesn't self-identify its
event the same way.

Two harness-native config sources wire each hook to its event(s):
`agents/hooks/claude.settings.json` (just the `hooks` key, Claude's own shape) and
`agents/hooks/cursor.hooks.json` (the full native Cursor shape — `{version, hooks}`,
its own dedicated file, nothing else lives there); `agents/hooks/` holds only these two
wiring files now, not the scripts themselves. `install-agents.sh hooks-sync` compiles
them: it merges `claude.settings.json`'s `hooks` key into the real `.claude/settings.json`
(leaving `permissions`/`env` untouched, since those stay hand-maintained) and generates
`.cursor/hooks.json` wholesale from `cursor.hooks.json`.

That compiled `.claude/settings.json` then merges into the global `~/.claude/settings.json`
on install (`install-agents.sh`): global settings win on scalar/object conflicts,
`permissions.allow/deny/ask` and `hooks` arrays are unioned. `.cursor/hooks.json` installs
as a plain symlink — Cursor reads it directly, no merge step.

`install-agents.sh` is the single source of truth for installing agent config: `agents-sync`
and `hooks-sync` are subcommands it embeds directly (`install-agents.sh
agents-sync|hooks-sync [flags]`), not separate `bin/` scripts, so there is one script to
read to understand the whole compile-and-install pipeline. See the table under "Setup"
above for what the default (no-subcommand) invocation does end to end.

`link-bin-files.sh` (part of `setup.sh`) symlinks every file in `bin/` into `~/.bin/`,
including the `hooks-*` scripts, so a hook is reachable by bare name from generated
config. `tap-hook <hook> [args...]` still works as a debug-logging wrapper around any
hook command — it names its log file from the first argument (the hook), not the last,
so it composes with the `--harness`/`--event` flags that now follow the hook name.

Some hooks were already cross-harness before this convention existed (`hooks-session-track`,
`hooks-session-log`, `hooks-engineering-autocommit`, `hooks-checks-snapshot`) and port real
`--harness cursor` support forward. One real limitation surfaced along the way, not
introduced by it: Cursor's native `stop` payload (`{status, loop_count}`) carries no session
or cwd correlation, unlike Claude's Stop payload — so Cursor's turn-end logging
(`hooks-session-log`) and check snapshotting (`hooks-checks-snapshot`) are best-effort there
and commonly no-op, same as before.

`hooks-notify`, `hooks-gitbutler-stop`, `hooks-gitbutler-git`, and `hooks-session-log`'s
Claude wiring (`Stop`/`SubagentStart`/`SubagentStop`) were removed from
`claude.settings.json`; the scripts still exist under `bin/` but nothing currently invokes
them for Claude. `hooks-session-log` now only fires from Cursor's `stop` hook (`--event
turn_end`), so per-turn telemetry in `~/.agent-sessions/<id>.jsonl` covers Cursor sessions
only.

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. After every agent turn (Claude or Cursor) `hooks-checks-snapshot` fires, which (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status`; enrollment is manual — add a `path` + `checks` entry to `~/.checks.yml` by hand (see the commented example `create-local-files.sh` seeds in a fresh one). `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `hooks-checks-snapshot` | Turn-end hook (Claude and Cursor): version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks and of hooks, and spans both Claude Code and Cursor Agent. `claude-sessions` (`bind a` in tmux) discovers live agent sessions by **scanning tmux pane processes** — it walks each pane's process subtree looking for an agent CLI (`claude`, `cursor-agent`, aider, codex, …; the matched set is the `AGENTS` list at the top of the script) and lists every match in one fzf picker (a `cc`/`cu` tag distinguishes them). There is no state file and no hook to keep in sync: a session exists exactly while its process is alive, so the list can never go stale and needs no configuration — a bare `claude` or `cursor-agent` in any pane just shows up. Enter jumps straight to that pane (switch session → select window → select pane); the preview (`claude-session-preview`) is a live `tmux capture-pane` of the agent plus its location and cwd. `claude-sessions` still knows how to sort a pane first when its window name carries the `⊡` waiting prefix, but nothing sets that prefix today — the `hooks-notify` hook that used to set it on `Stop`/`Notification` was removed from `claude.settings.json` (see "Hooks" above), so every session currently shows as `active`. The `hooks-session-track` hook that remains exists to record `track_name` for checks correlation and to restore a bare window name for the `claude-run` flow.

## GitButler provenance hooks

`bin/hooks-gitbutler-stop` and `bin/hooks-gitbutler-git` enforce GitButler-provenance-style commits in repos with a `.git/gitbutler/` dir: `hooks-gitbutler-stop` (`Stop`) blocks a turn from ending while the tree is dirty; `hooks-gitbutler-git` (`PreToolUse` on Bash) denies raw git write commands, requiring the `but` CLI for mutations. Neither is currently wired in `claude.settings.json` — both were removed from the `Stop`/`PreToolUse` hooks (see "Hooks" above) and are dormant scripts today.

## AI session token stats

`ai-stats` visualizes token spend across AI sessions as terminal bar charts, reading a tailored per-session store at `~/.agent-sessions/stats/<id>.json` that `ai-stats-import` derives from the original Claude Code transcripts (`~/.claude/projects/*/*.jsonl`). This store is separate from — and never touches — the hook-managed `<id>.json`/`<id>.jsonl` files.

Correctness is the point: a single assistant message is split across many JSONL lines that each repeat the same `usage`, so naive summing 3× overcounts. The importer dedupes by `message.id` (verified lossless: every line for an id reports identical usage, and ids never repeat across transcripts). Categories — input / output / cache-read / cache-write — are tracked separately because they aren't cost-equivalent; the default `io` metric (input+output) is the meaningful headline, with the full breakdown shown under each bar.

| Script | What it does |
|--------|--------------|
| `ai-stats-import` | Scan transcripts → per-model token aggregates in `~/.agent-sessions/stats/`. Idempotent rewrite; `--project NAME` to scope. |
| `ai-stats` | Terminal charts. Defaults: last `30d`, `--by model`, `--metric io`. Filters: `--since 7d\|2w\|all\|YYYY-MM-DD`, `--until`, `--project`, `--model`, `--by model\|session\|project`, `--metric io\|total\|input\|output\|cache_read\|cache_write`, `--top N`. |

Re-run `ai-stats-import` to refresh (live sessions whose transcript is still growing will show as stale until re-imported).

## Engineering vault auto-commit

`~/engineering` is a git repo whose changes are committed automatically after every agent turn — the commit never depends on the agent remembering to do it. `hooks-engineering-autocommit` is a `Stop`/`stop` hook, wired for both Claude and Cursor via `agents/hooks/claude.settings.json` and `agents/hooks/cursor.hooks.json`. It targets the **fixed** vault path (not the session cwd, since the vault is an additional working dir editable from any session): if the tree is dirty it `git add -A` + commits with a `vault: auto-commit N file(s) — <stamp>` message tagged with the harness and session id; if clean it no-ops fast. Concurrent turn-end hooks across sessions are serialised by an atomic `mkdir` lock under `.git/` (stale locks >60s reclaimed); a contender just bails, since the holder's commit or the next turn covers its changes.

`init-engineering-repo.sh` (part of `setup.sh`) idempotently creates the repo, writes `.gitignore` (`.trash/`, Obsidian `workspace*.json`/`cache`, `.DS_Store`), and seeds the first commit. Commits stay local — nothing is pushed. There is no single per-machine override switch anymore (that was `~/.agent-hooks.local.yml`, retired with `hooks-runner`); pausing this on one machine means overriding the hook at the harness's own local-settings layer.

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

The vault is `$ENGINEERING_HOME` (`.zshenv`, default `~/engineering`) — the local KB vault (markdown + `[[wikilinks]]`). Every script and skill that touches it resolves `${ENGINEERING_HOME:-$HOME/engineering}`. Nothing hardcodes the path. `bin/facts-churn` reads the same variable (it used to read a second name, `ENGINEERING_DIR`).

| Section | Owner | Holds |
|---|---|---|
| `issues/` | `issue` skill | Tracked work items, one delta each |
| `artifacts/` | `issue` skill | Raw material: notes, transcripts, data, diagrams, DDD surveys, hypothesis verdicts |
| `spikes/` | `spike` skill | Answered unknowns |
| `projects/` | `project` skill | One brief per project: glossary, topology, data map, standing questions |
| `reconcile/` | `reconcile` skill | entities/bridges/invariants/breaks tables, org-wide across every repository |
| `facts/`, `.metadata/` | `facts-churn` | The facts base and its provenance mapping |

A brief lives at `projects/<slug>.md`, named by a bare slug because other files point at it as a key. An issue names its project in an optional `project:` frontmatter key, and `members.sh` derives the membership — the brief keeps no list, so nothing rots. An issue holds a delta; a brief holds system state. A campaign moves to `projects/done/` at the end; a domain the team owns never moves.

### A skill is code, never a store

A skill directory holds `SKILL.md`, `references/`, `scripts/`, and `assets/`. Nothing else. Whatever a skill learns goes to the vault. A skill that needs durable storage delegates to the skill that owns that section, rather than inventing a path. `outcome-builder` invokes `issue`. `ddd-survey` and `reflect` offer their findings to `project`. `test_bin/skills-storage.bats` fails if a skill stores its own output.

Two kinds of output stay out of the vault on purpose. Ephemeral output goes to `/tmp` (`handoff`). Executable assertions stay beside the code they assert against: `reconcile` keeps `model/probes/*.sql` and `model/traces/*.sql` in the repository, while its knowledge tables move to the vault.
