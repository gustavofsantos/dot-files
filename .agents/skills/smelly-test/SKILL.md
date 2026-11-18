---
name: smelly-test
description: Make tests state business promises through domain-facing names, assertions, and visible deciding facts.
disable-model-invocation: true
---

# Smelly Test

Make each test state and enforce one business promise.

- Name the rule, not the method. Prefer a lowercase spec-sentence string
  (`"interest accrues daily on outstanding principal"`). Use a camelCase domain sentence only
  when the framework requires identifiers.
- Assert one promise per test on the domain concept (`isOverdrawn()`), not on internals or a
  recomputed formula (`price * 1.08`). State the literal (`108.00`).
- Take the rule and its words from the domain, not from the code. Use the canonical names from `vocabulary`; when no source gives the business name, ask the user.
- Put the deciding fact, such as the boundary value or the just-expired date, in the test
  body, not in a builder default.

When reviewing, look first for a rule that the code enforces but no test names. Take the rules to check against from the task, the project brief, and `workflows/`.
