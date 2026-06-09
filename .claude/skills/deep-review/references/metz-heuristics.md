# Sandi Metz — Structural Heuristics & Flocking Rules

## Structural limits (signals, not laws — ask *why* before fixing)

| Rule | Limit | Chronic violation signals |
|---|---|---|
| Lines/class | ≤ 100 | God Class |
| Lines/method | ≤ 5 | Missing named concept |
| Params/method | ≤ 4 | Data Clump (a hidden object) |
| Objects per controller action | 1 | Orchestration reaching into domain |

Tolerated: mathematically irreducible algorithms, framework-mandated signatures, cases where splitting harms reading cohesion.

**Hard prohibition:** never mask a high parameter count behind a generic hash/dict/map — that hides the real interface and breaks static analysis. The fix is a typed object, not a bag of options.

## Flocking Rules (incremental path to polymorphism, never a leap to a pattern)

1. Find the things most alike. 2. Find the smallest difference. 3. Make the simplest change that removes it. Repeat until the pattern reveals itself — the destination (Strategy, Null Object, …) is discovered, not imposed. Apply this to dispatch-on-type conditionals to reach polymorphism (satisfying LSP + Open-Closed).
