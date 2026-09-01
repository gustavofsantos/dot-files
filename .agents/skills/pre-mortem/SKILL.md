---
name: pre-mortem
description: Before implementation, expose the most credible failure modes and mitigate the ones that could invalidate the approach.
disable-model-invocation: true
---

# Pre-Mortem

Use this before implementation. Assume the proposed solution failed, then work backward to
the concrete causes that could invalidate the approach.

## Procedure

1. **Goal** — state it in one sentence. Name what success looks like and how you'd measure it.
2. **Assume failure** — "It is 4 weeks out. This failed." Do not ask *if* it might. Assume it did.
3. **Find credible failure modes** across the relevant technical, behavioral,
   integration, operational, and delivery boundaries. Do not add filler to reach a count.
4. **Prioritize** by likelihood and impact.
5. **Mitigate** each high-priority mode with a design constraint, an upfront test, a
   guard, or a question that must be answered before coding.
6. **Pre-flight** — the approach addresses the modes that could block implementation.
   Include containment or recovery only when the proposed change creates that need.

## Output

```
## Pre-Mortem: <name>
**Goal:** <one sentence>
**Top failure modes:**
| Failure mode | Likelihood | Impact | Mitigation |
|---|---|---|---|
**Blockers to resolve before coding:**
**Containment or recovery:** <only when material>
```

## Feeding back

If the work has a tracked issue, return the result to that issue. Do not turn this into
an end-of-change or deploy-review gate.
