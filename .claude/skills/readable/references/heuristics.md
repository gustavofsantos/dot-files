# Readability Heuristics — Kotlin

Rooted in the Agile school: Kent Beck, Martin Fowler, Sandi Metz, DHH, Gary Bernhardt,
Dave Thomas. Prefer fewer, higher-value changes over an exhaustive list of minor ones.

---

## Names

A name should say *what*, not *how*. If reading the name requires also reading the body
to understand what it represents, the name is wrong.

- Generic names are red flags: `data`, `info`, `result`, `temp`, `obj`, `value`,
  `item`, `manager`, `handler`, `util`, `helper`
- Booleans should read as assertions: `isExpired`, `hasPermission` —
  not `flag`, `check`, `status`, `bool`
- Functions returning Boolean should read as questions: `isValid()`, `canSubmit()`
- Collections should be plural nouns: `users`, `pendingOrders` —
  not `userList`, `ordersArray`, `listOfItems`
- A function named after *what it does* beats one named after *how*:
  `calculateMonthlyBalance()` over `processUserData()`

---

## Functions

- A function should do one thing at one level of abstraction
- If the body needs a comment to explain what it does, the name is wrong
- If the body needs a comment to explain *how* it does it, extract a function and name it
- Long functions are usually multiple functions waiting to be named
- Boolean parameters are a smell — they encode a decision the caller shouldn't make.
  Prefer two named functions or a sealed type
- Deep nesting (3+ levels) signals mixed abstraction levels — restructure via early
  return or extraction
- When both branches of an `if/else` are substantial, each branch is a function

---

## Structure

- Magic numbers and strings must become named constants or enum entries
- Comments that describe *what* the code does signal the code should say it itself
- Comments that describe *why* something is done are valuable — preserve them
- Dead code in comments must be removed

---

## Kotlin idioms — use when they clarify, not when they obscure

The goal is clarity at the call site. Idiomatic Kotlin that hides what's happening is
worse than explicit Kotlin that shows it.

- Prefer `when` over chains of `if-else if` for multiple conditions — reads as a
  decision table, not a cascade of guards
- Use named arguments when the call site is ambiguous without them — positional
  arguments beyond two parameters are a maintenance hazard
- Extension functions are good when they read like prose at the call site; bad when
  they hide that something meaningful is happening
- Chains of `let`/`run`/`also`/`apply` beyond one or two lines obscure control flow —
  extract a named function instead
- `data class` should model a domain concept, not just shortcut `equals`/`copy`
- `sealed class` or `sealed interface` + `when` beats boolean flags and string
  constants for states — the compiler enforces exhaustiveness, the code reads as a
  state machine
- Lambda parameters: name the parameter explicitly when `it` is ambiguous at the
  read site
