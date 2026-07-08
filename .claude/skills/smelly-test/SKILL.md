---
name: smelly-test
description: Steer test-writing toward tests that document and enforce business behavior. Use whenever writing new tests, reviewing tests, or changing business logic (domain rules, invariants, calculations, state transitions, validation). Trigger even on a bare "add a test" or "make sure this works" — the steer is that each test names the invariant it protects and reads as a rule a domain expert would recognize, not a mirror of the implementation. Skip for pure test plumbing (fixtures, CI, mocking setup) with no behavioral assertion.
---

# Smelly Test

You already know how to write tests. This skill only redirects the *target*: make each test document and enforce a **business promise**, so the suite reads as a spec and goes red when a promise breaks — not as a mirror of the code that passes while documenting nothing.

Apply one filter to every test: **does this protect a promise the business is making?** If yes, make it read like one.

## The steer

**Name the rule, not the method.** The test name is a sentence about the domain. If you can derive it from the method signature, rewrite it from the requirement.
`testCalculateInterest` → `interestAccruesDailyOnOutstandingPrincipal`

**One promise per test, asserted on the domain.** Split bundled checks so a failure names *which* rule broke. Assert on the domain concept (`isOverdrawn()`), not the internal field or the recomputed formula (`balance < 0`, `price * 1.08`).

**Put the deciding fact in plain sight.** The value that makes the case meaningful — the boundary number, the just-past-the-window date — goes in the test body, not a builder default. A domain expert should read the body and recognize the rule.

## Reviewing

Scan for the gap that matters most: a rule enforced in the code but named in **no** test. That invariant is unenforced — delete the guard and the suite stays green. Read the logic, list its rules, check each against the test names, add the missing ones.

For the catalogue of smells with before/after rewrites, see `references/smells.md`.
