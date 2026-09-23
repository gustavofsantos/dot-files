---
name: smelly-code
description: Make production-code intent visible through named decisions, clear ownership, and consistent abstraction levels.
disable-model-invocation: true
---

# Smelly Code

Make production code read as intention. Name conditions, not expressions. Keep each decision
near the data and invariants it needs, not in getter-driven callers. When persistence runs a
business rule, name the rule at that boundary. Keep one abstraction level per function.
Production code only. Tests belong to `smelly-test`.
