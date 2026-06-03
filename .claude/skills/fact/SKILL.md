---
name: fact
description: >
  Captures a durable, sourced fact about a system, domain, or decision in the facts
  base, cross-linked to the issues that rely on it. Use when an investigation, survey,
  or review surfaces something worth remembering. Triggers on "record a fact", "save
  this as a fact", "promote to facts", "registrar fato", "isso é um fato", or when
  survey / dead-reckoning return fact candidates worth keeping.
metadata:
  allowed-tools: Read Write Edit Bash(fd:*) Bash(git:*) Bash(grep:*) Bash(mkdir:*)
---

# Fact

Stores a durable, sourced fact and links it to the issues that depend on it. Facts
are the long-lived counterpart to issues: an **issue** tracks work to be done; a
**fact** records something true that the work relies on. Both live under
`~/engineering/` (`facts/` and `issues/`).

## Step 1 — Resolve storage

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_CFG="${_ROOT}/.skills/config"
if [ -f "$_CFG" ]; then
  FACTS_DIR=$(grep '^facts=' "$_CFG" | cut -d= -f2 | xargs)
  [[ -n "$FACTS_DIR" && "$FACTS_DIR" != /* ]] && FACTS_DIR="${_ROOT}/${FACTS_DIR}"
fi
FACTS_DIR="${FACTS_DIR:-$HOME/engineering/facts}"
mkdir -p "$FACTS_DIR"
```

## Step 2 — Dedup before allocating

Search the base for an existing fact on the same subject. If one exists, **update it**
(bump `updated`, refine the statement, add the new issue link) instead of creating a
duplicate.

```bash
rg -l --ignore-case "SUBJECT_TERM" "$FACTS_DIR" 2>/dev/null | head -5
```

## Step 3 — Allocate ID

```bash
NEXT=$(fd -t f -e md . "$FACTS_DIR" -d 1 2>/dev/null \
  | sed 's|.*/||' | grep '^[0-9]' | sed 's/-.*//' | sort -n | tail -1)
ID=$(printf 'FACT-%03d' $((${NEXT:-0} + 1)))
```

## Step 4 — Capture the fact

- **Subject** — what the fact is about (one noun phrase; becomes the slug).
- **Statement** — one or two sentences, present tense, **falsifiable**.
- **Evidence** — `file:line` anchor, commit, doc link, or `observed {date}`.

Reject vague or speculative claims. A fact must be checkable; if it can't be sourced,
it's an open question on an issue, not a fact.

## Step 5 — Link issues (both directions)

A fact and an issue reference each other **by ID**:

- In the fact's `## Issues`, list each issue ID that relies on or established this fact.
- In each of those issues' `## Facts` section, add this fact's ID (`FACT-NNN`).

When the fact was surfaced while working an issue, do both links now so the graph
stays navigable from either side.

## Step 6 — Write the fact

Slugify the subject (lowercase, hyphens, max 5 words).
Write `$FACTS_DIR/<NNN>-<slug>.md` (the numeric prefix only) using
`references/template.md`. The canonical reference is `FACT-<NNN>`, written inline as a
wiki link `[[FACT-<NNN>-<slug>]]` — the form survey and dead-reckoning emit.

Confirm: "Recorded FACT-<NNN>: <subject> → $FACTS_DIR (linked to <issue-ids or none>)"
