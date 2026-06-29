#!/usr/bin/env bash
# Raw-git write block (PreToolUse hook on Bash).
#
# In a GitButler repo, raw `git commit/add/push/...` bypasses lane assignment and
# corrupts the provenance + parallel-branch model. Force everything through `but`.
# Enforcement, not instruction (per the maxim: if a hook can enforce it, don't
# delegate it to the agent via prose).
#
# Reads the proposed Bash command from the tool-call payload on stdin (JSON).
# Gated on is_gitbutler_repo so normal git works everywhere else.
#
# Exit codes:
#   0 -> allow.
#   2 -> deny; stderr explains and points at the `but` equivalent.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_guard.sh
source "$DIR/lib_guard.sh"

is_gitbutler_repo || exit 0

payload="$(cat)"
# Best-effort extraction of the command string from the PreToolUse payload.
# Falls back to the raw payload if jq is unavailable or shape differs.
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"
else
  cmd="$payload"
fi
[ -z "$cmd" ] && exit 0

# Block git write verbs. Read-only git (status/log/blame/diff/show) stays allowed —
# those are exactly the retrieval path we want to keep working.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|]|\s)git\s+(commit|add|push|checkout|switch|merge|rebase|stash|reset|cherry-pick|branch)\b'; then
  echo "[provenance] Raw git write blocked in a GitButler repo." >&2
  echo "Use 'but' instead so changes stay lane-assigned and provenance is preserved:" >&2
  echo "  git commit  -> but commit <branch-id> -m \"...\"" >&2
  echo "  git add     -> but stage / lane assignment is automatic" >&2
  echo "  git push    -> but push" >&2
  echo "  git branch  -> but branch new <name>" >&2
  echo "Read-only git (status/log/blame/diff/show) is fine." >&2
  exit 2
fi

exit 0
