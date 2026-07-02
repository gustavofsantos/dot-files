# Issue templates

## Frontmatter (all types)

```yaml
---
id: "NNN"
title: "Short imperative title"
type: implementation        # implementation | bug | investigation | prototype | characterization
status: inbox               # inbox | ready | active | blocked | review | done
priority: medium            # high | medium | low
tags: []
repo: ""                    # /abs/path to git repo — fill before status: ready
intent: ""                  # throwaway | promote — required when type: prototype
target: ""                  # module, function, or service — required when type: characterization
created: YYYY-MM-DD
updated: YYYY-MM-DD
# workflow-managed — do not edit
branch: ""
worktree: ""
pr: ""
---
```

Status lifecycle: `inbox → ready → active → blocked → active → review → done`

Only `inbox` and `ready` are human-set initially. `repo:` must be set before `status: ready`.

## Body: implementation

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
```

Tasks rules: one action per checkbox, ordered, each completable in one agent turn.

## Body: bug

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

## Body: investigation

```markdown
## Objective
One sentence. What answering this unlocks.

## Context
What prompted the investigation. 2–4 sentences.

## Questions
- Q1: {specific unknown} → Confirming: {signal} | Falsifying: {signal}

## Method
How to investigate and what each approach will reveal.

> **Optional pre-step — scratch refactoring:** if the code is illegible, do an aggressive throwaway refactor on a temp branch to understand it before investigating. Nothing is committed. The branch may be preserved as a readable reference but is never merged.

## Tasks
- [ ] Answer Q1
- [ ] Write a spike or note with findings
```

## Body: prototype

> **Done when:** `## Decision` is filled. A merged PR is NOT required.
> `intent: throwaway` means the prototype is discarded after Decision; `intent: promote` means it may become a real implementation issue.

```markdown
## Objective
One sentence. What this prototype is meant to learn or validate.

## Hypothesis
The specific belief being tested. What would confirm it, what would falsify it.

## Scope
**In:** what will be built or tried
**Off-limits:** what will not be touched so the prototype stays throwaway

## Tasks
- [ ] First task, present tense imperative
- [ ] Second task

## Findings
_(filled during execution — do not pre-populate)_

## Decision
_(filled after evaluation — do not pre-populate)_
Outcome: promote | discard
Rationale: {one paragraph}
```

## Body: characterization

> **Done when:** all tasks checked, `## Behaviors Captured` filled, and tests passing in CI.

```markdown
## Objective
One sentence. What understanding this characterization produces.

## Target
{module, function, or service being characterized} — `target:` frontmatter must match.

## Tasks
- [ ] First task, present tense imperative
- [ ] Second task

## Behaviors Captured
_(filled during execution — do not pre-populate)_
```

## Sections added during execution (do not pre-populate)

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
