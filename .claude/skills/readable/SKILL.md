---
name: readable
description: "Reviews Kotlin code for readability, guided by the principle that code should hide mechanics and expose intention. Operates on a specified scope: file, class, function, or diff. Works in two phases — proposes a Change Contract for human review, then applies only approved changes. Activate when the user says things like 'readable', '/readable', 'review for readability', 'make this more readable', 'this is hard to read', 'hide the mechanics here', or points at Kotlin code and asks for a readability pass."
disable-model-invocation: true
---

# Readable

Guiding principle: **code should hide the mechanics and expose the intention.**

Two phases. Never apply changes before explicit human confirmation.

---

## Activation

Ask if the user hasn't specified:

> "What's the scope? File, class, function, or diff?"

Before analyzing, read both reference files:
- `references/heuristics.md` — readability heuristics (names, functions, structure, idioms)
- `references/syntax-sugar.md` — Kotlin syntax sugar cases

---

## Phase 1 — Contract

Analyze the scope against the heuristics. Produce a Change Contract.

```
## Readability Contract

**Scope:** {file | class | function | diff}
**Target:** {path or name}

---

### [R-01] {Short title}
**Location:** {function or class name}
**Problem:** {One sentence: what forces the reader to reconstruct intent from mechanics}
**Proposed change:** {What will be done and why it exposes intention better}

**Before:**
```kotlin
// current code
```
**After:**
```kotlin
// proposed code
```
```

After the full contract, ask:

> "Approve all, reject all, or list which items to apply (e.g. 'apply R-01, R-03')."

Do not proceed until the human responds.

---

## Phase 2 — Execute

Apply only the approved items using Read/Edit/Write tools.

After editing, report what was applied. Flag any item that couldn't be applied without
touching behavior — the human decides those explicitly.

---

## Diff mode

Apply heuristics only to changed lines and their immediate context. If a readability
problem existed before the diff and the diff is a clean opportunity to fix it, include
it marked as **[pre-existing]** — opt-in, never applied by default.

---

## Constraints

- Do not change behavior or logic
- Do not introduce abstractions that don't already exist in the codebase
- Do not rename public API members without marking **[API impact]** in the contract
- Do not review for correctness, performance, security, or architecture
- Do not apply changes without explicit approval
