# Handoff: unify hooks across Claude Code and Cursor

Paste this into a fresh session working in the dotfiles repo. It is the hooks
counterpart to the skills work already landed (`bin/skills-sync` +
`.claude/harness-profiles.yml`). Start with review, not code.

## Goal

Let me define a hook once, in one representation, and have it run correctly under
both Claude Code and Cursor — including hooks that need to **influence** the agent
(block a turn, inject context, veto a tool), not just observe. Same philosophy as
skills-sync: one source of truth, a small per-harness adapter, generated wiring.

## What already exists (read before proposing anything)

- `bin/hooks-runner` (Ruby) is already a working **input adapter**. It:
  - maps raw harness events to canonical names via `CANONICAL_EVENTS`
    (`claude Stop`/`cursor stop` → `turn_end`, etc.),
  - normalises each harness's payload into one `CanonicalEvent` envelope
    (`build_envelope`: Claude's `session_id`/`cwd` vs Cursor's
    `conversation_id`/`workspace_roots[0]`),
  - dispatches to hooks from `~/.agent-hooks.yml` (+ `~/.agent-hooks.local.yml`
    overlay), filtered by a `harness: [claude, cursor]` field.
- `.agent-hooks.yml` is the unified registry. Today every entry is an **observer**:
  session-track, session-log, notify, checks-snapshot, engineering-autocommit.
- Observer hooks work cross-harness already. That half of the problem is solved.

## The real gaps (this is the whole task)

1. **No output adapter.** `hooks-runner` *always exits 0 and suppresses hook
   stdout* by design (see its header + `dispatch`). It can carry an event *in*; it
   cannot carry a decision *out*. That is exactly why the two **blocking** hooks —
   `claude-hook-gitbutler-stop` and `claude-decision-gate` — are wired **directly**
   in `.claude/settings.json` under `Stop`, bypassing the runner, and are
   Claude-only. The split in the codebase *is* the boundary of the abstraction.

   Fix: define a canonical hook **decision** (e.g. `{decision: "block"|"allow",
   reason, additionalContext}`) that a hook emits on stdout, and have `hooks-runner`
   translate it to each harness's native contract:
   - Claude: exit code 2 + JSON on stdout with `decision`/`reason`/
     `additionalContext` (verify current Claude hook output schema against the docs
     before implementing — do not trust memory).
   - Cursor: its own permission/deny/block shape (verify against Cursor's current
     hook contract).
   Observers keep today's exit-0 semantics; only hooks that opt into a decision go
   through the new path. Note `hooks-runner` runs multiple hooks per event — decide
   precedence when several return decisions (first block wins is the obvious rule).

2. **Cursor invocation is not wired by this repo.** CLAUDE.md notes the dotfiles no
   longer ship a `~/.cursor/hooks.json`, so nothing actually calls
   `hooks-runner cursor <event>` unless wired by hand outside the repo. Generate that
   wiring the same way skills-sync generates the Cursor skills tree: derive
   `~/.cursor/hooks.json` (mapping each Cursor event → `hooks-runner cursor <event>`)
   from a source of truth, installed by a setup script. Confirm Cursor's current
   hooks.json location and event names first.

## The precedent to mirror (just landed — study it)

- `bin/skills-sync` + `.claude/harness-profiles.yml`: one Claude-native source,
  per-harness profile transform, generated per-harness tree, `.skills-sync` marker
  so pruning never touches hand-made files, wired into `scripts/install-claude.sh`.
- Reuse the shape: source of truth + per-harness adapter/profile + generated output
  + idempotent installer step + a marker if you generate into a shared dir.

## Before any implementation

- Verify the **current** Claude Code hook output contract (exit codes, stdout JSON
  fields for block/context injection) and the **current** Cursor hook contract from
  their live docs — both have changed over time. Do not code against remembered
  schemas.
- Confirm whether `claude-decision-gate` and `claude-hook-gitbutler-stop` actually
  need cross-harness behavior, or are deliberately Claude-only (gitbutler provenance
  may be Claude-specific). Migrate only what benefits.
- Decide: keep blocking hooks native in `settings.json`, or route them through the
  new output adapter. Recommend the latter only if it doesn't lose fidelity.

## Task

- Design the canonical decision protocol and add the **output adapter** to
  `hooks-runner` (translate canonical decision → per-harness exit code + stdout),
  keeping observers on the existing neutral path.
- Add a generator for `~/.cursor/hooks.json` (source of truth in-repo → generated
  file), wired into a `scripts/install-*.sh` step, mirroring skills-sync.
- Migrate the blocking hooks that should be cross-harness onto the unified path;
  leave genuinely Claude-only ones where they are, documented as such.
- Update CLAUDE.md (the "GitButler provenance hooks" and agent-hooks sections) and
  the `agent-hooks` skill if the envelope/registry/decision shape changes.

## Validation

- Unit-test the decision translation for both harnesses (canonical in → correct
  exit code + stdout out).
- Drive a real block end-to-end in each harness (e.g. dirty-tree Stop): confirm
  Claude blocks via exit-2+JSON and Cursor blocks via its own shape, from the *same*
  registry entry.
- Confirm observers are unaffected (session tracking, autocommit, checks still fire
  and never block).
- Idempotent installer; generated `hooks.json` regenerates cleanly and prunes stale
  entries without clobbering hand-made Cursor config.

## Non-goals

- Don't touch the skills pipeline (done).
- Don't unify hooks that are intentionally harness-specific just to force symmetry.
- No new dependencies; stay in Ruby/bash to match `hooks-runner` and the setup
  scripts.
