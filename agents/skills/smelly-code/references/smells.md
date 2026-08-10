# Code Smells and Rewrites

Detect, then rewrite in place. Pseudocode is language-agnostic — translate to the target stack's idiom. These are classical refactoring smells that hurt **readability in production code**; the fix is always to surface intention and put the decision where the knowledge lives. Skip test files — those belong to `smelly-test`.

## 1. Unnamed boolean / complex condition

The condition *is* the idea, but it has no name — so every reader re-parses the operators, and the idea can't be reused or discussed.

```
BAD:   if (account.balance < 0 && !account.hasOverdraftProtection) { ... }
GOOD:  if (account.isOverdrawn()) { ... }
       // Account: fun isOverdrawn() = balance < 0 && !hasOverdraftProtection
```

Same smell when the compound is assigned to `flag`, `check`, or `ok`. If it takes more than a breath to read aloud, extract a predicate or explaining variable whose name is the policy.

## 2. Tell, don't ask (feature envy / getter decisions)

The caller interrogates another object's data, decides, then mutates — so the policy lives away from the knowledge, and every new rule sprouts another getter chain.

```
BAD:   if (order.getStatus() == PAID && daysSince(order.getDeliveredAt()) <= 30) {
         order.setStatus(REFUNDED)
         gateway.refund(order.getTotal())
       }

GOOD:  order.refundWithinWindow(clock.today(), gateway)
       // Order owns the window check and the state change; gateway is told what to do
```

Train wrecks (`a.getB().getC().getD()`) are the same smell in motion: the caller knows too much about foreign structure. Tell the nearby object; hide the path.

## 3. Policy in the persistence / database layer

A repository, query, or SQL fragment encodes eligibility, pricing, or workflow — so the rule is invisible to the domain and untestable without a database.

```
BAD:   // repository / query layer
       fun findRefundableOrders(now) =
         db.query("SELECT * FROM orders WHERE status = 'PAID' AND delivered_at > ?", now.minusDays(30))

GOOD:  // domain owns the rule
       fun Order.isRefundable(now) = status == PAID && !isPastReturnWindow(now)

       // persistence only loads candidates or writes decided state
       fun findPaidOrdersDeliveredAfter(cutoff) = db.query(...)
       // caller filters with isRefundable, or receives an explicit, already-named criterion
```

Persistence may filter on **stored facts** (status, timestamps, ids). It must not invent **business meaning** ("refundable", "eligible", "preferred") inside `where` clauses or query builders. If the criterion has a domain name, that name lives above the database.

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

Same smell: `process(order, isAdmin)`, `save(entity, skipValidation)`. Split into named operations or a small sum type; don't smuggle control flow through a flag.

## 6. Narrating comment / opaque block

A comment explains *what* the next block does because the block itself doesn't. Comments that say *why* (trade-offs, history, external constraints) stay; *what*-narration is a missing extraction.

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

Read the logic, list the ideas a colleague would claim exist, and check each against names and homes in the code. This is where the skill earns its keep: tests can lock a promise (`smelly-test`); only readable production code can show *what that promise means* without a guided tour.
