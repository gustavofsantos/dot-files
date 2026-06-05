# Write contracts

## Note (fact, term, concept — same thing)

**Location:** `~/engineering/<slug>.md`

**Filename:** lowercase, hyphenated slug. This is the canonical link target — `[[slug]]` resolves here. Make it specific enough to be unambiguous: prefer `refund-authorization` over `refund`, `event-sourcing-write-read-decoupling` over `event-sourcing`.

**Body structure:**
```
<First sentence: the claim or definition. One sentence, present tense.>

<Context, evidence, nuance. 1–4 sentences. Prose only — no bullets, no headers.>

parent: [[parent-note]]
[[related-1]] [[related-2]]
```

**Constraints:**
- 150 words max — if it needs more, it's two notes
- At least one `[[wikilink]]` to an existing note
- `parent:` line only when this note branches from or continues another — the Folgezettel link
- No markdown headers (`#`) — the filename is the title
- No bullet points; no code blocks unless the code IS the claim

**Folgezettel:** A note that refines, qualifies, or branches from another ends with
`parent: [[parent-slug]]`. This is the only structural link that expresses sequencing;
all other connections are flat wikilinks.

**Example:**
```
Refund authorization is the merchant-initiated approval that releases funds back to
a customer once the refund request passes internal validation. It is distinct from a
chargeback, which is bank-initiated and contested rather than agreed. The authorization
step is what triggers the actual funds movement in the payment processor.

parent: [[payment-lifecycle]]
[[chargeback]] [[funds-settlement]]
```

---

## Issue

**Location:** `~/engineering/issues/NNN-<slug>.md`

**ID format:** 3-digit integer, zero-padded (`007`, `042`).

**type values:** `implementation` | `bug` | `investigation`

**Body structure:**
```markdown
---
id: "NNN"
title: "<Short problem or objective statement>"
type: implementation
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## Objective
One sentence. What done looks like.

## Context
What situation or observation created this issue. 2–4 sentences.

## Scope
**In:** what will be touched
**Off-limits:** what will not change and why

## Scenarios
- S1. Given ... When ... Then ...

## Open questions
- [ ] ?
```

**For type: bug** — replace Scenarios with:
```markdown
## Reproduction
Steps to reproduce:
1. {step}

**Expected:** {what should happen}
**Actual:** {what happens instead}

## Root Cause
Hypothesis or confirmed cause.

## Acceptance Criteria
- [ ] Reproduction steps no longer exhibit the broken behavior
```

**For type: investigation** — replace Scenarios with:
```markdown
## Questions
- Q1: {specific unknown} → Confirming: {signal} | Falsifying: {signal}

## Method
How to investigate and what each approach will reveal.

## Done when
Conditions that close this issue.
```

---

## Spike

**Location:** `~/engineering/spikes/NNN-<slug>.md`

**ID format:** 3-digit integer, zero-padded

**Body structure:**
```markdown
---
id: "NNN"
central_question: "<The specific unknown being investigated>"
repo: "<repo path or name>"
status: resolved | inconclusive | deferred
created: YYYY-MM-DD
---

## Answer
One sentence summary of the conclusion.

## Findings
What was discovered.

## Links
- issues/NNN-related-issue.md
- [[note-produced-by-spike]]
```
