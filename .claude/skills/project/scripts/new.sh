#!/usr/bin/env bash
# new.sh <slug> — prints the project brief path, seeding it on first use.
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: new.sh <slug>" >&2
  exit 64
fi

dir="$HOME/engineering/projects"
mkdir -p "$dir"

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

## Topology
How the system works today. Mermaid. This is system state, not a change.

## Data map
Where the data lives. Name each dataset. Say what one row means. Name the traps.

- **dataset** — one row is X. Trap: Y.

## Standing questions
The open unknowns. A spike answers one. The answer then moves up into Glossary,
Topology, or Data map.

- [ ] question

## Key artifacts
The few files worth reading cold. This is not an index.

- [[name]] — what it is, and why it is here.
EOF
fi

echo "$f"
