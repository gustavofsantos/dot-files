---
name: gitbutler-provenance
description: >-
  Per-turn, why-focused commits on GitButler virtual branches so unmerged
  branches explain themselves weeks later. Activate in any repo under GitButler
  management. The main agent writes each commit message from lived turn context;
  hooks enforce that no turn ends with an uncommitted tree and that raw git
  writes are blocked. Retrieval is pure git (blame, log -L).
---

# GitButler provenance

## Why this exists

Large implementations sit on unmerged branches for days or weeks waiting on
review. When you come back to a change you don't recognize, the rationale is
gone. This workflow puts the rationale in the commit message at the moment it's
made, so the branch carries its own explanation the whole time it waits. No
database, no knowledge base — just git, read back via `git blame` and
`git log -L`.

## The loop

The unit of work is one message exchange. You send a message, the agent works,
the turn ends — that boundary is the checkpoint. Nothing commits mid-turn.

At turn end:

1. `but status --json` — read the active branch id and the file/hunk ids.
2. Write a **why-focused** message (see below).
3. `but commit <branch-id> -m "<subject>" -m "<body>"` — scope with
   `--changes <ids>` if only part of the tree belongs to this lane.

A Stop hook (`claude-hook-gitbutler-stop`, wired in `.claude/settings.json`)
**blocks the turn from ending** while the tree is still dirty. So this is not
optional — finish the commit before yielding. The guard blocks at most once
per turn, so when you must ask the user which lane to use, the question gets
through on the retry instead of looping (see Lane discipline).

## Writing the message

The message answers **why**, for someone reading it cold, weeks later, out of
log order (via blame on a single line). It must be self-contained.

Capture:
- the goal, from the user's message;
- the path taken — key decisions, not a diff narration;
- what was ruled out, if anything.

Do not restate the diff. The diff is already in the commit. A message that says
*what* changed is noise; a message that says *why* is the entire point.

**Never use `but commit --ai`.** It generates the message from the diff alone,
reconstructing rationale post-hoc — the exact low-fidelity output this workflow
exists to avoid. You hold the real reasoning; you write it.

## Git discipline

Use `but` for every write. Raw `git commit/add/push/checkout/switch/merge/
rebase/stash/reset/branch/cherry-pick/revert` is blocked by a PreToolUse hook
(`claude-hook-gitbutler-git`) in GitButler repos. Read-only git (`status`,
`log`, `blame`, `diff`, `show`) is fine and is the retrieval path.

Get current CLI ids from `but status --json` before any mutation — ids are
short (2–3 chars) and can change between turns. Pass `--status-after` to chain
operations without re-querying.

## Lane discipline — which lane to commit to

The agent does not inherently know which lane a fresh change belongs to. A wrong
guess is the worst failure mode this system has: the change lands on the wrong
branch, ships in the wrong PR, and the provenance is now actively misleading —
worse than no provenance, because it will be trusted. So decide by lane count,
read from `but status --json`, and **ask rather than infer** when ambiguous:

- **Exactly one lane applied** → no ambiguity. Commit to it silently
  (`but commit` defaults to the single applied lane). This is the normal,
  heads-down case and stays frictionless.

- **More than one lane applied** → do **not** infer from file paths. Stop and
  ask the user which lane these changes belong to, then commit to that lane by
  id. If the turn legitimately spans two lanes, ask, then commit each separately
  with `--changes <ids>` scoping each commit to that lane's ids, each with its
  own why-focused message. (Asking ends the turn; the stop guard blocks at most
  once per turn, so it will not block the question on the retry.)

- **Zero lanes applied** → `but commit` would create a temp-named branch. Confirm
  with the user first rather than spawning a branch silently.

When you switch what you're working on, switch the active lane deliberately.

## Retrieval (how the payoff is collected)

- `git blame -L <start>,<end> <file>` → the commit → its message.
- `git log -L <start>,<end>:<file>` → the evolution of a specific range.
Fine per-turn granularity is what makes blame land on the right commit.

## Scope / non-goals

- Reasoning-only turns (decided something, changed no code) are **not** captured
  in the lean core — the dirty-tree guard only fires on a diff. Empty-commit
  capture (`but commit empty`) can be added if the "ruled out" narrative proves
  worth the extra commits.
- This is provenance, not memory. It stops at "the branch explains itself."
  No cross-branch or cross-session synthesis.
- Intermediate history is busy by design. Clean up at PR time with GitButler
  (squash, reorder, absorb). Expect recoverable history, not pretty history.
