# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow. Running `./setup.sh` is the only install step.

## Setup

```bash
./setup.sh          # links all files, installs skills, merges Claude settings and Codex hooks
```

`setup.sh` delegates to seven scripts in `scripts/`:

| Script | What it does |
|--------|--------------|
| `link-home-files.sh` | Symlinks dotfiles (`.zshrc`, `.gitconfig`, etc.) into `$HOME` |
| `create-local-files.sh` | Touches `~/.gitconfig.local` and `~/.zshlocal` if missing |
| `init-engineering-repo.sh` | Idempotently `git init`s `~/engineering`, writes its `.gitignore`, seeds the first commit |
| `link-bin-files.sh` | Symlinks every file in `bin/` into `~/.bin/` (hook scripts live there too, prefixed `hooks-*`) |
| `link-xdg-config.sh` | Symlinks each subdir of `config/` into `~/.config/` |
| `install-agents.sh` | Symlinks each `.agents/skills/<name>/` into `~/.agents/skills/` and from there into `~/.claude/skills/`, prunes links whose source is gone, merges `.codex/hooks.json` into `$CODEX_HOME/hooks.json`, and merges `.claude/settings.json` into `~/.claude/settings.json` |
| `set-caps-lock-ctrl.sh` | Sets the GNOME "Caps Lock as Ctrl" `xkb-options` key (`ctrl:nocaps`) via `gsettings`, no `gnome-tweaks` package needed. No-ops if `gsettings` is absent. |

Re-running `setup.sh` is idempotent (`ln -sf`).

## Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and any machine-specific git config
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets

## Directory layout

- `bin/` — personal scripts added to `$PATH` via `~/.bin/`, including hook scripts (`hooks-*`)
- `.agents/skills/` — every skill, one directory each, installed by `install-agents.sh`. This is the source of truth; nothing under `~/.agents/skills/` or `~/.claude/skills/` that links here is hand-edited
- `.agents/agents/` — subagent definitions (`maintainability-reviewer.md`). Nothing installs them yet
- `test_bin/` — bats tests for `bin/` scripts, one `<script>.bats` per script
- `config/` — XDG config dirs: `nvim/`, `ghostty/`, `bat/`, `lazygit/`, `mise/`, `zed/`, `wezterm/`, `tmux/`, `sheldon/`, `starship.toml`, `vale/`
- `.claude/` — hand-maintained Claude Code config, `settings.json` only (`permissions`/`env`/`statusLine`/`theme`/`defaultMode`/`teammateMode`), merged into the global `~/.claude/settings.json` on install
- `.codex/` — `hooks.json`, merged into Codex's global hooks file on install

## Skills

Skills live flat under `.agents/skills/<skill>/` — a `SKILL.md` plus optional `references/`,
`scripts/`, and `assets/`. `install-agents.sh` links each one into `~/.agents/skills/<skill>`
and links that into `~/.claude/skills/<skill>`. Cursor reads `~/.claude/skills/` too, so one
directory serves both harnesses. The links are live: editing a `SKILL.md` here applies in
the next session with no install step. Re-run `setup.sh` only to add or remove a skill.

`~/.claude/skills/` also holds real directories that are not in this repo — the private
`domain-*` skills written by `domain-skill-creator`. Only symlinks there belong to this repo.

There is no separate rules mechanism. Focused steering and workflow profiles are skills.
The `rules-of-*` and `way-of-*` families stay model-invocable on purpose, so their
descriptions must name a narrow, focused effect. The `smelly-*` family and
`rules-of-legacy-code` are manual profiles with `disable-model-invocation: true`. Scenario
skills can activate when a request matches their narrow boundary. Review, end-gate, and
batch skills (such as `reflect`) remain explicit when automatic use could take over another
task.

Conventions skills follow (keep them when editing):
- **Trigger is deliberate.** Automatically selected skills have a narrow scenario boundary.
  Manual profiles and explicit review or mutation gates set
  `disable-model-invocation: true`. Their descriptions explain the focused effect to the
  human who selects them and do not contain eager triggers.
- **Steps in `SKILL.md`, bulk reference behind pointers.** Branch-specific or
  phase-specific material lives in `references/*.md`, loaded only when that path runs
  (e.g. `reflect` loads `references/backlog.md` only for the backlog scope).
- **No dead pointers.** A skill may only reference skills, scripts, and agents that
  exist in this repo.
- **Skill scripts test in place.** A script under `.agents/skills/<name>/scripts/` keeps its
  bats tests beside it as `<script>_test.bats`, so the skill directory stays
  self-contained. `test_bin/` is only for `bin/` scripts.
- **Harness-agnostic bodies.** Claude Code and Cursor read the same `SKILL.md`. Don't name
  a specific subagent (say "use a subagent to explore X") or a Claude-only tool. Cursor's
  documented frontmatter is `name`/`description`/`paths`/`disable-model-invocation`/`metadata`;
  avoid Claude-only keys (`allowed-tools`, `context: fork`, …) on a skill that must work in
  Cursor, since it is unverified whether Cursor tolerates them.

Both test locations run under `bats`, and neither is discovered by `listchangedtests`,
which matches only `py|js|ts|clj`:

```bash
bats test_bin/                                              # all bin/ script tests
bats .agents/skills/reflect/scripts/sessions_test.bats      # one skill script
```

### Reflect state

`reflect` in backlog scope reads Claude (`~/.claude/projects/*/*.jsonl`) and Cursor
(`~/.cursor/projects/*/agent-transcripts/*/*.jsonl`) transcripts. It tracks what it has
analyzed as a set in `${XDG_STATE_HOME:-~/.local/state}/reflect/analyzed.tsv`
(`harness<TAB>session-id<TAB>lines`). Pending means "on disk and not in the set, or grown
since it was recorded". The file is machine-local state, never committed; `sessions.sh seed`
marks everything on disk as analyzed.

## Hooks

Hook scripts live under `bin/`, prefixed `hooks-*` (e.g. `hooks-vale-lint`) — the prefix
marks a script as hook-wired rather than a general personal command. The harness is passed
as an argument, not baked into the name. Each hook validates the harnesses it supports and
parses that harness's native stdin and response contract directly, with no shared envelope.
`bin/hooks-session-log` additionally takes `--event <name>`, since a harness's payload
doesn't self-identify its event.

Only Codex has hooks wired today. `.codex/hooks.json` wires `hooks-vale-lint --harness codex`
to `PostToolUse` for `apply_patch`/`Edit`/`Write`; `install-agents.sh` merges it into
`$CODEX_HOME/hooks.json` (normally `~/.codex/hooks.json`), replacing only its own prior
entry. The script extracts every Markdown path from Codex's apply-patch payload and returns
Vale feedback through `hookSpecificOutput.additionalContext`.

Claude Code and Cursor have no hook wiring in this repo since the `gustavofsantos` plugin
was removed (`5e55372`). `.claude/settings.json` carries no `hooks` key, and
`install-agents.sh` leaves any `hooks` key already in the global `~/.claude/settings.json`
untouched. Wiring a hook for Claude means adding it to `.claude/settings.json` (or the
global file); for Cursor, to `~/.cursor/hooks.json`.

Every other hook script is dormant: `hooks-notify`, `hooks-gitbutler-stop`,
`hooks-gitbutler-git`, `hooks-session-track`, `hooks-session-log`,
`hooks-engineering-autocommit`, `hooks-checks-snapshot`, `hooks-change-point-gate`, and
`claude-decision-gate`. Several already accept real `--harness cursor` input
(`hooks-session-track`, `hooks-session-log`, `hooks-engineering-autocommit`,
`hooks-checks-snapshot`). Cursor's native `stop` payload (`{status, loop_count}`) carries
no session or cwd correlation, so Cursor turn-end hooks are best-effort once wired.

`link-bin-files.sh` symlinks every file in `bin/` into `~/.bin/`, so a hook is reachable by
bare name. `tap-hook <hook> [args...]` wraps any hook command with debug logging; it names
its log file from the first argument (the hook), so it composes with `--harness`/`--event`.

`hooks-compare` is the default pattern for new hooks that relate two lifecycle events.
The first event runs `hooks-compare capture`; the second runs `hooks-compare release`,
optionally followed by `--files` or `--diff`, `--`, and a validation command. It
snapshots the complete Git worktree at capture time, reports only the intervening changes
at release time, and runs the validation only then. This keeps turn-time edits free of
repeated lint and test feedback while still returning failures to the agent at the
boundary. Harness dispatch comes from an `AGENT=claude|cursor|codex` environment
assignment in each hook definition; without `AGENT`, capture and release are silent
pass-throughs. Run `hooks-compare setup` for ready-to-copy definitions for all three
harnesses. `--files` pipes one changed path per line to the validation command; `--diff`
pipes a unified Git patch. Claude and Codex captures are isolated by session. Cursor's
`stop` payload omits its conversation identifier, so Cursor uses one capture slot per
worktree and is best-effort when several conversations share that worktree.

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. Once wired as a turn-end hook (Claude or Cursor; it is dormant today, see "Hooks" above), `hooks-checks-snapshot` (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status`; enrollment is manual — add a `path` + `checks` entry to `~/.checks.yml` by hand (see the commented example `create-local-files.sh` seeds in a fresh one). `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `hooks-checks-snapshot` | Turn-end hook (Claude and Cursor): version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks and of hooks, and spans both Claude Code and Cursor Agent. `claude-sessions` (`bind a` in tmux) discovers live agent sessions by **scanning tmux pane processes** — it walks each pane's process subtree looking for an agent CLI (`claude`, `cursor-agent`, aider, codex, …; the matched set is the `AGENTS` list at the top of the script) and lists every match in one fzf picker (a `cc`/`cu` tag distinguishes them). There is no state file and no hook to keep in sync: a session exists exactly while its process is alive, so the list can never go stale and needs no configuration — a bare `claude` or `cursor-agent` in any pane just shows up. Enter jumps straight to that pane (switch session → select window → select pane); the preview (`claude-session-preview`) is a live `tmux capture-pane` of the agent plus its location and cwd. `claude-sessions` still knows how to sort a pane first when its window name carries the `⊡` waiting prefix, but nothing sets that prefix today — `hooks-notify`, which used to set it on `Stop`/`Notification`, isn't currently wired (see "Hooks" above), so every session currently shows as `active`. The `hooks-session-track` hook that remains exists to record `track_name` for checks correlation and to restore a bare window name for the `claude-run` flow.

## Review queue

`bin/review` is a per-workspace queue of code review comments, written where you read the
code and pulled by whatever agent you are running next door. It replaced the old
`agent-comments.lua` "write comments, flush a prompt, paste it into the agent" loop: there
is no flush and no clipboard hop anymore — a comment is queued the moment you write it, and
the agent takes it from the queue.

`bin/review` is now legacy: its successor is `rvw` (Go + SQLite, `~/Projects/rvw`,
installed with `make install` into `~/go/bin/rvw`, store `~/.local/share/rvw/rvw.db`),
which keeps the same subcommands and flags but reads no environment variables — lane,
author, workspace and store are flags only. The editor plugin and the agent side both
target `rvw`; `bin/review` stays only until any pending `~/.reviews` notes are drained. The
rest of this section describes the shared model and the legacy script.

The queue is the single source of truth. `config/nvim/after/plugin/review.lua` keeps **no**
copy of it: it shells out to `rvw` for every read and acts on comments by id, so a
comment added from nvim, from a shell, or from another nvim instance shows up in all of
them. Signs are redrawn from `rvw list --format json --all-lanes --file <path>` (async, on
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
(`<leader>cx`), `:ReviewRefresh` (`<leader>cr`), `:ReviewSubmit <decision>`. `$RVW_CMD`
overrides which binary the plugin calls (default `rvw`) — e.g. a wrapper running
`rvw --db <scratch>.db "$@"` to test against a throwaway store. The editor passes no
`--lane`, so comments added from nvim are unlaned. Tests: `bats test_bin/review-nvim.bats`.

On the agent side, the `rvw` plugin (`/plugin install rvw@rvw`, skill `rvw:rvw`, source in
`~/Projects/rvw/skills/rvw/`) covers both directions: working the queue (`rvw pull`, then
`resolve`/`reject` by id) and reviewing code to leave comments for another agent
(`rvw add` + `rvw submit`). Nothing in this repo wraps it. Legacy script tests:
`bats test_bin/review.bats`.

## GitButler provenance hooks

`bin/hooks-gitbutler-stop` and `bin/hooks-gitbutler-git` enforce GitButler-provenance-style commits in repos with a `.git/gitbutler/` dir: `hooks-gitbutler-stop` (`Stop`) blocks a turn from ending while the tree is dirty; `hooks-gitbutler-git` (`PreToolUse` on Bash) denies raw git write commands, requiring the `but` CLI for mutations. Neither is currently wired (see "Hooks" above) — both are dormant scripts today.

## Engineering vault auto-commit

`~/engineering` is meant to be a git repo whose changes are committed automatically after every agent turn, so the commit never depends on the agent remembering to do it. `hooks-engineering-autocommit` is designed as a `Stop`/`stop` hook for both Claude and Cursor — but per "Hooks" above, it's currently a dormant script, so this auto-commit is **not currently running**. Once wired, it targets the **fixed** vault path (not the session cwd, since the vault is an additional working dir editable from any session): if the tree is dirty it `git add -A` + commits with a `vault: auto-commit N file(s) — <stamp>` message tagged with the harness and session id; if clean it no-ops fast. Concurrent turn-end hooks across sessions are serialised by an atomic `mkdir` lock under `.git/` (stale locks >60s reclaimed); a contender just bails, since the holder's commit or the next turn covers its changes.

`init-engineering-repo.sh` (part of `setup.sh`) idempotently creates the repo, writes `.gitignore` (`.trash/`, Obsidian `workspace*.json`/`cache`, `.DS_Store`), and seeds the first commit. Commits stay local — nothing is pushed. There is no single per-machine override switch anymore (that was `~/.agent-hooks.local.yml`, retired with `hooks-runner`); pausing this on one machine means overriding the hook at the harness's own local-settings layer.

## Neovim config

Entry point: `config/nvim/init.lua` → loads `config/options`, `config/keymaps`, `config/autocmds`, `config/pack`.

Plugins are managed by Neovim's native `vim.pack` (0.12+), pinned in `config/nvim/nvim-pack-lock.json`. `config/pack.lua` installs and loads plugins at startup with one `vim.pack.add`. It then sources every file in `lua/plugins/` by path; these files are plain setup code, not specs. Plugins that load only for one filetype are added with a no-op `load`, and their `after/ftplugin/<ft>.lua` loads them through `require("utils").packadd(names, setup)`. That helper runs once per session and replays the FileType autocmds the plugin registered, so the first buffer does not miss them. Build steps (`make`, `:TSUpdate`) run from a `PackChanged` autocmd. Leader is `<Space>`, local leader is `,`.

## Key environment variables (set in `.zshenv`)

| Variable | Purpose |
|----------|---------|
| `ENGINEERING_HOME` | Engineering knowledge-base vault (`~/engineering`) |
| `NOTES_HOME` | Daily notes dir |
| `JOURNALS_HOME` | Obsidian vault |
| `WORKLOG_PATH` | Obsidian worklog file |
| `HORSES_PATH` / `KNOWLEDGE_KB_PATH` | Horses knowledge-base engine |
| `PERSONAL_SESSIONS_DIR` | AI session artifacts (`~/engineering/.ai-sessions`) |

## Engineering knowledge base

The vault is `$ENGINEERING_HOME` (`.zshenv`, default `~/engineering`) — the local KB vault (markdown + `[[wikilinks]]`). Every script and skill that touches it resolves `${ENGINEERING_HOME:-$HOME/engineering}`. Nothing hardcodes the path.

| Section | Owner | Holds |
|---|---|---|
| `issues/` | `issue` skill | Tracked work items, one delta each |
| `artifacts/` | The workflow that records the evidence | Raw evidence and observations. An issue may link them. |
| `spikes/` | `spike` skill | Answered unknowns |
| `projects/` | `project` skill | Stable project summary, context, data map, questions, and canonical links |
| `workflows/` | `biz-workflows` skill | Standalone canonical business and system workflow diagrams |
| `VOCABULARY.md` | `vocabulary` skill | Canonical cross-project terms, aliases, usage, and relationships |

A brief lives at `projects/<slug>.md`, named by a stable bare slug. An issue names its
project in optional `project:` frontmatter, and `members.sh` derives membership. The brief
keeps no issue list. An issue holds a delta. A brief holds stable context and links the
canonical workflow files owned by `biz-workflows`.

### A skill is code, never a store

A skill directory holds `SKILL.md`, `references/`, `scripts/`, and `assets`. Nothing else.
A skill that needs durable storage uses the existing owner above instead of inventing a path.
Ephemeral output stays out of the vault and can use `/tmp`.
