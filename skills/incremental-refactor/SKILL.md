---
name: incremental-refactor
description: >
  Apply safe, incremental refactoring using tiny steps and the flocking rules to discover
  abstractions organically. Use this skill whenever the user wants to clean up code, remove
  duplication, extract a concept, rename something, or improve structure — without changing
  behavior. Trigger on phrases like "refactor this", "clean this up", "this feels wrong",
  "there's duplication here", "extract this", "rename this", "this is hard to read", or
  when code has obvious structural problems. Do NOT make large sweeping changes; every step
  must keep tests green.
---

# Incremental Refactoring

## Core idea

Refactoring is **changing structure without changing behavior**. The safety net is your
test suite. If tests aren't green before you start, fix that first.

Take the smallest possible step. Run tests. Repeat.

---

## The discipline

**One change at a time.** Not "one commit at a time" — one *logical change* at a time.

After every single change:
1. Run the tests
2. If green → continue
3. If red → undo the change, understand why, try differently

Never accumulate multiple untested changes. If you're unsure whether a change is safe,
make it smaller.

---

## The Flocking Rules

Use these three rules to organically discover abstractions from duplication:

1. **Find the things that are most alike**
   Look for code that does similar things — similar structure, similar shape, similar intent.

2. **Find the smallest difference between them**
   Don't look at everything at once. Find one single thing that differs.

3. **Make the simplest change to remove that difference**
   Make them identical in that one way. Don't jump to the final abstraction.

Repeat until the duplication is obvious enough to extract cleanly.

> The flocking rules are iterative. You won't see the right abstraction on the first pass.
> Trust the process.

---

## Common safe refactoring moves

Each of these is a single step:

| Move | Safe when |
|---|---|
| Rename variable/function | Tests still pass after rename |
| Extract variable | Behavior is identical, name is more expressive |
| Extract function | New function does exactly what the old code did |
| Inline function | Function is called once or its name doesn't add clarity |
| Move function | Cohesion improves, no circular dependencies introduced |
| Replace magic value with named constant | All uses updated |

---

## What to avoid

- **Big refactors**: rewriting multiple things at once
- **Refactor + feature**: mixing structural change with behavior change in the same step
- **Speculative abstraction**: extracting a pattern you "think" you'll need
- **Untested refactoring**: changing code that has no tests (fix the coverage gap first, or use approval/characterization tests)

---

## When you have no tests

If the code to be refactored has no tests:

1. Write a **characterization test** first — a test that captures the current behavior, whatever it is
2. Use it as your safety net
3. Then refactor

Do not refactor untested code without a safety net.

---

## Signals to watch for

Trigger this skill when:

- User says "refactor", "clean up", "extract", "remove duplication"
- User shows code with obvious copy-paste duplication
- User says "this feels wrong" or "this is hard to understand"
- User wants to rename or reorganize without changing behavior
- Code review identified structural issues to address
