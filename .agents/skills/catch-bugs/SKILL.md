---
name: catch-bugs
description: Adversarial review gate that reconstructs BASE, traces the affected behavior, and tries to falsify change safety. Review only and never fixes code.
disable-model-invocation: true
---

# Catch Bugs

Review the requested change with this kernel:

`BASE → intent kernel → complete changed surface → affected envelope → trustworthy pins → safe falsification → verdict`

Do not implement fixes, refactor product code, commit, push, or change the caller's tracked
files. Disposable tests, mutations, fixtures, and checkouts are allowed only when they make
the review stronger. Keep destructive probes in a disposable checkout. Never use production
systems, real credentials, customer data, or shared mutable infrastructure.

## Evidence

Label material claims:

- `OBSERVED`: code, an explicit contract, or an executed result establishes the claim.
- `INFERRED`: evidence supports the claim, but no direct observation establishes it.
- `UNKNOWN`: available evidence does not establish the claim.

BASE is the reference for preservation. Patch intent, comments, names, and HEAD-only tests
are claims until BASE or an independent contract supports them. A new test does not prove
preservation when its expected result comes only from HEAD.

## Review flow

1. **Establish BASE and HEAD.** Use the requested base or state the most defensible merge-base
   assumption. Account for committed, staged, unstaged, relevant untracked, renamed, deleted,
   generated, configuration, schema, migration, dependency, query, script, and operational
   changes. Do not sample the diff.
2. **Derive the intent kernel.** State the narrowest observable behavior that must change.
   Classify each meaningful area as required, supporting, coupled, unrelated, or unknown.
   Search for a narrower path only when it would reduce material blast radius.
3. **Reconstruct BASE.** Establish prior observable behavior, state, callers, consumers,
   side effects, failures, and hidden participation. Preserve surprising behavior unless the
   intent or an independent contract requires a change.
4. **Build the affected envelope.** Trace each behavior-changing area backward and forward
   to stable observable boundaries. Include shared state, asynchronous work, persistence,
   generated behavior, configuration, framework semantics, and external effects only when
   they are on the path.
5. **Find trustworthy pins.** For each material behavior, ask what fails if it changes and
   where that oracle gets its expected result. Classify it as preserved, intentionally
   changed, uncharacterized, or unknown. Coverage alone is not a pin.
6. **Falsify safely.** When material, run the same input and state against BASE and HEAD.
   Challenge important pins with the smallest plausible wrong behavior in a disposable
   checkout. Record the command and observed result. A plausible unsafe mutation that stays
   green weakens the pin.
7. **Issue a verdict.** Re-enter through a different caller or boundary when blast radius
   warrants it. Stop when the whole change is accounted for, material paths have pins, and
   the strongest credible failure claims have been tested.

If behavior-preserving structure and intentional behavior changes cannot be attributed
independently, return `BLOCK`. If safe evidence is unavailable, keep the gap and do not turn
uncertainty into `PASS`.

## Merge and deploy safety

Judge merge safety and deploy safety separately. For any irreversible or external effect,
state the concrete failure path and the containment, verification, or recovery evidence that
deployment needs. A change can be merge-safe and deploy-unsafe.

## Report

Start with one verdict: `PASS`, `PASS_WITH_FINDINGS`, `BLOCK`, or `INCONCLUSIVE`.

Then include:

- **Findings:** only concrete defects, material evidence gaps, unnecessary blast radius,
  preserved quirks, or unresolved areas. Give severity, evidence label, location, behavior
  at risk, BASE and HEAD evidence, failure path, weak pin, and smallest resolution.
- **Minimality:** intent kernel, current blast radius, narrower credible path, and coupled or
  unrelated areas.
- **Behavioral ledger:** account for every changed area, its necessity, affected behavior,
  BASE oracle, falsification, and state.
- **Material probes:** hypothesis, command, BASE result when relevant, HEAD result, and
  conclusion. Omit only when no safe probe was material.
- **Deploy safety:** state either that no material deploy-specific risk was found or name the
  required containment or recovery evidence.

Use `CRITICAL`, `HIGH`, `MEDIUM`, or `LOW` only when the failure path and impact support the
level. Keep the report concise. Do not report style, generic advice, unrelated refactors, or
risks with no plausible path.
