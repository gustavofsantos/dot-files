# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow. Running `./setup.sh` is the only install step.

## Setup

```bash
./setup.sh          # links all files, merges Claude settings, installs the agent plugin
```

`setup.sh` delegates to seven scripts in `scripts/`:

| Script | What it does |
|--------|--------------|
| `link-home-files.sh` | Symlinks dotfiles (`.zshrc`, `.gitconfig`, etc.) into `$HOME` |
| `create-local-files.sh` | Touches `~/.gitconfig.local` and `~/.zshlocal` if missing |
| `init-engineering-repo.sh` | Idempotently `git init`s `~/engineering`, writes its `.gitignore`, seeds the first commit |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` (hook scripts live there too, prefixed `hooks-*`) |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-agents.sh` | Single source of truth for installing agent config: symlinks each `agents/plugins/<name>/` (skills, commands, agents, hooks, themes) into `~/.claude/skills/` and `~/.cursor/plugins/local/`; merges `.claude/settings.json` (`permissions`/`env`/`statusLine`/`theme`) into `~/.claude/settings.json` |
| `set-caps-lock-ctrl.sh` | Sets the GNOME "Caps Lock as Ctrl" `xkb-options` key (`ctrl:nocaps`) via `gsettings`, no `gnome-tweaks` package needed. No-ops if `gsettings` is absent. |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`, including hook scripts (`hooks-*`)
- `agents/` — `agents/plugins/` only: one self-contained plugin directory per project, holding everything that reaches Claude Code and Cursor — skills, slash commands, subagents, hooks, themes (see "Skills and plugins" below). This is the source of truth; nothing under `~/.claude/skills/` or `~/.cursor/plugins/local/` is hand-edited
- `test_bin/` — bats tests for `bin/` scripts, one `<script>.bats` per script
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`, `vale/`
- `.claude/` — hand-maintained Claude Code config, `settings.json` only: `permissions`/`env`/`statusLine`/`theme` selection, merged into the global `~/.claude/settings.json` on install

## Skills and plugins

Every skill lives inside a plugin, under `agents/plugins/<name>/skills/<skill>/` — a
`SKILL.md` plus optional `references/`, `scripts/`, and `assets/`. There is no loose
`agents/skills/` anymore: a plugin is the only unit a skill installs through.

A plugin directory is self-contained: its own `.claude-plugin/plugin.json` and
`.cursor-plugin/plugin.json`, plus `skills/`, `commands/`, `agents/`, `hooks/`, and
`themes/` subdirectories at the plugin root. `install-agents.sh` (run by `setup.sh`) is the
only install step for it: it symlinks the whole plugin directory into `~/.claude/skills/<name>`
(Claude Code's skills-directory plugin mechanism — auto-discovered next session as
`<name>@skills-dir`, no marketplace, no copy) and into `~/.cursor/plugins/local/<name>`
(Cursor's local-plugin path, read by both the desktop app and the `cursor-agent`/`agent`
CLI). Both are loaded in place, not copied, so editing a file under `agents/plugins/<name>/`
is the only step — `SKILL.md` edits apply live in Claude Code mid-session; edits to
`commands/`, `agents/`, `hooks/`, `themes/`, or a manifest need `/reload-plugins` there. The
CLI has no equivalent reload command, but needs none: every invocation is a fresh process,
so it re-reads the plugin directory from scratch each time.

A plugin's `commands/` directory holds flat markdown files, one per slash command:
`commands/<name>.md` becomes `/<name>` in both harnesses. Claude Code auto-discovers the
directory; Cursor is declared the same way its hooks are, with `"commands": "./commands/"`
in `.cursor-plugin/plugin.json`. A command is the explicit entry point a human types; a
skill is what the model reaches for on its own. When both exist for one workflow (`/review`
and the `review-queue` skill), the command stays short and the skill carries the rules —
neither is the store, the underlying script is.

There is no separate "rules" mechanism anymore — every rule (including the always-apply
`way-of-work`/`way-of-planning`/`way-of-communication` trio) is now a skill like any other,
converted with the same eager, trigger-rich description style. Trading a rule's guaranteed
always-on loading for a skill's model-decided invocation is a real trade-off, not a free
repackaging — see "Conventions skills follow" below.

Every component is hand-authored directly in each harness's own native plugin shape — there
is no compile step and nothing generates `agents/plugins/<name>/` from anywhere else. A
component Claude Code and Cursor represent identically ships as one shared file (`SKILL.md`
bodies — see "Every SKILL.md ships..." below). A component whose native shape genuinely
differs per harness ships as two files, one per harness, each written directly in that
harness's own format — hooks are the clearest case of this; see "Hooks" below.

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

Each plugin wires its own hooks directly, hand-authored, one file per harness:
`hooks/hooks.json` (Claude's own shape — `{hooks: {<PascalCase event>: [...]}}`) and
`hooks/cursor.hooks.json` (Cursor's own shape — `{version, hooks: {<camelCase event>:
[...]}}`). Claude Code auto-discovers `hooks/hooks.json` at the plugin root with no
manifest declaration needed. Cursor does not: a plugin's `.cursor-plugin/plugin.json`
must declare `"hooks": "./hooks/cursor.hooks.json"` explicitly, or Cursor never reads the
file — this tripped up the first attempt at wiring `hooks-vale-lint` for Cursor. There is
no compile step and nothing merges the two files together; they're independent and only
share the plugin's `hooks/` directory because that's the fixed Claude-side convention.

`.claude/settings.json` carries no `hooks` key of its own anymore — just `permissions`/
`env`/`statusLine`/`theme`. `install-agents.sh` merges those into the global
`~/.claude/settings.json` on install (global wins on scalar/object conflicts,
`permissions.allow/deny/ask` arrays are unioned) and leaves whatever `hooks` key is
already in the global file untouched — Claude Code loads plugin hooks independently of
`settings.json`, so this script has nothing to do with them.

`link-bin-files.sh` (part of `setup.sh`) symlinks every file in `bin/` into `~/.bin/`,
including the `hooks-*` scripts, so a hook is reachable by bare name from a plugin's
`hooks/*.json`. `tap-hook <hook> [args...]` still works as a debug-logging wrapper around
any hook command — it names its log file from the first argument (the hook), not the last,
so it composes with the `--harness`/`--event` flags that now follow the hook name.

Some hook scripts were already cross-harness before this convention existed and support
real `--harness cursor` input (`hooks-session-track`, `hooks-session-log`,
`hooks-engineering-autocommit`, `hooks-checks-snapshot`) — that's a fact about the script,
independent of whether anything currently wires it in. One real limitation surfaced along
the way, not introduced by it: Cursor's native `stop` payload (`{status, loop_count}`)
carries no session or cwd correlation, unlike Claude's Stop payload — so Cursor's turn-end
logging (`hooks-session-log`) and check snapshotting (`hooks-checks-snapshot`) would be
best-effort there even once wired.

`hooks-notify`, `hooks-gitbutler-stop`, `hooks-gitbutler-git`, `hooks-session-track`,
`hooks-session-log`, `hooks-engineering-autocommit`, and `hooks-checks-snapshot` all exist
under `bin/`, but none are currently wired into any plugin's `hooks/hooks.json` or
`hooks/cursor.hooks.json` — the only entry either file has today is `hooks-vale-lint`'s
`PostToolUse`/`postToolUse`. They're dormant scripts; wiring one back in means adding an
entry directly to the relevant plugin's hooks file. The plugin is the sole source of truth
for hook wiring now — there's no separate compile source to restore.

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. After every agent turn (Claude or Cursor) `hooks-checks-snapshot` fires, which (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status`; enrollment is manual — add a `path` + `checks` entry to `~/.checks.yml` by hand (see the commented example `create-local-files.sh` seeds in a fresh one). `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `hooks-checks-snapshot` | Turn-end hook (Claude and Cursor): version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks and of hooks, and spans both Claude Code and Cursor Agent. `claude-sessions` (`bind a` in tmux) discovers live agent sessions by **scanning tmux pane processes** — it walks each pane's process subtree looking for an agent CLI (`claude`, `cursor-agent`, aider, codex, …; the matched set is the `AGENTS` list at the top of the script) and lists every match in one fzf picker (a `cc`/`cu` tag distinguishes them). There is no state file and no hook to keep in sync: a session exists exactly while its process is alive, so the list can never go stale and needs no configuration — a bare `claude` or `cursor-agent` in any pane just shows up. Enter jumps straight to that pane (switch session → select window → select pane); the preview (`claude-session-preview`) is a live `tmux capture-pane` of the agent plus its location and cwd. `claude-sessions` still knows how to sort a pane first when its window name carries the `⊡` waiting prefix, but nothing sets that prefix today — `hooks-notify`, which used to set it on `Stop`/`Notification`, isn't currently wired into any plugin's hooks (see "Hooks" above), so every session currently shows as `active`. The `hooks-session-track` hook that remains exists to record `track_name` for checks correlation and to restore a bare window name for the `claude-run` flow.

## Review queue

`bin/review` is a per-workspace queue of code review comments, written where you read the
code and pulled by whatever agent you are running next door. It replaced the old
`agent-comments.lua` "write comments, flush a prompt, paste it into the agent" loop: there
is no flush and no clipboard hop anymore — a comment is queued the moment you write it, and
the agent takes it from the queue.

The queue is the single source of truth. `config/nvim/after/plugin/review.lua` keeps **no**
copy of it: it shells out to `review` for every read and acts on comments by id, so a
comment added from nvim, from a shell, or from another nvim instance shows up in all of
them. Signs are redrawn from `review list --format json --file <path>` (async, on
`BufEnter`/`BufWritePost`/`FocusGained`, or `:ReviewRefresh`).

| Piece | What it does |
|---|---|
| `review add` | Enqueue a comment on a file range, stamped with its lane and author. Code is snapshotted at add time — from disk, or from `--code-file -` when the editor holds unsaved changes (pipe the whole buffer, `--lines` slices it) |
| `review list` / `count` | Inspect the queue without dequeuing (`--file` scopes to one file — this is what draws the editor's signs; `--status pending\|pulled\|done\|rejected\|open\|all`; `--format text\|json\|ids\|count\|markdown`) |
| `review pull` | **Dequeue** and print, markdown by default. Pulled comments leave the queue, so no note is ever worked twice; `--peek` reads without draining, `--limit`/`--id` take a subset |
| `review resolve` / `reject` | Record what became of a comment and who decided. `reject` requires `--note` — a silent decline is the thing this prevents. A decided comment cannot be re-decided |
| `review show` / `edit` / `drop` / `clear` | Act on queued comments by id, or drop them in bulk |
| `review workspaces` / `path` | Where comments are waiting, and which file backs this workspace's queue |

A comment's life is `pending` → `pulled` → `done` | `rejected`; `open` selects everything
raised but not yet decided. `pull` says a comment was handed over, `resolve`/`reject` say
what became of it — that pair is the accountability record, and it is why `clear`/`drop`
(which delete with no decision) are forbidden to agents.

Workspace resolution: `--workspace PATH` (accepted before or after the subcommand), then
`$REVIEW_WORKSPACE`, then the git toplevel of `$PWD` (so each worktree is its own queue),
then `$PWD`.

**Lanes** divide a single workspace, because one working tree can carry several branches at
once (GitButler). A comment records its lane (`--lane NAME`, else `$REVIEW_LANE`) and a
pinned session sees only that lane. Scoping is deliberately **strict**: a pull pinned to a
lane never takes an unlaned comment or another lane's, since `pull` dequeues and a comment
swallowed by the wrong session is a comment lost. An empty pinned pull says on stderr how
many are waiting elsewhere, so nothing starves quietly; `--all-lanes` widens it, and an
unpinned session (the editor) sees everything. Authorship works the same way: `--author
WHO`, else `$REVIEW_AUTHOR` (what an agent sets), else `$USER` — so a comment from nvim is
attributed to you and one from a reviewing agent to it. The store is `$REVIEW_HOME` (default `~/.reviews`)`/<workspace-slug>/queue.json`,
one JSON file per workspace, written atomically under an `flock` so concurrent editors and
agents cannot lose a comment. Ids (`r1`, `r2`, …) are per-workspace and never reused. Pulled
comments stay in the file as a bounded archive (`list --status pulled`), which is why they
survive a `clear` of the pending queue.

Editor commands: `:ReviewAdd` (range-aware, `<CR>` in Visual mode), `:ReviewList`
(`<leader>co`), `:ReviewEdit` (`<leader>ce`), `:ReviewDelete` (`<leader>cd`), `:ReviewClear`
(`<leader>cx`), `:ReviewRefresh` (`<leader>cr`). `$REVIEW_CMD` overrides which binary the
plugin calls.

On the agent side there are two entry points over the same CLI, both in
`agents/plugins/gustavofsantos/`: the `/review` command (`commands/review.md`) when you want
to say "go work my comments", and the `review-queue` skill (`skills/review-queue/`) which the
model triggers on its own when you mention notes you left. Both drain the queue with
`review pull` and report back by id. Tests: `bats test_bin/review.bats`.

## GitButler provenance hooks

`bin/hooks-gitbutler-stop` and `bin/hooks-gitbutler-git` enforce GitButler-provenance-style commits in repos with a `.git/gitbutler/` dir: `hooks-gitbutler-stop` (`Stop`) blocks a turn from ending while the tree is dirty; `hooks-gitbutler-git` (`PreToolUse` on Bash) denies raw git write commands, requiring the `but` CLI for mutations. Neither is currently wired into any plugin's hooks (see "Hooks" above) — both are dormant scripts today.

## AI session token stats

`ai-stats` visualizes token spend across AI sessions as terminal bar charts, reading a tailored per-session store at `~/.agent-sessions/stats/<id>.json` that `ai-stats-import` derives from the original Claude Code transcripts (`~/.claude/projects/*/*.jsonl`). This store is separate from — and never touches — the hook-managed `<id>.json`/`<id>.jsonl` files.

Correctness is the point: a single assistant message is split across many JSONL lines that each repeat the same `usage`, so naive summing 3× overcounts. The importer dedupes by `message.id` (verified lossless: every line for an id reports identical usage, and ids never repeat across transcripts). Categories — input / output / cache-read / cache-write — are tracked separately because they aren't cost-equivalent; the default `io` metric (input+output) is the meaningful headline, with the full breakdown shown under each bar.

| Script | What it does |
|--------|--------------|
| `ai-stats-import` | Scan transcripts → per-model token aggregates in `~/.agent-sessions/stats/`. Idempotent rewrite; `--project NAME` to scope. |
| `ai-stats` | Terminal charts. Defaults: last `30d`, `--by model`, `--metric io`. Filters: `--since 7d\|2w\|all\|YYYY-MM-DD`, `--until`, `--project`, `--model`, `--by model\|session\|project`, `--metric io\|total\|input\|output\|cache_read\|cache_write`, `--top N`. |

Re-run `ai-stats-import` to refresh (live sessions whose transcript is still growing will show as stale until re-imported).

## Engineering vault auto-commit

`~/engineering` is meant to be a git repo whose changes are committed automatically after every agent turn, so the commit never depends on the agent remembering to do it. `hooks-engineering-autocommit` is designed as a `Stop`/`stop` hook for both Claude and Cursor — but per "Hooks" above, it's currently a dormant script, not wired into any plugin's `hooks/hooks.json` or `hooks/cursor.hooks.json`, so this auto-commit is **not currently running**. Once wired, it targets the **fixed** vault path (not the session cwd, since the vault is an additional working dir editable from any session): if the tree is dirty it `git add -A` + commits with a `vault: auto-commit N file(s) — <stamp>` message tagged with the harness and session id; if clean it no-ops fast. Concurrent turn-end hooks across sessions are serialised by an atomic `mkdir` lock under `.git/` (stale locks >60s reclaimed); a contender just bails, since the holder's commit or the next turn covers its changes.

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
| `VOCABULARY.md` | `vocabulary` skill | Canonical cross-project terms, aliases, usage, and relationships |
| `reconcile/` | `reconcile` skill | entities/bridges/invariants/breaks tables, org-wide across every repository |
| `facts/`, `.metadata/` | `facts-churn` | The facts base and its provenance mapping |

A brief lives at `projects/<slug>.md`, named by a bare slug because other files point at it as a key. An issue names its project in an optional `project:` frontmatter key, and `members.sh` derives the membership — the brief keeps no list, so nothing rots. An issue holds a delta; a brief holds system state. A campaign moves to `projects/done/` at the end; a domain the team owns never moves.

### A skill is code, never a store

A skill directory holds `SKILL.md`, `references/`, `scripts/`, and `assets/`. Nothing else. Whatever a skill learns goes to the vault. A skill that needs durable storage delegates to the skill that owns that section, rather than inventing a path. `outcome-builder` invokes `issue`. `ddd-survey` and `reflect` offer their findings to `project`. `test_bin/skills-storage.bats` fails if a skill stores its own output.

Ephemeral output stays out of the vault and goes to `/tmp` (`handoff`). Reconciliation is the
opposite: `reconcile` keeps both its knowledge tables and executable SQL under the org-wide
`reconcile/` vault directory, namespacing probes and traces by repository.
