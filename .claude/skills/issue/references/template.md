# Issue Template

```markdown
---
id: "{id}"
title: "{title}"
type: implementation   # implementation | investigation
created: {today}
updated: {today}
---

## Objective
One sentence. What done looks like.

## Scenarios
- S1. Given ... When ... Then ...        # implementation: BDD
- S2. ...                                # investigation: Question ... → Expected finding ...

## Off-limits
What will not be touched and why.

## Facts
Facts this issue relies on or established (see the `fact` skill):
- FACT-NNN — why it matters here

## Context
Background, links, constraints, prior decisions.
Paste any relevant design-constraints block here.

## Tasks
- [ ] S1, S2 — label
- [ ] S3 — label

## Open questions
- [ ] ?

```

## Field notes

**type** — `implementation` (code to build; `tdd` implements the BDD scenarios) or
`investigation` (a question to answer; `dead-reckoning` is the engine; the durable
answers become facts via the `fact` skill). Default `implementation`.

**Scenarios** — co-authored with the issue skill. Each `Sn` maps to one or more tasks.
Rejected proposals during co-authoring become Off-limits entries. On an investigation
issue, a scenario is a question plus the finding that would settle it.

**Facts** — the fact base link. Each `FACT-NNN` listed here must list this issue back
in its own `## Issues` section (bidirectional — see the `fact` skill).

**Tasks** — derived from scenario groupings, not written independently. Each task
references its scenarios so the TDD skill knows what to implement.

**An issue is active** when it exists in `~/engineering/issues/` (or the `issues=`
path in `.skills/config`). Archive when all tasks are complete — that is the human's
action, not the agent's. Facts, by contrast, are durable and are not archived.
