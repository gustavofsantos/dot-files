# Syntax Sugar — Readability Reference

Language-agnostic in principle, applied per language. Every language has constructs that feel elegant in isolation but tax a reader who isn't fluent in that language's idioms. The test is always the same:

> Can a competent developer new to *this language* read this at the call site without looking up what's happening?

If no, prefer the explicit form. Calibrate against the local codebase's conventions, not against an idealized style guide.

## How to use this reference

The table below names the *families* of sugar that recur across languages, with keep/flag calibration. Map each family onto the host language's concrete construct (examples in the column on the right) and judge the slice against it.

| Family | Keep when | Flag when | Examples by language |
|---|---|---|---|
| Scope-flow / "use" blocks | single, short, call site is clear | chained, nested, or long body | Kotlin `let`/`run`/`also`/`apply`/`with`; Ruby `tap`; JS early-return blocks |
| Implicit call / `invoke` | well-known DSL only | non-DSL call sites — prefer a named method | Kotlin `operator fun invoke`; Python `__call__`; JS functor `x()` |
| Infix / operator-like calls | well-known DSL (test assertions) | general application code | Kotlin `infix`; Scala infix; Elixir |
| Operator overload | unambiguous math/collection types | any other domain concept (merge? sum?) | Kotlin/Scala/Python operators; Clojure transducer composition |
| Delegation / proxy | well-documented surface | silent/undocumented — real surface invisible | Kotlin `by`; Python descriptors; Ruby `method_missing` |
| Destructuring | 2 fields, stable type, or map pairs | 3+ fields or unstable order — positional, breaks silently | Kotlin/JS/Python/Clojure destructuring; `for ((k,v) in …)` |
| Trailing lambda / block arg | body is 1–3 lines | long body — the tie to the enclosing call is lost | Kotlin/Scala/Go trailing blocks; Ruby `do…end`; Clojure `#()` |
| Implicit/default parameter | one obvious referent | multi-line or nested — name it per level | Kotlin `it`; Clojure `%`, `->`/`->>` threading; JS implicit `this` |
| Macro / metaprogramming | reads as the vocabulary it defines | shifts meaning a plain reader can't follow | Clojure macros; Rust macros; Elixir macros; Lisp reader macros |

## Calibration notes

- A construct that is *commonplace in the host codebase* gets more tolerance than one that is rare — fluency is local. Check the surrounding code before flagging.
- When flagging, propose the explicit form the codebase already uses elsewhere; do not invent a style new to the project.
- Threading/pipeline constructs (e.g. Clojure `->`/`->>`, Elixir `|>`, JS optional chaining chains) are fine when they read left-to-right as a sequence; flag them when the intermediate shapes are unclear or the pipeline branches.
