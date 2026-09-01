# Code Smells and Rewrites

Detect, then rewrite in place. Pseudocode is language-agnostic — translate to the target stack's idiom. These are classical refactoring smells that hurt **readability in production code**. The fix is always to surface intention and put the decision where the knowledge lives. Skip test files — those belong to `smelly-test`.

## 1. Unnamed boolean / complex condition

The condition *is* the idea, but it has no name — so every reader re-parses the operators, and the idea cannot be reused or discussed.

```
BAD:   if (account.balance < 0 && !account.hasOverdraftProtection) { ... }
GOOD:  if (account.isOverdrawn()) { ... }
       // Account: fun isOverdrawn() = balance < 0 && !hasOverdraftProtection
```

Same smell when the compound is assigned to `flag`, `check`, or `ok`. If it takes more than a breath to read aloud, extract a predicate or explaining variable whose name is the policy.

## 2. Decision far from its knowledge

The caller pulls foreign data across a boundary and makes a decision far from the data and
invariants it needs. Each new rule spreads more structure through callers.

```
BAD:   if (order.getStatus() == PAID && daysSince(order.getDeliveredAt()) <= 30) {
         order.setStatus(REFUNDED)
         gateway.refund(order.getTotal())
       }

GOOD:  refundOrderWithinWindow(order, clock.today(), gateway)
       // The named operation keeps the window rule and state change together.
```

Getter chains are one form of this smell. Move the decision to the closest suitable object,
function, module, service, or boundary. Hide structure that the caller does not own.

## 3. Unnamed policy at the persistence boundary

A repository, query, or SQL fragment encodes eligibility, pricing, or workflow without a
domain name at its boundary. The rule becomes hard to find and discuss.

```
BAD:   // repository / query layer
       fun findRefundableOrders(now) =
         db.query("SELECT * FROM orders WHERE status = 'PAID' AND delivered_at > ?", now.minusDays(30))

GOOD:  fun findRefundableOrders(now) =
         db.query(REFUNDABLE_ORDERS_QUERY, now.minusDays(30))
       // The boundary names the domain intent. The database keeps filtering atomic and fast.
```

Database execution can be necessary for correctness, atomicity, or performance. Keep the
domain intent visible in the repository API, query name, schema constraint, or adjacent
domain contract. Do not hide policy in a generic method or unnamed predicate.

## 4. Nested control flow / long method

Deep `if/else` or a screen-length function forces the reader to simulate the machine to recover intent.

```
BAD:   fun process(order) {
         if (order != null) {
           if (order.isPaid()) {
             if (!order.isExpired(clock)) {
               // ... 40 lines ...
             } else { ... }
           } else { ... }
         }
       }

GOOD:  fun process(order) {
         requirePaid(order)
         requireActive(order, clock)
         settle(order)          // one named step at this level
       }
```

Prefer guard clauses and extracted named steps over nesting. Each extracted function should be one level of abstraction — orchestration *or* detail, not both.

## 5. Boolean parameter

A `true`/`false` argument encodes a caller's branch that the callee then re-branches on — so the call site hides which path runs.

```
BAD:   render(invoice, includeTax = true)
       render(invoice, false)

GOOD:  renderWithTax(invoice)
       renderNet(invoice)
```

Same smell: `process(order, isAdmin)`, `save(entity, skipValidation)`. Split into named operations or a small sum type. Do not smuggle control flow through a flag.

## 6. Narrating comment / opaque block

A comment explains *what* the next block does because the block itself does not. Comments that say *why* (trade-offs, history, external constraints) stay. *what*-narration is a missing extraction.

```
BAD:   // check return window and refund if still open
       if (daysSince(order.deliveredAt) <= 30) { gateway.refund(order.total); ... }

GOOD:  refundIfWithinReturnWindow(order, gateway, clock)
```

If you need a comment to label a region, extract a function with that label as its name — then delete the comment.

## 7. The unreadable arrangement (a gap, not a local smell)

Intention survives only as line order, a lucky early return, or a side effect of how two layers happen to call each other. Nothing *names* the idea, so a tidy refactor removes it while every remaining line still "looks fine."

```
BAD:   // "premium customers skip rate limiting" only because the premium
       // branch returns before the throttle check ever runs
GOOD:  if (customer.isExemptFromRateLimit()) return proceed()
       throttle(customer)
```

Read the logic, list the ideas a colleague would claim exist, and check each against names and homes in the code. This is where the skill earns its keep: tests can lock a promise (`smelly-test`). Only readable production code can show *what that promise means* without a guided tour.
