# FP Evaluation Criteria

- **Purity** — flag functions that read global/external state, mutate arguments, or produce effects (I/O, logging) not visible in their signature. Directive: pure core, impure shell — isolate effects at the boundary.
- **Immutability** — flag in-place mutation, shared mutable references, and `x = …; x = x + …` reassignment that could be a transform. Return new structures; reserve mutation for performance-critical paths.
- **Declarative over imperative** — replace accumulate-in-a-loop with `map`/`filter`/`reduce`/comprehensions. Each operation names its intent; a manual loop names only mechanics.
- **Higher-order & composition** — parameterize behavior, not just data; fold repeated structural patterns into a HOF; reach for partial application/currying over repetition.
- **Absence & errors** — prefer `Optional`/`Maybe` and `Result`/`Either` over null-as-signal, exceptions-as-control-flow, and nested `is not None` chains.
- **Laziness** — for large/infinite sequences, prefer generators/lazy seqs; chain without intermediate allocation; mark where eagerness is forced (`list(...)`).
- **Pattern matching** — prefer exhaustive matching over `if/elif` chains; handle all cases; name the matched shapes, not the conditions.
