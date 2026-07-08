# Test Smells and Rewrites

Detect, then rewrite in place. Pseudocode is language-agnostic — translate to the target stack's idiom. These are the cases where the *documenting* instinct diverges from ordinary test hygiene; the fix is always to surface the business promise.

## 1. Method-mirror name
Name repeats the implementation, so failure teaches nothing about the domain.
```
BAD:   applyDiscountWorks()
GOOD:  loyaltyDiscountAppliesOnlyAboveMinimumSpend()
```

## 2. Assertion on internals / restated arithmetic
Leaks implementation, or recomputes the formula so it passes when the code is wrong the same way.
```
BAD:   assertEquals(-5.0, account.balanceField)
GOOD:  assertThat(account).isOverdrawn()

BAD:   assertEquals(price * 1.08, invoice.total)   // mirrors the formula
GOOD:  assertThat(invoice.total).isEqualTo(108.00) // stated fact: $100 + 8% = $108
```
If no domain predicate exists to assert against, the domain is missing a concept — consider adding it.

## 3. Bundled multi-rule assertion
One giant equality over a result covering many rules. On failure: "something changed," no signal which promise broke.
```
BAD:   assertEquals(expectedOrder, checkout(cart))   // total, tax, shipping, status at once
GOOD:  taxIsChargedAtDestinationStateRate()
       freeShippingAppliesAboveThreshold()
       expiredCouponIsRejected()
```
Keep whole-object equality only for atomic value objects where the shape *is* the one rule.

## 4. Hidden deciding value
The fact that makes the scenario meaningful is buried in a default, so the reader can't see why this case exercises this rule. Name the condition too.
```
BAD:   refundIsRejected()  with  standardAccount()
GOOD:  refundIsRejectedAfterReturnWindowCloses()
         order = anOrderDeliveredDaysAgo(31)   // window is 30 — boundary visible
```

## 5. Mock-choreography assertion
Asserts on collaborator calls, documenting how the code is wired instead of what it guarantees. Breaks on refactor even when behavior holds.
```
BAD:   verify(repo).save(any()); verify(gateway).charge(any())
GOOD:  assertThat(order).isConfirmed()
       assertThat(customer.availableCredit).isEqualTo(0)   // credit consumed
```
Mock only true boundaries (external services, clock, randomness); assert on observable domain state.

## 6. The undocumented invariant (a gap, not a smell)
A rule is enforced in the code but named in no test — so it's unenforced by the suite; delete the guard and everything stays green. Read the logic, list its rules, check each against the test names, add the missing one. This is where the skill earns its keep: the code says *what happens*, only the test says *this is a promise we intend to keep*.
