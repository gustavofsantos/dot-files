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

## Cross-harness skills

`.claude/skills/` is the Claude-native source of truth (maximal frontmatter). Other
harnesses can't consume it as-is: Cursor reads `.claude`-style skills but only acts on
`name` + `description`, and Claude-only frontmatter (`disable-model-invocation`,
`allowed-tools`, `context: fork`) leaks as misapplied config. `bin/skills-sync` derives a
per-harness tree from the one source: it rewrites only the SKILL.md frontmatter (dropping
/ renaming keys per `.claude/harness-profiles.yml`) and symlinks the body's `references/`
and `scripts/` back to the source, so editing a skill reflects immediately — only
frontmatter changes need a re-run. `install-claude.sh` (run by `setup.sh`) symlinks
`harness-profiles.yml` into `~/.claude/` and runs the sync; the default Cursor target is a
generated `~/.cursor/skills/` tree.

The frontmatter transform is **textual**, not a YAML round-trip: descriptions are
preserved byte-for-byte (some are plain scalars with `": "` that strict YAML rejects but
Claude accepts). Generated skills carry a `.skills-sync` marker; pruning of stale skills
only ever touches marked dirs, so hand-made skills in the same destination are left alone.
Adding a harness = adding an entry to `harness-profiles.yml`, never editing a SKILL.md to
fit a harness. Because a skill's *body* is shared verbatim across harnesses, keep bodies
harness-agnostic: don't name a specific subagent (say "use a subagent to explore X" so each
harness picks the agent that fits) or a Claude-only tool.

| Script | What it does |
|--------|--------------|
| `skills-sync` | Derive per-harness skill trees from `.claude/skills/` per `harness-profiles.yml`. Idempotent; `--source`, `--profiles`, `--harness NAME`, `--dry-run`. |

Cursor reuses these same skills/agents by loading Claude's config directly (configured
outside this repo). Hooks are unified on the same one-source/per-harness-adapter model
— see "Agent hooks" below: `hooks-runner` is the input+output adapter, `.agent-hooks.yml`
the single registry, and `cursor-hooks-sync` the generated Cursor wiring (the analog of
`skills-sync`). Observers run cross-harness; blocking hooks that both harnesses can veto
(tool-use) do too. Turn-end blocking stays Claude-only because Cursor's stop hook is
observe-only (can't block a turn from ending).

The `.claude/settings.json` merges into the global `~/.claude/settings.json` on install.
Global settings win on scalar/object conflicts; `permissions.allow/deny/ask` arrays are
unioned.

## Agent hooks

`~/.agent-hooks.yml` is the single registry of hooks run across harnesses, dispatched by
`bin/hooks-runner` (Ruby). Each harness invokes `hooks-runner <harness> <event>`; the
runner maps the raw event to a canonical name (`Stop`/`stop` → `turn_end`, Claude
`PreToolUse` / Cursor `beforeShellExecution`,`beforeMCPExecution` → `tool_pre`, …),
normalises the payload into one `CanonicalEvent` envelope (Claude `session_id`/`cwd`/
`tool_input` vs Cursor `conversation_id`/`workspace_roots[0]`/`command`), and runs each
matching hook — filtered by a `harness: [claude, cursor]` allowlist — with the envelope on
stdin. Local machine hooks overlay by name via `~/.agent-hooks.local.yml`.

**Input adapter (observers).** Most hooks just observe: their stdout is suppressed and the
runner stays neutral (exit 0), so they never block a harness. session-track, session-log,
notify, checks-snapshot, engineering-autocommit are all observers, cross-harness already.

**Output adapter (decision hooks).** A hook with `decision: true` in the registry emits a
canonical decision on stdout — `{"decision":"block"|"allow","reason","context"}` — and the
runner translates the first block (registry order) into the invoking harness's *native*
contract: Claude `tool_pre` → `permissionDecision:"deny"`; Claude `turn_end`/`prompt_submit`
→ `decision:"block"` (+ `additionalContext`); Cursor `tool_pre` → `permission:"deny"`
(`agentMessage`/`userMessage`); Cursor `prompt_submit` → `continue:false`. A `turn_end`
block is Claude-only: Cursor's stop hook is observe-only and can't block a turn from ending,
so such a decision is dropped with a logged note. This is why turn-end blockers stay native
in `settings.json` (see "GitButler provenance hooks"), while the tool-veto (`gitbutler-git`)
runs on the unified path and blocks in *both* harnesses from one registry entry.

**Generated Cursor wiring.** `cursor-hooks-sync` derives `~/.cursor/hooks.json` from the
registry the way `skills-sync` derives skills: for every canonical event with a
Cursor-applicable hook it wires the matching Cursor event(s) to `hooks-runner cursor
<event>`. Only its own `hooks-runner cursor …` entries are added/replaced/pruned, so
hand-made Cursor hooks in the same file are never touched. `install-claude.sh` runs it
after `skills-sync`. (Cursor also loads Claude's config directly for skills/agents; the
generated `hooks.json` is what wires the hook *events*.)

| Script | What it does |
|--------|--------------|
| `hooks-runner` | Dispatch `~/.agent-hooks.yml` hooks for a `<harness> <event>`; input+output adapter (envelope in, canonical decision → native contract out). |
| `cursor-hooks-sync` | Generate `~/.cursor/hooks.json` from the registry. Idempotent; `--source`, `--local`, `--dest`, `--dry-run`. |

## Agent checks

A single global registry, `~/.checks.yml`, enrolls the repositories that run checks after each agent turn and defines them — each check a `name` + a `command`, modeled on the hooks shape. Repos are matched by `path` (main working tree), so every worktree is covered; unregistered repos are skipped. After every agent turn the `Stop` hook fires `checks-snapshot`, which (for enrolled repos) hashes the changed tracked files (`checks-hash`), versions them under `~/.checks/<session>/<hash>/`, and spawns `checks-runner` detached to run the checks and write `results.json`. The agent reads them via `checks-status`; enrollment is managed by the `setup-checks` skill. `~/.checks.local.yml` (same shape) overlays a repo's checks by name for machine-specific checks. `create-local-files.sh` seeds an empty `~/.checks.yml`.

| Script | What it does |
|--------|--------------|
| `checks-hash` | Stable content hash of tracked working-dir changes vs `HEAD` |
| `checks-config` | Resolve a repo's checks from `~/.checks.yml` (handles worktrees); `--registered` for an enrolment check |
| `checks-snapshot` | `Stop` hook: version changes for enrolled repos, fire the runner (no-op if unchanged) |
| `checks-runner` | Run a snapshot's checks; `--watch` for daemon mode |
| `checks-status` | Show the latest result for a session/repo (`--json`, `--oneline`) |

Session navigation is independent of checks, and spans both Claude Code and Cursor Agent. A `SessionStart`/`UserPromptSubmit` hook (`claude-hook-session-track`) registers *every* Claude session — however launched — into `~/.agent-sessions/<id>.json` with the exact tmux pane it runs in; `SessionEnd` (`claude-hook-session-end`) marks it ended. Cursor can mirror this: the `cursor-hook-session-track`/`cursor-hook-session-end` scripts (kept in `bin/`, dispatched via `hooks-runner cursor <event>`) translate Cursor's `conversation_id`/`workspace_roots` into the *same* `~/.agent-sessions/<id>.json` schema (tagged `agent:"cursor"`), with `beforeSubmitPrompt` creating-if-missing so a session registers on its first prompt. The `~/.cursor/hooks.json` that wires these Cursor events is generated by `cursor-hooks-sync` from the shared registry (see "Agent hooks"), so Cursor session tracking is wired on install without hand-editing. Each agent turn also appends structured events to `~/.agent-sessions/<id>.jsonl` via `claude-hook-session-log` (`turn_end`, `message`, `file_change`, `session_start`, `session_end`). `claude-sessions` (`bind a` in tmux) lists both tools in one picker (a `cc`/`cu` tag distinguishes them), keys liveness on whether that pane still exists, previews the session log (plus live pane), and Enter jumps straight to the pane running the agent. Works for a bare `claude` or `cursor-agent` in any pane.

## GitButler provenance hooks

Two hooks in `bin/` enforce the `gitbutler-provenance` skill in repos with a `.git/gitbutler/` dir — and no-op instantly everywhere else.

`claude-hook-gitbutler-git` denies raw git write commands (`commit`, `add`, `push`, `checkout`, `rebase`, …) — mutations must go through the `but` CLI; read-only git passes. It runs on the **unified path** as a `tool_pre` decision hook (`.agent-hooks.yml`, `harness: [claude, cursor]`): `settings.json` wires `PreToolUse` on Bash to `hooks-runner claude PreToolUse`, and the generated `~/.cursor/hooks.json` wires `beforeShellExecution`/`beforeMCPExecution` — so the same guard denies raw git writes whether GitButler is driven from Claude Code or Cursor. The hook emits a canonical `{"decision":"block",…}`; the runner translates it to each harness's deny contract.

`claude-hook-gitbutler-stop` (`Stop`) blocks a turn from ending while the tree is dirty, at most once per turn (`stop_hook_active`), so a lane question can still reach the user. It stays wired **natively** in `.claude/settings.json` and is Claude-only by necessity: Cursor's stop hook is observe-only and cannot block a turn from ending, so routing it through the runner would gain nothing cross-harness.

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
