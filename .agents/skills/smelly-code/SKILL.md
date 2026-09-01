---
name: smelly-code
description: Make production-code intent visible through named decisions, clear ownership, and consistent abstraction levels.
disable-model-invocation: true
---

# Smelly Code

You already know how to write code. This skill only redirects the *target*. Make production code **read as intention**. The next reader then sees what the system means. They do not see a sequence of mechanics to reverse-engineer into a policy.

Apply one filter to every unit of production code: **must the reader reconstruct the idea from expressions, getters, and layer-crossing branches?** If yes, name it and put it where it belongs until the idea is visible in one place.

Scope is **production code only**. For tests, use `smelly-test`.

## The steer

**Name the condition, not the expression.** A boolean that takes a breath to read aloud is a missing concept. Extract a predicate, explaining variable, or domain method whose name *is* the rule (`overdrawn?`, `withinReturnWindow`, `eligibleForLoyalty`). Inline `a && !b || c` is policy the codebase never got to discuss.

**Keep decisions close to their knowledge.** Put a decision near the data and invariants it
needs. Avoid getter-driven decisions that expose foreign structure and scatter one rule
across callers. The right home can be an object, function, module, service, query boundary,
or another local abstraction that makes the rule visible.

**Name policy at the persistence boundary.** SQL and persistence can execute business rules
when correctness, atomicity, data volume, or performance requires it. Keep the domain intent
named and visible at the boundary. Do not bury eligibility, pricing, or workflow policy in an
anonymous predicate or generic repository method.

**One abstraction level per function.** A function that mixes "why we do this" with "how the bytes move" forces the reader to hold both. Extract until each function is either orchestration (named steps) or a single concrete step — not a nest of both.

## Reviewing

Scan for the gap that matters most. Look for an unnamed condition or a decision far from its
knowledge. Look for anonymous policy in persistence, mixed abstraction levels, or comments
that narrate mechanics. Ask what a colleague would call the idea. If the code has no such
name, the intent is fragile.

For the catalogue of smells with before/after rewrites, see `references/smells.md`.
