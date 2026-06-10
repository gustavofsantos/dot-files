# Write contracts

## Note (fact, term, concept — same thing)

**Location:** `~/engineering/Title Case Name.md`

**Filename:** Title Case, spaces. This is the canonical link target — `[[Title Case Name]]` resolves here. Make it specific enough to be unambiguous: prefer `Refund Authorization` over `Refund`, `Event Sourcing Write Read Decoupling` over `Event Sourcing`.

**Body structure:**
```
<First sentence: the claim or definition. One sentence, present tense.>

<Context, evidence, nuance. 1–4 sentences. Prose only — no bullets, no headers.>

Parent: [[Parent Note]]
[[Related One]] [[Related Two]]
```

**Constraints:**
- 150 words max — if it needs more, it's two notes
- At least one `[[wikilink]]` to an existing note
- `Parent:` line only when this note branches from or continues another — the Folgezettel link
- No markdown headers (`#`) — the filename is the title
- No bullet points; no code blocks unless the code IS the claim

**Folgezettel:** A note that refines, qualifies, or branches from another ends with
`Parent: [[Parent Note]]`. This is the only structural link that expresses sequencing;
all other connections are flat wikilinks.

**Example:**
```
Refund authorization is the merchant-initiated approval that releases funds back to
a customer once the refund request passes internal validation. It is distinct from a
chargeback, which is bank-initiated and contested rather than agreed. The authorization
step is what triggers the actual funds movement in the payment processor.

Parent: [[Payment Lifecycle]]
[[Chargeback]] [[Funds Settlement]]
```

---

## Issue

**Location:** `~/engineering/issues/NNN-Title Case.md`

**ID format:** 3-digit integer, zero-padded (`007`, `042`).

### Frontmatter schema

```yaml
---
id: "013"
title: "Short imperative title"
type: implementation        # implementation | bug | investigation
status: inbox               # inbox | ready | active | blocked | review | done
priority: medium            # high | medium | low
tags: []
repo: ""                    # /abs/path to git repo — required before status: ready
created: YYYY-MM-DD
updated: YYYY-MM-DD
# workflow-managed — do not edit
branch: ""
worktree: ""
pr: ""
---
```

**Human-set fields:**

| Field | Values | Notes |
|-------|--------|-------|
| `id` | `"NNN"` | 3-digit zero-padded string |
| `title` | string | Short imperative phrase |
| `type` | `implementation` · `bug` · `investigation` | |
| `status` | see below | Only `inbox` and `ready` are human-set initially |
| `priority` | `high` · `medium` · `low` | Used by issue-worker to order the queue |
| `tags` | list | Domain labels for search |
| `repo` | abs path | Fill before setting `status: ready` |
| `created` / `updated` | `YYYY-MM-DD` | |

**Status lifecycle:**

```
inbox → ready → active → blocked → active → review → done
```

| Status | Who sets it | Meaning |
|--------|-------------|---------|
| `inbox` | human | Captured, not yet ready to work |
| `ready` | human | Queued for issue-worker; `repo:` must be set |
| `active` | workflow | Being worked on |
| `blocked` | workflow | Needs human input — see `## Blocked` section |
| `review` | workflow | PR opened — see `pr:` field |
| `done` | human | Merged and closed |

**Workflow-managed fields** (do not edit manually):

| Field | Set when |
|-------|----------|
| `branch` | worktree created |
| `worktree` | worktree created |
| `pr` | PR opened |

### Body: implementation

```markdown
## Objective
One sentence. What done looks like.

## Context
What situation or observation created this issue. 2–4 sentences.

## Scope
**In:** bullet list of what will be touched
**Off-limits:** what will not change and why

## Tasks
- [ ] First task, present tense imperative
- [ ] Second task
- [ ] Third task
```

**Tasks rules:**
- One action per checkbox
- Order matters — tasks are executed sequentially by issue-worker
- Each task should be completable in one agent turn
- No `Task N:` prefix — the checkbox text is the identifier

### Body: bug

```markdown
## Objective
One sentence. What correct behavior looks like once fixed.

## Context
What situation surfaced this bug. 2–4 sentences.

## Reproduction
1. Step one
2. Step two

**Expected:** what should happen
**Actual:** what happens instead

## Root Cause
Hypothesis or confirmed cause. Update once known.

## Tasks
- [ ] Write a failing test reproducing the bug
- [ ] Fix the implementation
- [ ] Confirm the test passes and no regressions
```

### Body: investigation

```markdown
## Objective
One sentence. What answering this unlocks.

## Context
What prompted the investigation. 2–4 sentences.

## Questions
- Q1: {specific unknown} → Confirming: {signal} | Falsifying: {signal}

## Method
How to investigate and what each approach will reveal.

## Tasks
- [ ] Answer Q1
- [ ] Write a spike or note with findings
```

### Sections added during execution

These sections are added by the workflow or by you after the fact — do not pre-populate them:

```markdown
## Blocked
### Needs input
{precise question or decision the agent cannot make alone}

## Resolution
PR: {url}
{one-paragraph summary of what was done}

## Open questions
- [ ] {any remaining questions after closing}
```

---

## Spike

**Location:** `~/engineering/spikes/NNN-Title Case.md`

**ID format:** 3-digit integer, zero-padded.

```yaml
---
id: "NNN"
title: "Question being investigated"
status: resolved             # resolved | inconclusive | deferred
created: YYYY-MM-DD
related-issue: "NNN"         # optional
---
```

**Body:**
```markdown
## Question
The question the spike is intended to answer.

## Context
What prompted this spike. 2–4 sentences.

## Answer
One sentence summary of the conclusion.

## Evidence
What was discovered. Prose. Link to files, commits, or docs.

## Links
- issues/NNN-Related Issue.md
- [[Note Produced By Spike]]
```
