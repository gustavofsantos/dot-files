#!/usr/bin/env bash
# new.sh <slug> [frame-ref] — prints plan path, seeds frontmatter
set -euo pipefail
slug="$1"; frame="${2:-}"; dir=~/Documents/Plans; mkdir -p "$dir"
f="$dir/${slug}.md"
if [[ ! -f "$f" ]]; then
  printf -- '---\nstatus: open\ncreated: %s\nframe: %s\n---\n' \
    "$(date +%F)" "${frame:-<frame-ref>}" > "$f"
fi
echo "$f"
