#!/usr/bin/env bash
# new.sh <slug> — prints the spike path, seeding frontmatter on first use.
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: $(basename "$0") <slug>" >&2
  exit 64
fi

today=$(date +%F)
dir="${ENGINEERING_HOME:-$HOME/engineering}/spikes"
mkdir -p "$dir"

f="$dir/${today}-${slug}.md"
if [[ ! -f "$f" ]]; then
  cat > "$f" <<EOF
---
status: resolved
created: $today
---
EOF
fi

echo "$f"
