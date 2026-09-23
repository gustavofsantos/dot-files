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
- Put the deciding fact, such as the boundary value or the just-expired date, in the test
  body, not in a builder default.

When reviewing, look first for a rule that the code enforces but no test names.
