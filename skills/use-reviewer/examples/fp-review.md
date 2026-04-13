# Example: FP Review — Data Pipeline

## Submitted Code

```javascript
function processTransactions(transactions) {
  let result = [];
  for (let i = 0; i < transactions.length; i++) {
    let t = transactions[i];
    if (t.status === 'completed') {
      let amount = t.amount;
      if (t.currency !== 'USD') {
        // convert to USD
        amount = amount * getExchangeRate(t.currency);
      }
      if (amount > 1000) {
        t.flagged = true;  // mutating input
        result.push({ id: t.id, amount: amount, flagged: true, category: t.category });
      } else {
        result.push({ id: t.id, amount: amount, flagged: false, category: t.category });
      }
    }
  }
  return result;
}
```

---

## Section 1 — Executive Architectural Summary

This is JavaScript operating in a functional context — a data transformation pipeline over a collection — but written with an imperative mindset. The logic is correct and the intent is legible. The structural issues are about paradigm mismatch: the code uses the idioms of a language without the practices that make those idioms safe and composable. The refactoring path is mechanical and low-risk.

---

## Section 2 — Deep Structural Diagnosis

The most significant issue is the mutation of input data: `t.flagged = true` modifies the original transaction object passed into the function. In a functional pipeline, this is the primary source of action-at-a-distance bugs. The caller passes in a list of transactions and, after the call, those objects have been silently altered. Any other code holding a reference to the same objects now sees the mutation. The fix is to construct new objects rather than modifying existing ones.

The manual `for` loop with an index variable is an imperative pattern that names the mechanics of iteration without expressing the intent of the transformation. The code is doing three distinct things: filtering by status, converting currency, and flagging high-value transactions. Each of these maps cleanly to a declarative pipeline stage — `filter`, `map`, `map`. Written as a pipeline, each stage is independently readable, testable, and replaceable.

The inline comment `// convert to USD` is a DHH smell: the conversion logic is a named concept that has been left anonymous. It belongs in a function called `toUSD` or `normalizeToUSD`. Once extracted, the comment becomes redundant.

Finally, the two branches of the final conditional produce objects with identical shapes but different values for `flagged`. This is a Data Clump pattern hiding a simpler solution: derive `flagged` directly from `amount` without branching.

---

## Section 3 — Operational Refactoring Plan

**Step 1 — Eliminate mutation (Immutability)**
Replace `t.flagged = true` with spread syntax to produce a new object: `{ ...t, flagged: true }`. Never mutate the input.

**Step 2 — Extract `normalizeToUSD` (DHH: Comments as Smells)**
Move the currency conversion into a named function. It now has a single responsibility and can be tested independently.

**Step 3 — Extract `isFlagged` (Minimalism + Clarity)**
Replace the conditional branch with a pure predicate: `const isFlagged = amount => amount > 1000`. The branching disappears.

**Step 4 — Replace the loop with a declarative pipeline (FP: Declarative over Imperative)**
Compose `filter` → `map` → `map` to express the three transformation stages explicitly. The structure of the pipeline mirrors the structure of the business logic.

---

## Section 4 — Refactored Code

```javascript
const normalizeToUSD = (amount, currency) =>
  currency === 'USD' ? amount : amount * getExchangeRate(currency);

const isFlagged = amount => amount > 1000;

const toProcessedTransaction = transaction => {
  const amount = normalizeToUSD(transaction.amount, transaction.currency);
  return {
    id: transaction.id,
    amount,
    flagged: isFlagged(amount),
    category: transaction.category,
  };
};

function processTransactions(transactions) {
  return transactions
    .filter(t => t.status === 'completed')
    .map(toProcessedTransaction);
}
```
