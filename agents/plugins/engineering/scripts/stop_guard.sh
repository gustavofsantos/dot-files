#!/usr/bin/env bash
# Dirty-tree stop guard (Stop hook, runs AFTER turn_end_inject.sh).
#
# The teeth. If the working tree still has uncommitted changes on a lane when the
# agent tries to yield, block the turn from ending. This converts the reminder
# from "please commit" into "you cannot stop until you have." Deterministic —
# the main agent cannot forget, defer, or batch.
#
# Exit codes:
#   0  -> clean (or not a GitButler repo): allow the turn to end.
#   2  -> dirty: block. stderr is surfaced to the agent as the reason.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_guard.sh
source "$DIR/lib_guard.sh"

is_gitbutler_repo || exit 0

status_json="$(but status --json 2>/dev/null || true)"
[ -z "$status_json" ] && exit 0

# Clean tree -> nothing to enforce.
if ! printf '%s' "$status_json" | grep -q '"files"'; then
  exit 0
fi

# Count applied lanes. When more than one lane is applied, the agent may
# legitimately need to ASK the user which lane to commit to — and asking ends
# the turn. So the guard stands down in that case, otherwise it would block the
# very turn carrying the question.
#
# Counting is defensive: use jq against the likely structure if present, else a
# text fallback. If the count is uncertain, FAIL OPEN (stand down) — a guard that
# wrongly blocks is worse than one that wrongly passes, and the single-lane case
# (where enforcement matters) counts reliably either way.
lane_count=""
if command -v jq >/dev/null 2>&1; then
  # Try a few plausible shapes; first that yields a number wins.
  for q in \
    '[.branches[]? | select(.applied // .active // true)] | length' \
    '.branches | length' \
    '.stacks | length' ; do
    n="$(printf '%s' "$status_json" | jq -r "$q" 2>/dev/null || true)"
    if printf '%s' "$n" | grep -Eq '^[0-9]+$'; then lane_count="$n"; break; fi
  done
fi

# If jq gave us a definite count and it's >1, stand down for the lane question.
if printf '%s' "$lane_count" | grep -Eq '^[0-9]+$' && [ "$lane_count" -gt 1 ]; then
  exit 0
fi

# If we could NOT get a definite single-lane count, fail open rather than risk
# blocking a legitimate multi-lane question. Only enforce when we are confident
# it is the single-lane case (count == 1, or count unknown but jq absent is
# treated as "cannot confirm multi" -> we still enforce only on a definite 1).
if [ "$lane_count" != "1" ]; then
  # Unknown lane count: do not hard-block. Remind instead via stderr, allow exit.
  echo "[provenance] Uncommitted changes remain; lane count could not be confirmed." >&2
  echo "Commit via 'but commit <branch-id>' (ask the user which lane if more than one is applied)." >&2
  exit 0
fi

# Confident single-lane case with a dirty tree: enforce. No excuse not to commit.
echo "[provenance] Turn blocked: uncommitted changes remain on the single active lane." >&2
echo "Commit them with a why-focused message via 'but commit <branch-id>' before ending." >&2
echo "(Reasoning-only? This guard only fires on a dirty tree — empty-commit capture is off in the lean core.)" >&2
exit 2
