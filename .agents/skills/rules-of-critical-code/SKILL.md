---
name: rules-of-critical-code
description: Apply language-independent safety, boundedness, failure-handling, and clarity rules when changing code in critical systems.
---

# Rules of critical code

1. Prefer direct, legible control and data flow. Add indirection only when it makes an invariant, policy, or boundary clearer.
2. Make termination and resource bounds evident for iteration, recursion, retries, queues, batches, concurrency, input sizes, and I/O. Make intentionally unbounded processes explicit and define how they stop.
3. Distinguish invariant violations from expected domain or operational failures. Fail loudly on broken invariants; represent and propagate expected failures. Never silently discard failure.
4. Validate untrusted data at trust, persistence, and serialization boundaries. Assert important internal assumptions and enforce critical invariants at the authoritative layer.
5. State invariants positively. Make valid states, invalid states, and fallback paths legible; avoid dense conditions that obscure the decision structure.
6. Separate decisions and transformations from effects. Keep state changes and external interactions localized, and avoid duplicated state that can drift.
7. Keep values close to where they are created, validated, and consumed. Make ownership, lifetime, and synchronization explicit when they are not locally evident.
8. Use domain-precise representations. Keep indexes, counts, sizes, durations, offsets, identifiers, and monetary values distinct. Make units, precision, overflow, division, and rounding semantics explicit where relevant.
9. Follow the host language’s naming and API conventions, while making domain meaning, units, optionality, and qualifiers unambiguous.
10. Keep functions and data transformations small enough to reason about locally. Extract coherent policy or computation, not fragments created only to satisfy a size limit.
11. At integration points, choose correctness-relevant behavior explicitly: timeouts, retries, consistency, durability, ordering, batching, backpressure, and library defaults.
12. Make transaction boundaries, state transitions, concurrency assumptions, and idempotency guarantees explicit wherever correctness depends on them.
13. Consider network, storage, memory, and CPU costs during design. Estimate before optimizing and amortize expensive work when practical.
14. Add dependencies and tooling only when their continuing operational and cognitive cost is justified by a material benefit.
15. Explain non-obvious intent, trade-offs, and safety constraints. Do not use comments to narrate the code.
