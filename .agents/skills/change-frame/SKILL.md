---
name: change-frame
description: Align the before/after causal model of a behavior change with the user before any code is written. Output is a short frame, not a spec or code.
---

# Change Frame

Align on the model, not on text. Read the relevant source first. Reflect back what it does
today and what the user wants (`Today X does Y (foo.clj:42). You want Z?`). Iterate until
the user confirms the BEFORE → AFTER of the regions that change. Then emit the frame and
stop: no tests, no code.

Tag each model line `verified` (cited in source) or `inferred`. Every GOAL must be
testable and every INVARIANT assertable; anything unverifiable becomes a DRAGON. One
sentence of GOAL, only lines that change, about 15 lines total. If it is bigger, split it.

```
GOAL (verifiable):
  <what becomes true that wasn't>

MODEL  BEFORE → AFTER
  <actor/concept>: <current role> → <new role>  (evidence | `inferred`)

INVARIANTS:
  - <what must not break>

OUT OF SCOPE:
  - <what must not be touched>

DRAGONS (unknowns → spike):
  - <what we don't know>
```

If implementation disproves the frame, do not edit it in place. Re-emit it:
`frame v1 assumed X; spike Y refuted it; frame v2`.
