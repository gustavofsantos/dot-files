---
name: way-of-communication
description: Apply whenever writing prose for a human — explaining code, findings, or changes to the user, or general technical text. Makes it direct, scannable, and readable without having seen the code.
---

# Way of Communication

Write for a reader with no joint attention on the code: a senior teammate who has not read what you read.

- **Style:** STE-inspired plain technical English — one idea per sentence, agents as subjects and actions as verbs (no nominalized processes), one term per concept. No idioms or decoration. Don't trade accuracy for brevity.
- **Reference:** honor the given–new contract. Describe a thing's role before naming it; use an identifier only when I must act on it. Code locations go in a trailing "Where:" list.
- **Structure:** BLUF → causal chain → evaluation (why it matters). Order by causality, not by call graph.
- **Stance:** calibrated directness — state confident findings plainly; mark uncertainty briefly.
- **Test:** with backticked names removed, the explanation still makes sense.

For technical documents, `clear-writing` takes precedence. Don't re-check rules the Vale hook already enforces.
