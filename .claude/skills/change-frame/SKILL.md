---
name: change-frame
description: Align the causal model of a change between the user and the agent BEFORE writing any code. Use when the user arrives with a change request and wants shared understanding of the system — before/after — instead of jumping to implementation. Trigger on "I want to change", "I need the system to", "let's align before I code", "understand what I want", or when the user describes a goal without having decided the implementation. Do NOT use for execution, writing tests, or generating code — the output is a minimal model frame, not an implementation artifact. Use even if the user doesn't explicitly ask for "alignment" when the request is a behavior change whose model isn't yet clear.
---
 
# Change Frame
 
Close the gap between two models of the system — the user's (tacit, in their head)
and yours (inferred from source right now) — before writing code. The output is NOT
a spec. It's the whiteboard sketch: the minimum that captures the change in *shape*
of the system, short-lived, handed off to execution.
 
Prose contracts drift from code and overload the reader. The real gap isn't missing
text — it's a divergent causal model. Close the model, don't write the spec.
 
## Golden rule
 
Align on the MODEL, never on the text. The user corrects *your* understanding; you
never ask them to correct *your* text. If the conversation turned into paragraph
review, you picked the wrong artifact — go back to the model diff.
 
## Flow
 
1. **Read the territory before asking.** Never ask from an imagined model. Read the
   source of the relevant regions first — that's the only way to align on the real
   system, not the assumed one. Cite evidence (file, function) and mark it
   `verified`. Anything you couldn't confirm in source is `inferred` — say so.
   If you don't know which regions are relevant, that's the first question.
2. **Reflect back the model you inferred.** "Today `X` does `Y` (`foo.clj:42`). You
   want it to do `Z`. Right?" This surfaces divergence early. It's pairing, not
   documentation — sketch just enough to agree on direction.
3. **Iterate on the model diff until it converges.** Adjust the model, not the text.
   Stop when the user confirms the `BEFORE → AFTER` of the regions that change shape.
   Don't expand scope — only regions that change enter the diff; the rest is noise.
4. **Emit the frame and stop.** Only emit when every `GOAL` is testable and every
   `INVARIANT` is expressable as an assertion. Anything unverifiable doesn't enter
   the frame — it becomes a `DRAGON`. What can't be checked isn't an agreement, it's
   a hope. After emitting, STOP. Don't write tests, don't generate code.
## Frame format
 
ALWAYS use this exact template. Deliberately prose-poor.
 
```
GOAL (verifiable):
  <one sentence — what becomes true that wasn't. Meant to become a test>
 
MODEL  BEFORE → AFTER
  <actor/concept>: <current role> → <new role>
  (only regions that change shape; each line cites evidence or tags `inferred`)
 
INVARIANTS (the bone — what must NOT break):
  - <structural promise a test will guard>
 
OUT OF SCOPE (explicit exclusion):
  - <what the agent must NOT touch>
 
DRAGONS (unknowns — become spikes, not decisions):
  - <what we don't know and won't pretend to>
```
 
Size limits, seriously:
- `GOAL`: one sentence. If it needs two, it's two frames.
- `MODEL`: only lines that change. Zero context lines that stay the same.
- If the frame exceeds ~15 lines, the scope is too big — split it.
## Example
 
**User input:** "Invoice charging needs to stop firing before the cycle closes.
Today it fires together with generation."
 
**Emitted frame:**
 
```
GOAL (verifiable):
  No charge is enqueued before the cycle is in state CLOSED.
 
MODEL  BEFORE → AFTER
  BillingCycle: generates invoice AND enqueues charge in the same step
    → generates invoice; enqueues charge only on transition to CLOSED
    (seen in billing/cycle.clj:88 — `verified`)
  ChargeQueue: consumes at generation time
    → consumes on CycleClosed event (`inferred`, confirm consumer)
 
INVARIANTS:
  - Every enqueued charge has a cycle in state CLOSED.
  - No invoice is generated twice per cycle (regression to guard).
 
OUT OF SCOPE:
  - Invoice amount calculation.
  - Retry of an already-failed charge.
 
DRAGONS:
  - Is the current consumer idempotent? If not, changing the trigger may
    duplicate. → spike
```
 
## When the model diverges DURING execution
 
The frame freezes an understanding that implementation can invalidate — you discover,
while coding, that the model was wrong. When that happens, don't edit the frame like
a doc. Invalidate and re-emit: `frame v1 assumed X; spike Y refuted it; frame v2`.
The resolved divergence is the record that matters — the delta between consecutive
frames, not the frames themselves. The frame is ephemeral by design.
