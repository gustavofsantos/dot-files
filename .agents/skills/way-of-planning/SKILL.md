---
name: way-of-planning
description: Turn an agreed behavior change into testable EARS requirements and ordered vertical slices, then obtain approval before execution.
disable-model-invocation: true
---

# Way of Planning

Create a short plan in the conversation. Do not create a plan file.

1. Phrase each requirement so it maps to an acceptance test:
   - `THE <system> SHALL <response>`
   - `WHEN <trigger>, THE <system> SHALL <response>`
   - `IF <condition>, THEN THE <system> SHALL <response>`
   - `WHILE <state>, THE <system> SHALL <response>` only for a real state.
2. Order the requirements as thin, end-to-end slices. Each slice must go green without
   breaking an earlier slice.
3. Show the requirements and slices to the user. Wait for approval before execution.
4. If execution disproves the plan's shape, revise the affected requirement or slice and
   obtain approval for that delta.
5. Stop when the approved slices are complete. Do not invent more work.

If the causal model is not agreed, hand that question to `change-frame` before planning.
Once approved, each slice can enter `way-of-work`. Other design, code, test, and cost steers
remain independent choices.
