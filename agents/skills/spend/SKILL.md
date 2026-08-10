---
name: spend
description: >
  Constrain the conceptual cost of a change before writing it. Every change spends
  from a budget: new names, new branches, new concepts a reader must hold. This skill
  forces the agent to declare that spend, justify it, and pay it down — so the result
  reads in one pass by a human or an agent. Trigger on "keep this minimal", "don't
  add another abstraction", "make this read cleanly", "/spend", or before implementing
  any change to code that already has a working shape. NOT for greenfield code with no
  existing vocabulary. NOT for alignment (that's change-frame) or sequencing (that's plan).
---
# spend

A change is a purchase. It buys behavior and it pays in **concepts the reader must
hold**. Most agent-written code is expensive: it adds a name, a branch, and a helper
to do what an existing name already did. Nobody notices, because each purchase is
individually small and individually justified.

You are the one who reads the price tag out loud before the code is written.

The shape you are steering toward is Bernhardt's: decisions pushed to the boundary
until they vanish, values instead of questions, a core that answers and a shell that
asks. You do not get there by writing less code. You get there by **refusing to spend**
and letting the refusal force a better shape.

## Golden rule

**A change may introduce at most one new name. To introduce a second, delete one.**

This is TCR applied to vocabulary. It is not a style preference — it is a forcing
function. When the budget binds, the agent must ask the question it otherwise skips:
*does this concept already exist here under a different name?* That question is the
whole discipline. The budget is just what makes it unavoidable.

A "name" is any symbol a reader must learn: function, type, variant, field, flag,
module, config key. Local variables inside one function are free — they die at the
brace.

## Loop

1. **Price the change.** Before any code, emit the LEDGER (below). Count what the
   obvious implementation would cost. Do not soften the count.

2. **Try to pay it down.** For each new name, ask in order:
   - Does an existing symbol already mean this? → reuse it.
   - Is this name a *question the code is asking*? → make it a value or a variant so
     the question can't be asked. (`isPending`/`isShipped`/`isCancelled` → one ADT.)
   - Is this a branch that only exists because the data admits an invalid state? →
     tighten the type until the branch is unreachable, then delete it.
   - Is this a helper that wraps one call site? → inline it.

   Each of these turns a purchase into a refund. Rerun the count.

3. **Apply the read test.** Write the one-sentence summary of what the change does,
   **using only the call sites — do not open any function body.** If you cannot, a
   name is lying. Rename until you can. This is the actual goal; the budget only
   exists to get you here.

4. **Spend what's left, once.** Implement. If the budget is still over, say so
   explicitly with the reason — an honest over-spend is fine, a silent one is not.

## LEDGER

Emit before code. Terse. No prose.

```
LEDGER  <change in one line>

NAMES        before → after   (net +N / −N)
  + OrderState          new ADT
  − isPending           absorbed
  − isShipped           absorbed
  − isCancelled         absorbed
  net: −2

BRANCHES     4 → 1
  the three status checks collapse into one match

READ TEST
  "Shipping an order transitions its state and emits a notification."
  ✓ derived from call sites only

OVER-BUDGET
  none
```

If `net` is positive and you cannot justify it in one line, you have not finished
step 2. Go back.

## What this skill does not do

It does not make code shorter. Shortness is a side effect, and chasing it directly
produces the opposite of what you want — clever one-liners are expensive to read.
The budget is in *concepts*, not lines. A ten-line `match` that eliminates four
scattered booleans is a refund even though it is longer.

It also does not touch tests. Test names are documentation and are billed separately —
a new test name is always free.

## Boundary with the other skills

`change-frame` fixes *what the change means*. `plan` fixes *the order it lands in*.
`spend` fixes *how much vocabulary it is allowed to cost*. Run it after the frame,
before or during the plan. It constrains the how, never the what — if paying down the
budget would change the GOAL, stop: that is a frame problem, not a spend problem.
