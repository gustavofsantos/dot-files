---
name: rules-of-refactoring
description: After green tests and a behavior commit, flock alike code into a separate refactor commit
disable-model-invocation: true
---

# Way of refactoring — flock after green, commit separately

After an agent turn that makes tests **green**, do **not** fold structural cleanup into the behavior change. Commit the behavior first, then refactor under a closed scope, then land a separate `refactor:` commit.

## Gate (all required)

1. Relevant tests are green.
2. The behavior (or slice) change is **already committed** on the branch.
3. Working tree is clean except for the intentional refactor edits you are about to make.
4. User has not asked to skip refactoring or to stop after the behavior commit.

If the behavior is not committed yet: commit it first, then start this pass.

## Flocking Rules

Repeat until the next difference is no longer worth removing, or would invent a speculative abstraction:

1. **Select the things that are most alike.**
2. **Find the smallest difference between them.**
3. **Make the simplest change that will remove that difference.**

Structures and names should **emerge** from removing differences — do not design the abstraction up front and rearrange code to fit it.

## Closed scope

- Prefer alike things **inside the files / paths touched by the just-committed change** (and their direct callers/callees if needed to complete one flocking step).
- Do not open a repo-wide cleanup, rename campaign, or unrelated module rewrite.
- Do not change behavior, public contracts, or tests' asserted outcomes — only shape. If a test must change, you left the refactor lane. Stop and treat it as a new behavior turn.
- Keep tests green after every flocking step. If red, revert the step and pick a smaller difference.

## Commit

When the flocking pass is done (or the user stops you):

- Commit **only** the refactor diff.
- Message type **`refactor:`** (Conventional Commits). If a Jira key is known from the branch / change, use `refactor(<JIRA>): …`.
- Do **not** amend the prior behavior commit. Do **not** mix feat/fix/test edits into the refactor commit.

## Avoid

- Refactoring while still red, or before the behavior commit exists.
- “While I’m here” drive-bys outside the alike set.
- Introducing a new name/type “for clarity” before two concrete alike sites forced it (see also spend / vertical-slice bias).
- A single giant rewrite instead of repeated smallest-difference steps.
