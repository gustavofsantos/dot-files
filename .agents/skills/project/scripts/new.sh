#!/usr/bin/env bash
# new.sh <slug> — prints the project brief path, seeding it on first use.
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: $(basename "$0") <slug>" >&2
  exit 64
fi

dir="${ENGINEERING_HOME:-$HOME/engineering}/projects"
# done/ is made up front. Without it, `mv brief.md projects/done` renames the
# brief to a file called "done" instead of failing.
mkdir -p "$dir/done"

f="$dir/${slug}.md"
if [[ ! -f "$f" ]]; then
  cat > "$f" <<EOF
---
created: $(date +%F)
tags: []
---

## Objective
One sentence. What this project is for. A campaign ends. A domain does not.

## Glossary
The vocabulary of this project, in plain words.

- **term** — what it means here.

## Workflow context
Links to canonical standalone files in workflows/. Do not embed a second topology.

## Data map
Where the data lives. Name each dataset. Say what one row means. Name the traps.

- **dataset** — one row is X. Trap: Y.

## Standing questions
The open unknowns. A spike answers one. Move the answer into the relevant stable section.

- [ ] question

## Key artifacts
The few files worth reading cold. This is not an index.

- [[name]] — what it is, and why it is here.
EOF
fi

echo "$f"
