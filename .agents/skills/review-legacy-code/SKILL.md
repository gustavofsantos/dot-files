---
name: review-legacy-code
description: Review any bounded change against legacy behavior and decide whether evidence makes it safe to land. Review only and never fix code.
disable-model-invocation: true
---

# Review Legacy Code

Treat the system around the reviewed change as legacy. Important behavior may be
undocumented, surprising, or visible only through indirect effects. Finding no obvious bug
is not enough to make the change safe to land.

This is a review-only gate. Do not fix code, refactor it, commit, merge, push, or approve a
pull request. Keep any probe or fixture disposable and outside the caller's tracked files.

## Fix the comparison

Determine the exact `BEFORE` and `AFTER` states from the user's scope.

- For working-tree changes, include staged, unstaged, and relevant untracked files.
- For branches or commits, use the requested base. If none was given, state the merge-base
  assumption.
- For a supplied patch or code slice, use its supplied before-state and inspect enough
  surrounding code to trace its effects.

State the comparison you reviewed. Account for the whole requested change rather than a
sample. Without a defensible `BEFORE`, do not claim that the change preserves behavior.

## Reconstruct legacy behavior

Derive the narrow behavior the change intends to alter. Then trace every changed area
backward to its callers and forward to stable observable boundaries. Include state,
persistence, side effects, consumers, failures, and hidden participation on affected paths.
Check data, schema, configuration, compatibility, retry, ordering, timing, and concurrency
contracts when the change can reach them.

Use `BEFORE` code, existing tests, explicit contracts, configuration, schemas, and runtime
observations as evidence. Treat the patch description, names, comments, and `AFTER`-only
tests as claims until independent evidence supports them.

## Demand landing evidence

For each material behavior, classify it as intentionally changed, preserved,
uncharacterized, or unknown. A preservation pin must exercise the affected path. It must
fail for a plausible wrong behavior. Its expected result must come from `BEFORE` or an
independent contract. Coverage alone is not proof.

Check that seams and structural changes preserve behavior on their own. Look for accidental
behavior drift, unprotected paths, and blast radius that the intent does not require. Run a
focused safe probe when it can settle a material claim. Do not require or trust a prior
legacy evidence report without checking it independently.

Label material claims `OBSERVED`, `INFERRED`, or `UNKNOWN`. When it is material, run the
same input and state against `BEFORE` and `AFTER`. Challenge an important pin with the
smallest plausible wrong behavior in a disposable checkout. A plausible mutation that stays
green weakens the pin.

## Give a verdict

- `PASS` only when the full change is accounted for and trustworthy evidence protects every
  material affected path.
- `BLOCK` for a concrete defect, accidental behavior drift, missing essential protection,
  or avoidable blast radius that makes landing unsafe.
- `INCONCLUSIVE` when a missing baseline, environment, or observation prevents a sound
  decision.

Never turn material uncertainty into `PASS`. When migrations, irreversible effects, or
external systems matter, judge code landing and deployment safety separately.

## Make the review visible

Report to the user with this shape:

```text
LEGACY REVIEW
- Scope: <BEFORE to AFTER>
- Verdict: <PASS, BLOCK, or INCONCLUSIVE>
- Intended change: <behavior meant to change>
- Preservation evidence: <behavior proven unchanged and concrete evidence>
- Findings: <failure paths with locations and evidence, or none>
- Evidence gaps: <material behavior not proved, or none>
- Landing conditions: <what must become true before landing, or none>
```

Every field is required. Use `none` only after checking the full scope. Do not replace the
report with a vague statement that the change looks safe. `PASS` reports technical evidence.
It does not grant authority to merge, approve, or deploy.

For each finding, give the location, triggering scenario, behavior at risk, concrete
evidence, and the smallest condition that would make the change safe to land. Do not report
style, generic advice, unrelated cleanup, or risks without a plausible failure path.
