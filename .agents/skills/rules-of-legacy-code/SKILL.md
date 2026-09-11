---
name: rules-of-legacy-code
description: Require a user-visible, evidence-backed picture of affected legacy behavior before any production-code change.
disable-model-invocation: true
---

# Rules of Legacy Code

When this skill is invoked, treat the code in scope as legacy. Existing behavior may encode undocumented contracts. Do not change production code until the affected behavior is understood and protected.

## Establish the affected picture

Trace the bounded effect surface of the proposed edit:

1. Entry points, callers, triggers, and reachable branches the edit can influence.
2. Downstream calls, outputs, state changes, persistence, and external side effects.
3. Data, configuration, failure, retry, ordering, timing, and concurrency contracts when they can be affected.
4. Existing tests and relevant source, schema, configuration, or runtime evidence.
5. Observed behavior that must remain distinct from behavior the request intends to change.

The picture is complete when every consequential effect the edit can alter is supported by evidence through a stable observable boundary. This does not require understanding the whole system. Expand the picture only along affected paths.

## Make the evidence visible

Before the first production-code edit, send the user an update with this shape:

```text
LEGACY EVIDENCE
- Change point: <where the edit will occur>
- Affected paths: <triggers through observable effects>
- Evidence: <files, symbols, tests, commands, or runtime observations>
- Preserve: <current behavior and invariants that must remain>
- Protection: <characterization coverage or seam>
- Unknowns: <remaining uncertainty and why it cannot affect the edit, or none>
```

Every field is required. Cite concrete locations or observed results. Do not claim that an unknown cannot affect the edit without evidence.

Do not keep this assessment in private reasoning. Do not replace it with a vague claim that the area was inspected or understood. This is an information checkpoint, not a new request for permission when the change is already authorized.

If a consequential path remains unexplained or cannot be observed, stop before editing production code. Tell the user what evidence is missing and identify the smallest safe step that could obtain it.

## Protect behavior before changing it

Characterize current behavior at the nearest stable observation point or pinch point. An existing test counts only when it exercises the affected path and its deciding facts. Keep accidental current behavior separate from behavior that is intentionally required.

If the code cannot be observed under test, introduce the smallest behavior-preserving seam needed for sensing or separation. The evidence gate applies to that edit too. Verify equivalence and keep the seam change separate from the requested behavior change. Leave the resulting protection in the test suite.

## Make the narrow change

After the gate passes, make the smallest production change that satisfies the request. Avoid unrelated cleanup, broad rewrites, or speculative modernization. Verify both the new behavior and the preserved behavior at affected boundaries.

If implementation exposes an untraced path or contradicts the reported picture, stop and refresh the user-visible evidence before continuing.
