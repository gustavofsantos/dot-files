#!/usr/bin/env bash
# new.sh <slug> [issue-id] — prints spike path, seeds frontmatter
set -euo pipefail
slug="$1"; issue="${2:-}"; dir=~/engineering/spikes; mkdir -p "$dir"
if [[ -n "$issue" ]]; then prefix="$issue"; else
  n=$(ls ~/engineering/issues/ ~/engineering/issues/archive/ "$dir" 2>/dev/null \
    | grep -oE '^[0-9]+' | sort -n | tail -1)
  prefix=$(printf '%03d' $(( ${n:-0} + 1 )))
fi
f="$dir/${prefix}-${slug}.md"
[[ -f "$f" ]] || printf -- '---\nstatus: resolved\ncreated: %s\n---\n' "$(date +%F)" > "$f"
echo "$f"
