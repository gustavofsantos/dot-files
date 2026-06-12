---
name: issue
description: >
  Create or update a tracked work item in ~/engineering/issues/. Trigger only on
  explicit intent to file work: "create an issue", "file a bug", "track this as an issue",
  "new story", "new feature", "/issue", or when another skill says to invoke the issue skill.
  Does NOT trigger on casual code discussion that mentions the word "issue".
---

# issue

Create or update tracked work items in `~/engineering/issues/`. Read this before writing.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/issues/ -l 2>/dev/null` — if a similar item exists, update it instead of creating a duplicate.
2. **Allocate ID** — find the next ID:
   ```bash
   ls ~/engineering/issues/ ~/engineering/issues/archive/ 2>/dev/null \
     | grep -oE '^[0-9]+' | sort -n | tail -1
   # increment by 1 and zero-pad to 3 digits
   ```
3. **Choose type** — infer from context; confirm if ambiguous.
4. **Fill missing fields conversationally** — ask only what cannot be inferred.
5. **Write** — follow the contract below exactly.

## File location

`~/engineering/issues/NNN-Title Case.md` — Title Case, spaces, short imperative phrase.

## Frontmatter schema

```yaml
---
id: "NNN"
title: "Short imperative title"
type: implementation        # implementation | bug | investigation
status: inbox               # inbox | ready | active | blocked | review | done
priority: medium            # high | medium | low
tags: []
repo: ""                    # /abs/path to git repo — fill before status: ready
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

## Tasks
- [ ] Answer Q1
- [ ] Write a spike or note with findings
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
