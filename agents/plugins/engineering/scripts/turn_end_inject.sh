#!/usr/bin/env bash
# Turn-end injector (Stop hook).
#
# Fires deterministically when the main agent finishes a turn. Does NOT commit
# anything itself and does NOT call a subagent. It injects an instruction telling
# the MAIN agent to write a why-focused commit message from the turn it just
# lived, and commit to the active lane via `but`. Fidelity stays at the source.
#
# The actual enforcement (turn cannot end dirty) lives in stop_guard.sh.
# This hook only handles the *reminder*; the guard handles the *teeth*.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_guard.sh
source "$DIR/lib_guard.sh"

is_gitbutler_repo || exit 0

# Only nudge if there is actually something uncommitted on a lane.
# `but status --json` is the authoritative read of workspace state.
status_json="$(but status --json 2>/dev/null || true)"
[ -z "$status_json" ] && exit 0

# If there are no uncommitted changes at all, nothing to do this turn.
# (Lean core: reasoning-only turns are NOT captured yet. See README.)
if ! printf '%s' "$status_json" | grep -q '"files"'; then
  exit 0
fi

# Emit the instruction back to the main agent. The agent already holds the full
# turn in context (your message + its reasoning + the edits) — it writes the
# message from lived context, not reconstruction.
cat <<'INSTRUCTION'
[provenance] Before ending this turn, commit your changes with GitButler.

Write the commit message to answer WHY this change exists for someone reading it
cold, weeks from now, on an unmerged branch — not WHAT changed (the diff shows
that). Capture: the goal from my message, the path you took, and anything you
ruled out. Self-contained: it must answer "why does this line exist" on its own,
because it will be read via `git blame` / `git log -L`, out of log order.

Steps:
  1. `but status --json` to get the active branch id and file/hunk ids.
  2. Compose the why-focused message (subject + verbose body).
  3. `but commit <branch-id> -m "<subject>" -m "<body>"`
     (scope with `--changes <ids>` if only part of the tree belongs to this lane).

Do NOT use `but commit --ai` — that reconstructs rationale from the diff alone,
which is exactly the low-fidelity message we are avoiding. You write it.
INSTRUCTION
