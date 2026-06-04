# Per-Language Design Decision Points

The 8 principles and checklist live in `design-principles.md`. This file holds only the
cases where a **language forces a design decision** the model would otherwise get wrong.

---

## Clojure — protocol vs. multimethod

Use **protocols** (`defprotocol`) for type-based dispatch — the direct analog to interfaces.  
Use **multimethods** (`defmulti`/`defmethod`) when dispatch depends on a value attribute, not a type.

Don't conflate them. A multimethod is not a slower protocol — it's a different dispatch model.

When to use protocols over plain functions: multiple dispatch targets, or Java interop required.  
Clojure's dynamic nature means a plain function accepting a map is often the right answer until you genuinely need dispatch.

---

## Kotlin — `fun interface` vs. sealed class

**`fun interface`** (SAM interface): use for open, single-method abstractions where callers should
be able to pass lambdas. The compiler generates a SAM conversion.

```kotlin
fun interface Validator<T> {
    fun validate(input: T): Boolean
}
val notEmpty = Validator<String> { it.isNotBlank() }
```

**Sealed class**: use for a **closed, known set** of implementations where you want exhaustive
`when` dispatch. If the set is closed and you own all variants, sealed class is correct — an
interface here loses exhaustiveness guarantees.

```kotlin
sealed class Result<out T>
data class Success<T>(val value: T) : Result<T>()
data class Failure(val error: Throwable) : Result<Nothing>()
```

Rule: open extensibility → `interface`/`fun interface`. Closed set + exhaustive dispatch → `sealed class`.

---

## TypeScript — `type` vs. `interface`

- Use `interface` for object shapes implemented by classes or extended by other interfaces — signals an abstraction boundary.
- Use `type` for unions, intersections, mapped types, and aliases.
- Prefer `interface` at module boundaries (it's extendable via declaration merging; `type` is not).

---

## Python — `Protocol` vs. `ABC`

| | `ABC` | `Protocol` |
|---|---|---|
| Satisfaction | Explicit (`class Foo(MyABC)`) | Structural (implicit) |
| Runtime check | `isinstance` works | Only with `@runtime_checkable` |
| Use when | You own all implementations | Third-party or legacy code |
| Analog to | Java interfaces | Go / TypeScript interfaces |

**Default to `Protocol`.** Use `ABC` only when you own all implementors and want runtime enforcement.
