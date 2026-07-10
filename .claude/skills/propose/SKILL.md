---
name: propose
description: >
  Turn an aligned change-frame into an ordered list of failing tests an agent walks
  one-per-turn, stored in ~/Documents/Plans/ so other agents can read, review, and
  execute it. Each step is a test, not a prose task — done means green, not "looks done".
  Trigger on "write a plan", "plan this frame", "/plan", or when change-frame emits a
  frame ready to execute. NOT for design/alignment (that's change-frame) — the frame
  must already exist or be inferable. NOT for capturing a finding (that's spike).
---
# propose

A plan is the executable downstream of a frame: the GOAL, cut into an **ordered list
of failing tests**, each one a single reviewable turn. You are the surveyor, not the
builder — you sequence the tests and stop. The genie walks the list; the human reviews
at each green.

The frame holds the *why* and the *what-must-not-break*. The plan holds only the
*order*. Don't restate the frame — reference it. A plan that re-explains intent has
drifted back into being a spec; the frame already won that argument.

## Golden rule

Every step is a test that can go **red before green**. If a step can't fail, it isn't
a step — it's a wish. A prose task ("implement the consumer") lets the agent rationalize
done; a failing test lets the machine prove it. One test = one turn = one review.

## Loop

1. **Take the frame.** If a change-frame was just emitted, that's the input — GOAL
   becomes the last test, INVARIANTS become guard tests, DRAGONS block steps that
   depend on them. If no frame exists, stop and invoke change-frame first — don't
   plan from an un-aligned model.
2. **Cut the GOAL into an ordered test sequence.** Smallest behavior first, each test
   one assertion of one behavior. Order so every test can go green without breaking a
   prior green. INVARIANTS enter as their own guard tests, early.
3. **Leave the plan.** `scripts/new.sh "<slug>" [frame-ref]` returns the path with
   stamped frontmatter. Fill Frame / Tests. Each test starts `[ ]`.
4. **Hand off and stop.** The plan is for the executing agent, not you. Don't write
   the tests' bodies, don't implement. Emit the ordered list and stop.

## Execution protocol (for the agent that picks this up)

Walk top to bottom. Per turn: take the next `[ ]` test, make it go red, make it green,
change `[ ]` → `[x]`, **stop for review**. One test per turn — never code ahead of the
next unchecked line. A `DRAGON` in the frame blocks any step depending on it until a
spike resolves it.

## Dedup

`rg -il '<term>' ~/Documents/Plans/` first. Same frame → update the plan, don't fork.

## The artifact

```markdown
---
status: open        # open | in-progress | done | superseded
created: <stamped>
frame: <path-or-ref to the change-frame this executes>
---
## Frame
One line: the GOAL from the frame, verbatim. The rest lives in the frame — link it.

## Tests
Ordered. Each `[ ]` is one turn. Smallest behavior first; invariant-guards early.

- [ ] <test name — one behavior, phrased as the assertion it makes>
- [ ] <next>
- [ ] <GOAL as the final test — when this is green, the plan is done>
```
