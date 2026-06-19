# Kotlin Syntax Sugar — Readability Reference

Kotlin constructs that feel elegant in isolation but tax a reader who isn't fluent. The test:

> Can a competent developer new to Kotlin read this at the call site without looking up what's happening?

If no, prefer the explicit form. The reviewer's calibration:

| Construct | Keep when | Flag when |
|---|---|---|
| Scope functions (`let`/`run`/`also`/`apply`/`with`) | single, short, call site is clear | chained, nested, or the body is long |
| `invoke()` (`x()` on an object) | well-known DSL only | non-DSL call sites — prefer a named method |
| `infix` | well-known DSL (test assertions like `shouldBe`) | general application code |
| Operator overload | unambiguous math/collection types (`Vector + Vector`) | any other domain concept (`report + adjustment` — merge? sum?) |
| `by` delegation | well-documented | silent/undocumented — the class's real surface is invisible |
| Destructuring | 2 fields, stable type, or `for ((k,v) in map)` | 3+ fields or unstable order — positional, breaks silently on reorder |
| Trailing lambda | body is 1–3 lines | long body — the tie to the enclosing call is lost |
| `it` | one-liner, obvious type | multi-line or nested lambdas — name the parameter per level |

Scope-function receivers (the recurring confusion): `let`/`also` expose `it`, `run`/`apply`/`with` expose `this`; `also`/`apply` return the original object, the rest return the lambda result. `let` for a single short null-safe call (`user.email?.let { sendConfirmation(it) }`) is fine.
