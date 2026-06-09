---
name: design-constraints
description: >
  Produces named constraint blocks for an issue's `## Context` section. Two modes —
  `evolutionary` (greenfield, tracer-bullet) and `refactor` (behavior-preserving
  incremental change).
---

# Design Constraints

Read [references/guide.md](references/guide.md) for slice definition, violation signals,
flocking rules, safe moves, and characterization test guidance.

Two modes. Each emits a constraint block to paste into the issue's `## Context`
section. Once placed, `tdd` implements the scenarios under those constraints.

| Mode | When | Block name |
|---|---|---|
| `evolutionary` | New feature, module, or integration | `## Design constraints — evolutionary design` |
| `refactor` | Restructuring without changing behavior | `## Design constraints — incremental refactoring` |

---

## Mode: evolutionary

```
## Design constraints — evolutionary design

- First deliverable: thinnest vertical slice through all layers.
  One real behavior, end-to-end. Nothing more.
- Do not build utilities, helpers, or infrastructure before behavior exists.
- Do not extract abstractions until two concrete cases exist.
- Hardcode values if they unblock the slice — generalize only when forced by
  a second case.
- Each subsequent task extends the existing path. It does not replace it.
- Skip edge cases, validation, and error handling in the first slice unless
  they block the slice from running at all.
```

---

## Mode: refactor

```
## Design constraints — incremental refactoring

- Tests must be green before the first change. If they aren't, stop and report.
- One logical change at a time. Run tests after each change.
- If tests go red: undo the last change immediately. Understand why. Try smaller.
- Do not mix refactoring with behavior changes in the same task.
- Do not extract an abstraction until the duplication is obvious.
  Apply the flocking rules: find the most alike things, find the smallest difference,
  make the simplest change to remove that difference. Repeat.
- Do not refactor code that has no tests. Write a characterization test first.
- No speculative abstractions — only extract what two or more concrete cases demand.
```
