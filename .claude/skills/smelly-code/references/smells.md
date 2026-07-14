# Code Smells and Rewrites

Detect, then rewrite in place. Pseudocode is language-agnostic — translate to the target stack's idiom. These are the cases where the *naming* instinct diverges from ordinary code hygiene; the fix is always to surface the business rule.

## 1. Unnamed rule (inline condition)

The condition *is* the policy, but it has no name — so it can't be reused, tested, or discussed.

```
BAD:   if (account.balance < 0 && !account.hasOverdraftProtection) { ... }
GOOD:  if (account.isOverdrawn()) { ... }
       // Account: fun isOverdrawn() = balance < 0 && !hasOverdraftProtection
```

If the condition takes more than a breath to read aloud, it's a missing domain concept.

## 2. Magic value

A number or string carrying policy, stated as a literal. The reader sees `30` and not "the return window".

```
BAD:   if (daysSinceDelivery > 30) rejectRefund()
GOOD:  if (order.isPastReturnWindow()) rejectRefund()
       // RETURN_WINDOW = Days(30)   — one home, named
```

The literal is not the problem; the *anonymity* is. `MAX_RETRIES = 3` earns its name; `THIRTY = 30` does not.

## 3. Duplicated rule

The same policy expressed in two places. Both are right today; one will be wrong tomorrow.

```
BAD:   // checkout.kt:  if (cart.total > 100) shipping = 0
       // quote.kt:     if (items.sum() >= 100) freeShipping = true
GOOD:  ShippingPolicy.qualifiesForFreeShipping(cart)   // called from both
```

Note the bug already present in BAD: `>` vs `>=`. Duplication doesn't cause drift — it *hides* drift that already happened.

## 4. Braided decision and effect

The rule can't be read or tested without the IO wrapped around it.

```
BAD:   fun processRefund(orderId) {
         order = repo.load(orderId)
         if (daysSince(order.deliveredAt) > 30) { log.warn(...); return }
         gateway.refund(order.total)
         repo.save(order.markRefunded())
       }

GOOD:  // core: pure, the rule is the whole function
       fun decideRefund(order, now): RefundDecision =
         if (order.isPastReturnWindow(now)) Rejected(PastWindow) else Approved(order.total)

       // shell: no rule, only obedience
       fun processRefund(orderId) {
         when (val d = decideRefund(repo.load(orderId), clock.now())) {
           is Approved -> { gateway.refund(d.amount); repo.save(...) }
           is Rejected -> log.warn(d.reason)
         }
       }
```

This is the smell that makes `smelly-test` hard: braided code forces mock-choreography assertions (test smell #5). Fix the code and the test smell dissolves.

## 5. Primitive obsession on a domain value

A concept with rules is carried as a bare `String`/`Double`, so the rules live in whoever remembers to call the validator.

```
BAD:   fun charge(amount: Double, currency: String)   // negative? BRL vs "brl"?
GOOD:  fun charge(amount: Money)
       // Money's constructor refuses non-positive amounts — the rule can't be skipped
```

Apply where the value has invariants worth protecting. Not every `String` is a type.

## 6. The invisible rule (a gap, not a smell)

The business has a policy; the code enforces it only as an accident of arrangement — an ordering of statements, an early return, a lucky default. Nothing *names* it, so the next refactor removes it silently and no one notices until production.

```
BAD:   // "premium customers are never rate-limited" is enforced only because
       // the premium branch happens to return before the throttle check
GOOD:  if (customer.isExemptFromRateLimit()) return proceed()
       // the exemption is now a fact, not a side effect of line order
```

Read the logic, list the rules a domain expert would claim exist, and check each against the names in the code. This is where the skill earns its keep: the tests say *this is a promise*, only the code can say *this is what the promise means*.
