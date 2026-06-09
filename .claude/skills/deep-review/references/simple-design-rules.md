# Kent Beck — Simple Design Rules

Applied in strict priority order — no gain from a lower rule justifies degrading a higher one.

1. **Passes all tests** — correctness precedes aesthetics. Reject any refactor that mutates semantics; a well-organized bug is still a bug.
2. **Reveals intention** — names describe domain *what*, not mechanical *how*. Fix clarity before duplication: a confusing-but-DRY codebase is worse than a legible-but-slightly-repetitive one.
3. **No duplication** — one domain concept, one home. But tolerate repetition when unifying it requires an abstraction that obscures intent. Accidental structural similarity ≠ conceptual duplication.
4. **Fewest elements** — once 1–3 hold, delete what doesn't earn its place: lazy classes, speculative generality, single-implementation interfaces. Premature abstraction is paid continuously in cognitive overhead.

**Rule 0 (tie-break):** empathy with future readers wins over any strict metric.
