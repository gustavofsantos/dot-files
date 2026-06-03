---
name: issue
description: >
  Co-authors a new issue with BDD scenarios from a problem description, then writes the
  issue file. Use when the user has a new problem, feature, or task to track. Triggers on
  "new issue", "nova issue", "create issue for", "criar issue para", "let's work on X",
  "vamos trabalhar em X", or any raw problem description that needs to be shaped before
  execution.
metadata:
  allowed-tools: Read Write Edit Bash(fd:*) Bash(git:*) Bash(grep:*) Bash(mkdir:*)
---

# Issue

Turns a problem description into a tracked issue with co-authored BDD scenarios.

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

## Step 3 — Get the objective

If not stated in the request: "What's the objective — one sentence describing what done looks like?"

## Step 4 — Classify the work

Set `type` on the issue:

- **`implementation`** — code is to be written or changed. Scenarios are BDD
  (Given/When/Then); the `tdd` skill implements them; done = scenarios green.
- **`investigation`** — a question must be answered before (or instead of) building.
  Scenarios are the questions to resolve and the findings expected; the
  `dead-reckoning` skill is the engine; done = the questions are answered and the
  durable answers are recorded as facts via the `fact` skill.

If unsure, ask: "Is this work to build something, or to find something out?"

## Step 5 — Co-author scenarios

Propose scenarios one at a time. Start with the happy path, then edge cases, then
error and limitation cases. For an `investigation` issue, frame each scenario as a
question to answer and the observation that would settle it.

For each proposal:
- State it in Given/When/Then form (or Question/Expected-finding for investigation)
- Wait for confirmation, reframe, or rejection before the next
- Rejected or out-of-scope proposals become **Off-limits** entries

When the list feels complete: "Anything missing, or anything to remove?"

Assign stable IDs: S1, S2, S3, …

## Step 6 — Link known facts

Search the facts base for anything this issue already depends on:

```bash
FACTS_DIR="${FACTS_DIR:-$HOME/engineering/facts}"
rg -l --ignore-case "KEY_TERM" "$FACTS_DIR" 2>/dev/null | head -5
```

List any relevant fact IDs in the issue's `## Facts` section, and add this issue's ID
to each of those facts' `## Issues` section (the link is bidirectional — see the
`fact` skill). New facts discovered while working the issue are promoted the same way.

## Step 7 — Write the issue

Slugify the title (lowercase, hyphens, max 5 words).
Write `$ISSUES_DIR/<ID>-<slug>.md` using `references/template.md`.
Derive tasks from scenario groupings.

Confirm: "Created issue <ID> (<type>): <title> — N scenarios → $ISSUES_DIR"
