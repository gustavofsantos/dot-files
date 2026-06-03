---
name: pre-mortem
description: Activate this skill when designing a new feature or system component, proposing a significant refactor, choosing between two or more implementation approaches, estimating effort or timelines, about to write code that touches critical paths (auth, data integrity, payments, etc.)
---

# Pre-Mortem

## Purpose
Before implementing any non-trivial solution, mentally project into the future
where the implementation has already failed. Work backwards to identify the
causes, then proactively mitigate them before writing a line of code.

## When to trigger
Activate this skill when:
- Designing a new feature or system component
- Proposing a significant refactor
- Choosing between two or more implementation approaches
- Estimating effort or timelines
- About to write code that touches critical paths (auth, data integrity, payments, etc.)

## Procedure

### Step 1 — Zoom out (2 min)
State the goal of the implementation in one sentence.
Ask: "What does success look like? How would we measure it?"

### Step 2 — Assume failure
Say: "It is 4 weeks from now. This implementation has failed."
Do NOT ask why it might fail — assume it already has.

### Step 3 — Enumerate failure modes
List at least 5 specific reasons the implementation failed. Think across:
- **Technical**: race conditions, edge cases, performance cliffs, wrong abstractions
- **Behavioral**: misunderstood requirements, wrong assumptions about user/system behavior
- **Operational**: deployment issues, missing observability, rollback difficulty
- **Integration**: broken contracts with upstream/downstream services or clients
- **Time**: scope creep, underestimated complexity, missing dependencies

### Step 4 — Score and prioritize
For each failure mode, estimate:
- **Likelihood**: low / medium / high
- **Impact**: low / medium / high

Focus discussion on HIGH likelihood + HIGH impact items first.

### Step 5 — Define mitigations
For each top-priority failure mode, define one concrete mitigation:
- A design change
- A test to write upfront
- A constraint or guard to add
- A question to answer before proceeding

### Step 6 — Pre-flight checklist
Before moving to implementation, confirm:
- [ ] The top 2-3 failure modes have a mitigation plan
- [ ] Any blocking unknowns are identified and assigned
- [ ] Rollback or recovery path exists if this goes wrong in production

## Output format
Summarize the pre-mortem as:

<template>
## Pre-Mortem: <feature/task name>

**Goal:** <one sentence>

**Top failure modes:**
| Failure mode | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ... | high | high | ... |

**Blockers to resolve before coding:**
- ...

**Rollback plan:**
- ...
</template>

## Handoff map

After the pre-mortem, suggest the next skill explicitly:

- Blocking unknown depends on current system behavior → `dead-reckoning`
- Mitigations should become explicit build constraints → `design-constraints`
- Risks are understood and the work now needs a scoped implementation story → `user-story-builder`
