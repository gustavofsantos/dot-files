# Issue Template — Bug

```markdown
---
id: "{id}"
title: "{title}"
type: bug
created: {today}
updated: {today}
---

## Objective
One sentence: what broken behavior needs to be corrected.

## Reproduction
Steps to reproduce reliably:
1. {step}
2. {step}

**Expected:** {what should happen}
**Actual:** {what happens instead}
**Frequency:** always / intermittent / rare

## Root Cause
{hypothesis or confirmed cause — leave blank if unknown}

## Fix Scope
What will be changed:
- {file or area}

## Off-limits
What must not change (to avoid regressions or scope creep).

## Acceptance Criteria
- [ ] Reproduction steps no longer exhibit the broken behavior
- [ ] {regression guard}

## Facts
Facts this issue relies on (see the `fact` skill):
- FACT-NNN — why it matters here

## Context
Environment, version, logs, prior attempts.
```
