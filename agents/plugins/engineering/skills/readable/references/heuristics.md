# Readability Heuristics — Kotlin

Agile school (Beck, Fowler, Metz, DHH, Bernhardt, Thomas). Prefer fewer, higher-value changes over an exhaustive list of minor ones. Throughout: a name/function/abstraction should reveal *what*, never force the reader into the *how*.

## Names

- Red-flag generic names: `data`, `info`, `result`, `temp`, `obj`, `value`, `item`, `manager`, `handler`, `util`, `helper`.
- Booleans read as assertions (`isExpired`, `hasPermission`), Boolean-returning functions as questions (`isValid()`, `canSubmit()`) — not `flag`/`check`/`status`.
- Collections are plural nouns (`pendingOrders`), not `userList`/`ordersArray`.
- Name by what it does (`calculateMonthlyBalance()`), not how (`processUserData()`).

## Functions

- One thing, one level of abstraction. A function needing a comment to explain *what* has the wrong name; one needing a comment for *how* hides a function waiting to be extracted and named.
- Boolean parameters are a smell (they encode a caller's decision) → two named functions or a sealed type.
- Deep nesting (3+) or substantial both-branches of an `if/else` → early return / extraction.

## Structure

- Magic numbers/strings → named constants or enum entries.
- Comments: keep *why*; delete *what*-narration and commented-out dead code.

## Kotlin idioms (use only when they clarify the call site)

- `when` over `if-else if` cascades — reads as a decision table.
- `sealed class`/`interface` + `when` over boolean flags or string-constant states — compiler-enforced exhaustiveness, reads as a state machine.
- Named arguments past two parameters; `data class` for a real domain concept (not just free `equals`/`copy`).
- Extension functions only when they read as prose; name a lambda parameter when `it` is ambiguous. (Scope-function/construct calibration lives in `syntax-sugar.md`.)
