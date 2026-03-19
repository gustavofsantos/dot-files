---
name: evolutionary-design
description: >
  Apply evolutionary design and tracer bullet tactics when building new features or systems.
  Use this skill whenever the user is starting a new feature, a new module, a new integration,
  or any greenfield work — even if they don't say "tracer bullet" explicitly. Also trigger when
  the user says things like "where do I start", "how should I structure this", "let's build X",
  or "I need to add Y to the system". Do NOT design everything upfront; instead, grow the
  solution incrementally from a working primitive.
---

# Evolutionary Design / Tracer Bullet

## Core idea

Don't design the full system upfront. Build a **primitive whole** — the thinnest possible
vertical slice that integrates all major parts and delivers a tiny piece of real value. Then
grow it based on actual feedback.

A tracer bullet is not a prototype. It is **production code** that is deliberately incomplete.
It lives in the codebase, runs through all layers (UI → logic → persistence or equivalent),
and proves the path works end-to-end.

---

## Process

### 1. Identify the vertical slice

Before writing any code, ask:

- What is the smallest interaction that would touch all major layers of this feature?
- What would make this "real" even if it only does one thing?

Do not start with utilities, helpers, or infrastructure. Start with the behavior.

### 2. Build the primitive whole

Write just enough to make the slice work:

- Skip edge cases
- Skip validation
- Skip error handling (unless it blocks the slice from running)
- Use hardcoded values if it helps move faster

The goal is: **something real runs end-to-end**.

### 3. Verify it before expanding

Run the tests (or demo the behavior manually). Confirm the path works.
Only then add the next slice.

### 4. Grow by adding slices

Each new slice should:
- Extend the existing path, not replace it
- Add one behavior at a time
- Keep all previous slices working

---

## What to avoid

- **Big bang design**: designing all components before writing any code
- **Bottom-up building**: building infrastructure before behavior
- **Branching too early**: creating abstractions before you have 2–3 concrete cases

---

## Signals to watch for

Trigger this skill when you see:

- "Let's create a new feature/module/service"
- "How should I start building X?"
- "We need to integrate A with B"
- "I'm not sure where to begin"
- Any greenfield work in an existing codebase

---

## Output format

When applying this skill, produce:

1. **Slice definition**: one sentence describing the primitive whole
2. **Layer map**: which layers the slice will touch
3. **First task**: the first concrete file/function to write
4. **Expand plan**: ordered list of the next 2–3 slices after the first works
