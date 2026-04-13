---
name: knowledge
description: >
  Manages the knowledge library — atomic facts and spike narratives that accumulate
  across all work. Use this skill when a validated discovery should be preserved beyond
  a single session, when promoting a dead-reckoning theorem to a permanent fact, when
  querying for prior knowledge before starting work, or when maintaining the qmd index.
  Triggers on phrases like "save this as a fact", "do we know anything about X",
  "promote this theorem", "what do we know about Y", or when the workflow skill's
  session start protocol runs knowledge retrieval.
---

# Knowledge

The knowledge library is the long-term memory of the system. It survives card completion,
session endings, and context window pressure. It is queried automatically at session start
and written to whenever a validated fact is discovered.

---

## Storage layout

```
~/.knowledge/
  facts/
    FACT-001-auth-token-refresh-window.md
    FACT-002-billing-cycle-immutability.md
  spikes/
    001-auth-investigation.md
    002-payment-flow-traversal.md
```

Facts are global — not scoped to a system or repo. A fact about Clojure lazy sequences
is as valid here as a fact about SeuBarriga's billing rules.

Spikes are narratives — the story of an investigation. They reference facts but do not
contain them.

---

## Fact format

```markdown
---
id: FACT-NNN
title: "Short label — what this fact says"
confidence: asserted | validated
created: YYYY-MM-DD
confirmed: YYYY-MM-DD
tags: [auth, clojure, seubarriga]
refs:
  - spike: ~/.knowledge/spikes/001-auth-investigation.md
  - card: "007"
  - commit: abc1234
---

## Statement

One paragraph. Plain language. Behavioral claim, not code description.
What is true, not how it is implemented.

## Evidence

What anchors this fact. File and line, commit hash, or test name.
Prefer commit hash over file:line — a changed hash signals staleness.

## Depends on

- FACT-NNN (if this fact builds on another)

## Notes

Optional. Caveats, edge cases, conditions under which this might not hold.
```

**Confidence levels:**
- `asserted` — stated by the human as external truth. Not yet verified in code.
- `validated` — confirmed through traversal or testing. Anchored to evidence.

Never invent a fact. Never assert confidence higher than the evidence supports.

---

## Spike format

Spikes live in `~/.knowledge/spikes/`. They are produced by `dead-reckoning`.
Their format is defined in the `dead-reckoning` skill.

A spike references facts by ID. It never contains the fact content.

```markdown
This confirms that auth token refresh happens before expiry validation.
→ FACT-007

The billing cycle is immutable once created — updates are not possible,
only replacements.
→ FACT-012, FACT-013
```

---

## Creating a fact

When a validated discovery warrants permanent storage:

1. Determine the next ID:
   ```bash
   ls ~/.knowledge/facts/ | grep -oP 'FACT-\d+' | sort -t- -k2 -n | tail -1
   ```
   Increment by 1. Zero-pad to 3 digits: FACT-001, FACT-002, etc.

2. Create the file:
   ```bash
   ~/.knowledge/facts/FACT-NNN-<slug>.md
   ```
   Slug: kebab-case summary of the statement. Max 5 words.

3. Fill all required fields. Leave `confirmed` blank if confidence is `asserted`.

4. Update the qmd index:
   ```bash
   qmd update
   qmd embed
   ```
   Run both. `update` re-indexes text; `embed` regenerates vectors for semantic search.
   This is required for the fact to be retrievable in future sessions.

5. Add the fact ID to the originating card's `facts:` field.

---

## Querying facts

### At session start (automatic)

```bash
qmd query "<card title> <card objective>" --min-score 0.5 -n 8 --files
```

Returns file paths. Read the ones above threshold. Ignore the rest.

### During investigation

```bash
# Semantic search — best for "do we know anything about X"
qmd query "auth token expiry behavior" -n 5

# Keyword search — best for known terms
qmd search "FACT-007" --full

# Get a specific fact
qmd get "facts/FACT-007-auth-token-refresh-window.md" --full
```

### Finding related facts before writing a new one

Before creating a fact, check for duplicates or related facts:
```bash
qmd query "<proposed fact statement>" -n 5 --min-score 0.6
```

If a related fact exists, update it rather than creating a new one.
Single source of truth — never duplicate.

---

## Promoting a theorem from dead-reckoning

When `dead-reckoning` produces a confirmed theorem:

1. The theorem has: a statement, an anchor (commit hash or file:line), and human confirmation.
2. Create a fact with `confidence: validated`.
3. Set `confirmed` to today's date.
4. Set `refs.spike` to the spike document that produced it.
5. Set `refs.commit` if available.
6. Run `qmd update && qmd embed`.
7. In the spike document, replace the full theorem text with `→ FACT-NNN`.

---

## Invalidating a fact

When a fact is discovered to be wrong or outdated:

1. Add a `## Invalidated` section to the fact file:
   ```markdown
   ## Invalidated

   **Date:** YYYY-MM-DD
   **Reason:** What changed or what was wrong.
   **Cascade:** List any facts that depended on this one and must be reviewed.
   ```
2. Change `confidence` to `invalidated` in the front-matter.
3. Run `qmd update && qmd embed`.

Do not delete invalidated facts. The history of what was believed is useful.
Spikes that referenced the fact still make sense if the fact records why it was invalidated.

---

## qmd collection setup (one-time)

```bash
qmd collection add ~/.knowledge --name knowledge
qmd context add qmd://knowledge "Engineering knowledge base — facts and spike narratives"
qmd embed
```

Run once when setting up a new machine.

---

## Rules

- One fact per atomic claim. If a fact needs two paragraphs, it contains two claims — split it.
- Facts are global. Never scope them to a system when the claim is universal.
- Never copy fact content into a card or spike. Reference by ID only.
- A fact exists to be found. If it cannot be found by `qmd query`, it does not exist.
  Always run `qmd update && qmd embed` after writing.
- Confidence is a property of the evidence, not of how certain you feel.
  Asserted = human said so. Validated = code confirms it.
