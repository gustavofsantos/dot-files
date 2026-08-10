---
name: readable
description: "Reviews a slice of code (usually a diff between two revisions) for readability — hide mechanics, expose intention. Language-agnostic. Two phases: proposes a Change Contract for human review, then applies only approved changes."
---

# Readable

Guiding principle: **code should hide the mechanics and expose the intention.**

The model is not bound to any programming language. It hunts for **bad readability signals** within a **slice** of code — most often a diff between two revisions. The slice, not the language, defines the working surface.

Two phases. Never apply changes before explicit human confirmation.

---

## Scope — work from a slice

A *slice* is the smallest contiguous region that carries one change of intent. It is a diff between two revisions, which is the common case. It can also be a single function or hunk handed over explicitly. The model:

1. Reads the slice (and just enough surrounding context to understand it).
2. Scans for readability signals — see the reference files below — *within the slice and its immediate context*, not across the whole file.
3. Treats everything outside the slice as background. Never proposes changes there unless it is the only way to make the slice readable, and even then flags it.

When no slice is given, ask:

> "What is the slice? A diff (default), or a specific file/class/function?"

Before analyzing, read both reference files — they are language-agnostic:
- `references/heuristics.md` — readability signals (names, functions, structure, idioms)
- `references/syntax-sugar.md` — per-language syntax-sugar calibration (when to keep vs. flag a construct)

---

## Phase 1 — Contract

Analyze the slice against the heuristics. Produce a Change Contract.

<contract>
## Readability Contract

**Slice:** {diff <base..head> | file | class | function}
**Language:** {the source language of the slice}

---

### [R-01] {Short title}
**Location:** {function or class name}
**Problem:** {what forces the reader to reconstruct intent}
**Proposed change:** {what to change, and why it exposes intention}

**Before:**
```{lang}
// current code
```
**After:**
```{lang}
// proposed code
```
</contract>

Use the slice's own language for the code fences (for example `clojure`, `kotlin`, `python`). Never assume a fixed language.

After the full contract, ask:

> "Approve all, reject all, or list which items to apply (for example 'apply R-01, R-03')."

Do not proceed until the human responds.

---

## Phase 2 — Execute

Apply only the approved items, editing the files directly.

After editing, report what was applied. Flag any item that could not be applied without
touching behavior — the human decides those explicitly.

---

## Whole-file scope (not the default)

The human can hand over an entire file, class, or function instead of a diff. The
same signal scan applies. Treat the whole region as the slice. Keep changes minimal and
local to the named region. Do not cascade into unrelated parts of the file.

A readability problem can exist *before* the slice. If the slice is a clean opportunity
to fix it, include it marked as **[pre-existing]**. This is opt-in, never applied by default.

---

## Constraints

- Do not change behavior or logic
- Do not introduce abstractions that do not already exist in the codebase
- Do not rename public API members without marking **[API impact]** in the contract
- Do not review for correctness, performance, security, or architecture
- Do not apply changes without explicit approval
