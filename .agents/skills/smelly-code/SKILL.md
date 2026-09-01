---
name: smelly-code
description: Steer production code toward classical readability — name conditions, tell don't ask, keep policy out of persistence, one abstraction level per function. Use whenever writing or reviewing production code (services, domain, handlers, repositories, jobs). Trigger even on a bare "implement this", "clean this up", or "refactor" — the steer is that a reader should see intention without reconstructing it from control flow and layer leaks. Pairs with smelly-test where smelly-code makes the production code readable. Smelly-test makes the promise enforceable. Skip for test code (use smelly-test) and for pure wiring with no decision inside.
disable-model-invocation: true
---

# Smelly Code

You already know how to write code. This skill only redirects the *target*. Make production code **read as intention**. The next reader then sees what the system means. They do not see a sequence of mechanics to reverse-engineer into a policy.

Apply one filter to every unit of production code: **must the reader reconstruct the idea from expressions, getters, and layer-crossing branches?** If yes, name it and put it where it belongs until the idea is visible in one place.

Scope is **production code only**. For tests, use `smelly-test`.

## The steer

**Name the condition, not the expression.** A boolean that takes a breath to read aloud is a missing concept. Extract a predicate, explaining variable, or domain method whose name *is* the rule (`overdrawn?`, `withinReturnWindow`, `eligibleForLoyalty`). Inline `a && !b || c` is policy the codebase never got to discuss.

**Tell, don't ask.** Do not pull an object's guts out, decide elsewhere, then push a result back. Ask the object that owns the data to do the work (`order.refund()`), not `if (order.getStatus() == PAID && order.getDays() <= 30) order.setStatus(REFUNDED)`. Feature envy and getter chains are the same smell: the decision lives away from the knowledge.

**Keep policy out of the infrastructure.** Repositories, queries, SQL/`where` clauses, and adapters load and store — they do not decide eligibility, pricing, or workflow. A conditional that encodes a business rule inside a database layer belongs in the domain/service. The persistence code receives an already-decided criterion or writes an already-decided state.

**One abstraction level per function.** A function that mixes "why we do this" with "how the bytes move" forces the reader to hold both. Extract until each function is either orchestration (named steps) or a single concrete step — not a nest of both.

## Reviewing

Scan for the gap that matters most. It is a place where meaning exists only as an accident of arrangement. Look for an unnamed compound boolean, or a caller that interrogates another object's fields. Look also for a business `if` inside a query builder, or a comment that narrates the next five lines. Read those spots and ask what a colleague would *call* that idea. If the name is not in the code, the next change will break the idea silently while leaving the mechanics looking fine.

For the catalogue of smells with before/after rewrites, see `references/smells.md`.
