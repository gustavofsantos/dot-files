---
name: pre-mortem
description: Before implementing a non-trivial solution — assume it already failed, enumerate and score failure modes, mitigate the top ones before writing code.
disable-model-invocation: true
---

# Pre-Mortem

Before implementing a non-trivial solution, project into a future where it has **already failed**, work backward to the causes, and mitigate them before writing code.

## Procedure

1. **Goal** — state it in one sentence; name what success looks like and how you'd measure it.
2. **Assume failure** — "It's 4 weeks out. This failed." Don't ask *if* it might; assume it did.
3. **Enumerate ≥5 specific failure modes** across: technical (races, edge cases, perf cliffs, wrong abstractions), behavioral (misread requirements/assumptions), operational (deploy, observability, rollback), integration (broken upstream/downstream contracts), time (scope creep, underestimation, missing deps).
4. **Score** each by likelihood × impact; focus on high/high.
5. **Mitigate** each top item with one concrete action — a design change, an upfront test, a guard/constraint, or a question to answer first.
6. **Pre-flight** — top 2–3 modes have a mitigation, blocking unknowns are assigned, a rollback/recovery path exists.

## Output

```
## Pre-Mortem: <name>
**Goal:** <one sentence>
**Top failure modes:**
| Failure mode | Likelihood | Impact | Mitigation |
|---|---|---|---|
**Blockers to resolve before coding:**
**Rollback plan:**
```

## Feeding back

If tracked as an issue (`issue` skill): unresolved blockers → `## Open questions`; approach-constraining mitigations → `## Context`; must-not-break modes → `## Off-limits`.
