---
name: issue
description: >
  Storage layer for tracked issues. Allocates an ID, links known facts, and writes the
  issue file. Called as the final step by framing skills (user-story-builder, outcome-builder,
  bug, epic, hypothesis). Use directly only when you have pre-formed content ready to store.
  Triggers on "store issue", "save issue", "write issue", or as the last step of any framing skill.
metadata:
  allowed-tools: Read Write Edit Bash(fd:*) Bash(git:*) Bash(grep:*) Bash(mkdir:*) Bash(rg:*)
---

# Issue

Pure storage layer. Receives pre-formed issue content and persists it to the engineering KB.

## Step 1 — Resolve storage

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_CFG="${_ROOT}/.skills/config"
if [ -f "$_CFG" ]; then
  ISSUES_DIR=$(grep '^issues=' "$_CFG" | cut -d= -f2 | xargs)
  [[ -n "$ISSUES_DIR" && "$ISSUES_DIR" != /* ]] && ISSUES_DIR="${_ROOT}/${ISSUES_DIR}"
fi
ISSUES_DIR="${ISSUES_DIR:-$HOME/engineering/issues}"
mkdir -p "$ISSUES_DIR"
```

## Step 2 — Allocate ID

```bash
NEXT=$(fd -t f -e md . "$ISSUES_DIR" -d 1 2>/dev/null \
  | sed 's|.*/||' | grep '^[0-9]' | sed 's/-.*//' | sort -n | tail -1)
ID=$(printf '%03d' $((${NEXT:-0} + 1)))
```

## Step 3 — Link known facts

Search the facts base for key terms from the issue content:

```bash
FACTS_DIR="${FACTS_DIR:-$HOME/engineering/facts}"
rg -l --ignore-case "KEY_TERM" "$FACTS_DIR" 2>/dev/null | head -5
```

List relevant fact IDs in the issue's `## Facts` section. Add this issue's ID to each fact's `## Issues` section (bidirectional — see the `fact` skill).

## Step 4 — Write the issue

Slugify the title (lowercase, hyphens, max 5 words).
Write `$ISSUES_DIR/<ID>-<slug>.md` with the pre-formed content, filling in `{id}` and `{today}`.

Confirm: "Created issue <ID> (<type>): <title> — $ISSUES_DIR"
