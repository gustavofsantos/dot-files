# Readability Heuristics

Agile school (Beck, Fowler, Metz, DHH, Bernhardt, Thomas). Prefer fewer, higher-value changes over an exhaustive list of minor ones. Throughout: a name/function/abstraction should reveal *what*, never force the reader into the *how*.

These signals are language-agnostic. Apply them within the slice (most often a diff) and its immediate context — not across the whole file. Language-specific construct calibration lives in `syntax-sugar.md`.

## Names

- Red-flag generic names: `data`, `info`, `result`, `temp`, `obj`, `value`, `item`, `manager`, `handler`, `util`, `helper` (and the local equivalents — e.g. `process`, `aux`, `foo`).
- Booleans read as assertions (`is-expired`, `has-permission`, `expired?`), Boolean-returning functions as questions (`valid?`, `can-submit?`, `isValid()`) — not `flag`/`check`/`status`.
- Collections are plural nouns (`pending-orders`, `pendingOrders`), not `user-list`/`orders-array`/`order-array`.
- Name by what it does (`calculate-monthly-balance`), not how (`process-user-data`).

## Functions

- One thing, one level of abstraction. A function needing a comment to explain *what* has the wrong name; one needing a comment for *how* hides a function waiting to be extracted and named.
- Boolean parameters are a smell (they encode a caller's decision) → two named functions or a sum/enum/sealed type.
- Deep nesting (3+) or substantial both-branches of a conditional → early return / guard clause / extraction.

## Structure

- Magic numbers/strings → named constants or enum entries.
- Comments: keep *why*; delete *what*-narration and commented-out dead code.
- A change that scatters one intent across many small edits, or crams several intents into one hunk, is itself a readability signal for the *diff* — name the intent in the commit/message when the code can't carry it.

## Idioms

- Prefer the construct the local codebase already uses fluently over a "clever" one, even if the clever form is shorter — consistency reads better than novelty.
- Reach for a language idiom only when it clarifies the call site; if it taxes a reader unfamiliar with that idiom, see `syntax-sugar.md`.
