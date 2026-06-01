# Kotlin Syntax Sugar — Readability Reference

Kotlin has constructs that feel elegant in isolation but create friction for anyone
who isn't already fluent in the language. The test is always the same:

> Can a competent developer new to Kotlin read this at the call site without
> needing to look up what's happening?

If no, prefer the explicit form.

---

## Scope functions: `let`, `run`, `also`, `apply`, `with`

The most common source of readability issues in Kotlin codebases.

**The core problem:** they create anonymous scopes where the receiver changes,
`this` and `it` refer to different things at different nesting levels, and the
control flow is hidden inside a lambda.

| Function | Receiver inside | Returns |
|----------|----------------|---------|
| `let`    | `it`           | lambda result |
| `run`    | `this`         | lambda result |
| `also`   | `it`           | original object |
| `apply`  | `this`         | original object |
| `with`   | `this`         | lambda result |

**When to flag:**
- Chains of more than one scope function
- Nesting scope functions inside scope functions
- Using `run` or `with` when a local variable would be clearer
- Using `also` for side effects buried mid-chain — the side effect should be visible

**Prefer:**
```kotlin
// Hard to read — what does this chain produce?
val result = user
    .takeIf { it.isActive }
    ?.let { repo.findOrdersFor(it) }
    ?.also { logger.info("found ${it.size} orders") }
    ?.filter { it.isPending }

// Explicit — each step is named and visible
if (!user.isActive) return
val orders = repo.findOrdersFor(user)
logger.info("found ${orders.size} orders")
val pendingOrders = orders.filter { it.isPending }
```

**`let` for null-safety is generally acceptable** when it's a single, short call:
```kotlin
user.email?.let { sendConfirmation(it) }  // ok
```

---

## `invoke()` convention

Kotlin allows any object to be called like a function by defining `operator fun invoke()`.
This makes `repository()` valid syntax when `repository` is an object, not a function.

**When to flag:** Any call site where it's not immediately obvious whether `x()` is
a function call or an `invoke()` on an object.

```kotlin
// Hard to read — is this a function or an object?
val result = orderProcessor(order)

// Clear
val result = orderProcessor.process(order)
```

---

## `infix` functions

`infix` allows `a method b` instead of `a.method(b)`. Reads like English but hides
that it's a method call, and is unfamiliar to developers coming from Java or other languages.

**When to flag:** `infix` usage outside of well-known DSL contexts (e.g., test assertions
like `shouldBe` are acceptable because the context makes them obvious).

```kotlin
// Surprising — what is "to"? What is "with"?
user sends message with attachment

// Clear
user.sendMessage(message, attachment = attachment)
```

---

## Operator overloading

Kotlin allows overloading of `+`, `-`, `*`, `/`, `[]`, `in`, `..`, and others.

**When to flag:** Any operator overloading where the operation's meaning isn't
immediately obvious from the types involved.

```kotlin
// What does + mean here? Merge? Append? Sum?
val report = monthlyReport + adjustment

// Clear
val report = monthlyReport.applyAdjustment(adjustment)
```

**Exception:** Mathematical or collection types where the operator has an unambiguous
meaning (`Vector + Vector`, `Matrix * scalar`) are fine.

---

## Interface delegation via `by`

`class Foo(val bar: Bar) : Bar by bar` makes `Foo` implement `Bar` by forwarding all
calls to `bar`. The mechanics are completely invisible at the class definition.

**When to flag:** When the delegation relationship isn't obvious from context and there's
no documentation explaining it.

```kotlin
// Hard to read — what methods does Foo actually have?
class UserRepository(val db: Database) : Database by db

// At minimum, document it
// Delegates all Database operations to [db].
// Only override methods where UserRepository adds behavior.
class UserRepository(val db: Database) : Database by db
```

---

## Destructuring by position

Data class destructuring assigns fields by their declaration order, not by name.

```kotlin
val (id, name, email) = user  // breaks silently if field order changes
```

**When to flag:** Any destructuring where the positional mapping isn't obvious,
or where the data class has more than 2-3 fields.

```kotlin
// Fragile — adding a field to User in the wrong position breaks this silently
val (id, name, email) = user

// Explicit and stable
val id = user.id
val name = user.name
val email = user.email
```

**Destructuring in `for` loops over pairs/maps is generally acceptable:**
```kotlin
for ((key, value) in map) { ... }  // conventional, widely understood
```

---

## Trailing lambdas

When the last argument to a function is a lambda, Kotlin allows moving it outside
the parentheses. Fine for short lambdas; problematic when the lambda is long.

**When to flag:** Trailing lambdas longer than 3-4 lines, especially when the function
name doesn't make it obvious that a block of code is being passed as configuration.

```kotlin
// Hard to read — the relationship between configure() and the block is lost
configure {
    // 20 lines of setup
    // ...
    // by here, it's easy to forget we're inside configure()
}

// If the lambda is long, name what's inside it
val config = buildConfig {
    // ...
}
configure(config)
```

---

## `it` in lambdas

`it` is the implicit parameter name for single-parameter lambdas. Fine for short,
obvious transformations; a problem when the lambda body is more than one line or
when `it` could refer to multiple things.

**When to flag:** `it` used in lambdas longer than one line, or in nested lambdas.

```kotlin
// Which "it" is which?
users.filter { it.isActive }.map { it.orders.filter { it.isPending } }

// Named parameters make each level explicit
users
    .filter { user -> user.isActive }
    .map { user -> user.orders.filter { order -> order.isPending } }
```

---

## Summary: when to prefer explicit over idiomatic

| Construct | Keep when | Flag when |
|---|---|---|
| Scope functions | Single, short, call site is clear | Chained, nested, or body is long |
| `invoke()` | Never at non-DSL call sites | Always — prefer a named method |
| `infix` | Well-known DSL (test assertions) | General application code |
| Operator overload | Unambiguous math/collection types | Any other domain concept |
| `by` delegation | Well-documented | Silent, undocumented |
| Destructuring | 2 fields, stable type, or map pairs | 3+ fields or unstable order |
| Trailing lambda | Body is 1-3 lines | Body is long; structure is lost |
| `it` | One-liner, obvious type | Multi-line or nested lambdas |
