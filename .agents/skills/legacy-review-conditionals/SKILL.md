---
name: legacy-review-conditionals
description: Review a legacy-code change for conditional and branching risk only — decision drift, fail-open defaults, absent-value semantics, exhaustiveness — and name the safe-change strategy for each finding.
disable-model-invocation: true
---

# Legacy review: conditionals

Review only the conditional logic a change touches. Everything else is out of scope for this run; sibling review skills cover it.

## Scope

**In:** every changed or newly added decision point — `if`/`unless`/`when`, `cond`/`case`/`switch`/`match`, ternaries, guard clauses and early returns, boolean expressions, filter/where predicates, feature-flag checks, and exceptions used as control flow.

**Out:** naming, style, performance, architecture, test design, security beyond branch outcome. Do not report these, even when obvious.

**Read:** the diff, the enclosing function of each changed decision, and the direct callers that supply its inputs. Expand only to resolve a deciding fact.

## Classify first: contract or decision

Use Design by Contract. Before applying lenses, label each in-scope condition as one of:

- **Contract**: an expectation that must hold (precondition, postcondition, invariant). When it's violated, that's a bug or bad input, not a business case. It must **fail fast** (raise, assert, or reject at the boundary). It must never route the violation into an ordinary branch or a silent default.
- **Decision**: a legitimate business choice among valid states. It must be **exhaustive**, and every branch must be a valid outcome.

Report a mismatch as a finding:

- **Contract disguised as decision**: an impossible or invalid state is handled by returning a default, `nil`, or an empty result. This hides the violation.
- **Decision disguised as contract**: a valid business case raises or rejects.
- **Redundant defensive check**: an inner re-check of a contract already enforced at a trusted boundary (DbC non-redundancy). This only matters when the change makes the copies disagree.

## Lenses

Apply each lens to each in-scope decision point. A lens either yields a finding or nothing.

0. **Contract drift**: For each contract, compare before and after. **Strengthening a precondition** (accepting less) or **weakening a postcondition** (guaranteeing less) breaks existing callers. That is HIGH whenever the function has callers outside the diff. The reverse direction, weakening a precondition or strengthening a postcondition, is safe for callers.

1. **Truth-table drift** — Reconstruct the decision table before and after. Any input row whose outcome changed and is not part of the stated intent is a finding. Claimed-equivalent rewrites (De Morgan, inversion, guard-clause extraction, merged branches) must preserve every row.
2. **Fail-open vs fail-closed** — For unknown, missing, or erroring input, which branch wins? On money, authorization, state transitions, or external effects, the default must fail closed. A changed `else`/`default` path is always examined.
3. **Absent-value semantics** — Truthiness is language-specific: `nil`/`null`/`undefined`, `false`, `0`, `""`, empty collections, `NaN`, boxed booleans, SQL `NULL` (three-valued logic). Flag any condition whose outcome depends on which absent value arrives, and any port between languages (e.g. Clojure → Java) that changes this.
4. **Evaluation order and short-circuit** — Guards that protect later operands (null check before dereference), side effects inside conditions, and reordered operands.
5. **Exhaustiveness** — New or future variants (enum value, status, type) that fall into a default branch silently; `cond` without `:else` yielding nil; `switch` fallthrough; pattern matches without a catch-all decision.
6. **Boundary predicates** — `<` vs `<=`, inclusive/exclusive ranges, date/time comparisons across time zones, equality on floats or money.
7. **Divergent duplicates** — The same business predicate expressed elsewhere in the codebase but changed here only. Search for its deciding terms before concluding none exist.
8. **Flag states** — Both states of every touched feature flag must be valid paths; the flag's absent/default value must be the safe branch; a removed flag must not leave a dead or inverted branch.
9. **Branch evidence** — Each changed truth-table row is pinned by a test whose deciding fact is visible in the test itself. A missing pin is a finding, not a test-design critique.

## Safe-change strategies

Each finding names exactly one strategy:

- **Characterize** — Pin the current truth table with characterization or approval tests before the change.
- **Split refactor from behavior** — Equivalence-preserving rewrite in its own commit; behavior change in another.
- **Make the default explicit** — Replace the implicit fallthrough with an explicit branch that fails closed or raises.
- **Parallel change** — Expand/contract: add the new predicate beside the old, migrate callers, remove the old.
- **Shadow compare** — Evaluate old and new predicates side by side in production, act on the old, log mismatches (Scientist pattern).
- **Toggle** — Gate the new decision behind a flag whose default is the current behavior.
- **Sprout** — Put the new decision in a new, tested unit called from the legacy site, leaving the legacy decision untouched.
- **Consolidate the predicate** — Extract the duplicated decision into one named predicate before changing it.
- **State the contract**: Turn an implicit expectation into an explicit precondition at the trust boundary (guard, assertion, or parsed type), and fail fast there. Remove inner defensive branches only after characterization.

## Output

Report findings only, highest risk first. Use this shape for each:

```text
[HIGH|MEDIUM|LOW] <lens name> — <file>:<line>
Condition: <the condition, quoted from the code> (contract | decision)
Drift: <the input that now behaves differently, and before → after outcome>
Evidence: <deciding facts: callers, values, tests, or their absence>
Strategy: <one strategy from the list> — <one line on how it applies here>
```

Severity: **HIGH** if the drift reaches money, authorization, persisted state, or external effects; **MEDIUM** if it changes user-visible behavior; **LOW** otherwise.

Report a finding only with a concrete drifting input. A suspicion without one goes under `Unresolved:` with the missing deciding fact.

If nothing qualifies, output exactly: `No conditional findings.`
