# Design Constraints — Reference Guide

## Evolutionary

A vertical slice touches every major layer (UI/API → domain → persistence/external call) for *one* real behavior. It is **not**: data layer first then logic then UI; all models before any behavior; infrastructure scaffolded "to support future work." The first slice is deliberately incomplete — its only job is to prove the path.

**Violation signals (redirect to "thinnest slice first"):**
- A module proposed with no behavior yet.
- Abstractions before two concrete cases exist.
- More than one layer built before any layer is exercised.
- "We'll need this later" justifying any code.

## Refactor

**Flocking rules** (the path to an abstraction — discovered, not designed): find the most-alike things → the smallest difference → the simplest change that removes it; repeat until the pattern is obvious enough to name and extract.

**Safe moves** are the standard catalog (rename, extract/inline variable or function, move function, replace magic value) — each safe only while tests stay green and behavior is identical.

**Violation signals (stop, make the change smaller):**
- Multiple structural changes in one task, or behavior change mixed with structural.
- Abstraction extracted before two concrete cases exist.
- Tests skipped "because the refactor is obviously safe."

**No tests?** Write a characterization test capturing current behavior first, use it as the safety net, then refactor. Never refactor untested code without one.
