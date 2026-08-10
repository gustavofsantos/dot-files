#!/usr/bin/env bash
# members.sh <slug> — prints the issues that name this project, one path per line.
# Order is active, then backlog, then done.
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: $(basename "$0") <slug>" >&2
  exit 64
fi

issues="${ENGINEERING_HOME:-$HOME/engineering}/issues"
[[ -d "$issues" ]] || exit 0

# The project is declared in the frontmatter. A mention in the prose is not
# membership, so awk stops at the closing delimiter.
find "$issues" -type f -name '*.md' -print0 \
  | LC_ALL=C sort -z \
  | while IFS= read -r -d '' f; do
      if awk -v slug="$slug" '
           NR == 1                { if ($0 != "---") exit; next }
           /^---[[:space:]]*$/    { exit }
           $0 == "project: " slug { found = 1; exit }
           END                    { exit (found ? 0 : 1) }
         ' "$f"; then
        echo "$f"
      fi
    done
