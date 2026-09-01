---
name: smelly-test
description: Make tests state business promises through domain-facing names, assertions, and visible deciding facts.
disable-model-invocation: true
---

# Smelly Test

You already know how to write tests. This skill only redirects the *target*. Make each test document and enforce a **business promise**. The suite then reads as a spec and goes red when a promise breaks. It does not mirror the code, passing while it documents nothing.

Apply one filter to every test: **does this protect a promise the business is making?** If yes, make it read like one.

## The steer

**Name the rule, not the method.** The test name is a sentence about the domain. If you can derive it from the method signature, rewrite it from the requirement.

Prefer a **natural-language string** that reads like a spec sentence — lowercase, no camelCase, punctuation only when it helps clarity:

`"interest accrues daily on outstanding principal"`

Use **camelCase as an identifier** only in two cases. The first is when the framework or convention requires it, as with JUnit method names. The second is when no string name is available. Even then, the identifier should still read as a domain sentence, not a method mirror:

`testCalculateInterest` → `"interest accrues daily on outstanding principal"` (preferred) or `interestAccruesDailyOnOutstandingPrincipal` (fallback)

**One promise per test, asserted on the domain.** Split bundled checks so a failure names *which* rule broke. Assert on the domain concept (`isOverdrawn()`), not the internal field or the recomputed formula (`balance < 0`, `price * 1.08`).

**Put the deciding fact in plain sight.** The value that makes the case meaningful — the boundary number, the just-past-the-window date — goes in the test body, not a builder default. A domain expert should read the body and recognize the rule.

## Reviewing

Scan for the gap that matters most: a rule enforced in the code but named in **no** test. That invariant is unenforced — delete the guard and the suite stays green. Read the logic, list its rules, check each against the test names, add the missing ones.

For the catalogue of smells with before/after rewrites, see `references/smells.md`.
