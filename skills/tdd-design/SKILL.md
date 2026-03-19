---
name: tdd-design
description: >
  Drive implementation using Test-Driven Development as a design tool, not just a testing
  strategy. Use this skill whenever the user is about to write new production code, implement
  a function, add a behavior, or fix a bug with a reproducible case. Trigger on phrases like
  "implement X", "add behavior Y", "write the function that...", "make this work", or when
  the user jumps straight to writing implementation code. Also trigger if the user writes
  code without a failing test first. This skill enforces the red-green-refactor cycle and
  uses test friction as a design signal.
---

# TDD as Design Tool

## Core idea

Write the test first. Not as a formality — as a **design act**.

If a test is hard to write, the design is wrong. Test friction is not an inconvenience;
it is information. Use it.

---

## The cycle

```
RED → GREEN → REFACTOR
```

Each step has a strict contract:

### RED: Write a failing test

- Write **one** test for the next behavior
- The test must fail for the right reason (not compile errors, not setup failures)
- Do not write more than one failing test at a time

Ask before writing: *What is the simplest behavior I need to add next?*

### GREEN: Make it pass — nothing more

- Write the minimum code to pass the test
- Do not add behavior that isn't tested
- Do not clean up yet — that comes in refactor
- Hardcoding the return value is valid if it makes the test pass

### REFACTOR: Improve structure, keep tests green

- Run tests after every change
- If a test breaks, undo the last change
- Do not add behavior during refactor

---

## TDD as design signal

| Symptom during TDD | Design problem |
|---|---|
| Hard to instantiate the subject | Too many dependencies |
| Test needs to know internal state | Missing abstraction |
| Need to mock many things | High coupling |
| Test setup is longer than the assertion | Wrong responsibility boundary |
| Can't test without side effects | Logic mixed with I/O |

When you hit friction, **stop and redesign** before continuing.

---

## Sequencing behaviors

Before starting a new feature with TDD, list the behaviors in order from simplest to most
complex. Start with the degenerate case (empty input, zero, null, single item).

Example order for a filtering function:
1. Returns empty when input is empty
2. Returns all items when no filter matches
3. Returns matching items
4. Handles multiple matching items

---

## What to avoid

- Writing tests after the code ("test-after" is not TDD)
- Writing multiple failing tests at once
- Skipping the refactor step
- Using TDD only for unit tests — apply it at any level where behavior is being added

---

## Signals to watch for

Trigger this skill when:

- User is about to write a new function or class
- User says "implement", "write", "add", "create" anything behavioral
- User writes code without mentioning tests
- User has a failing test and asks "how do I make this pass"
