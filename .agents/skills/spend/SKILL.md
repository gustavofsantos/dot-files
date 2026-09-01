---
name: spend
description: >
  Make the conceptual cost of a change explicit when the user asks to keep names,
  branches, or abstractions minimal. This is an optional constraint, not an implementation phase.
---

# Spend

A change spends concepts that a reader must learn: public names, types, variants, fields,
flags, modules, configuration keys, and branches.

## Loop

1. Before code, list the names and branches that the likely change adds or removes.
2. Try to reduce the cost. Reuse an exact existing concept. Replace related booleans with a
   valid state model. Remove branches that only guard invalid states. Inline a one-use helper
   when that makes the call site clearer.
3. Apply the read test. Summarize the change from its call sites without opening function
   bodies. Rename any concept that hides the intent.
4. State the final cost. Make every net addition explicit and justify why the domain or a
   real boundary needs it.

Treat one net new name as a strong default budget. More names are an overspend that requires
an explicit reason, not a prohibition. A valid domain model can cost more than the default.
Do not distort the behavior or merge distinct domain concepts to meet the budget.

Use a terse ledger:

```text
LEDGER <change>
NAMES <before> → <after> (net change)
BRANCHES <before> → <after>
READ TEST <one sentence from call sites>
OVER-BUDGET <none or explicit reason>
```

This skill constrains conceptual cost only. `change-frame` can align meaning, and
`way-of-planning` can sequence delivery. Tests and test names do not count against this
production-code budget.
