---
name: design
description: >
  Interactive design analysis in two modes — `boundary` (module coupling, bounded
  contexts) and `abstraction` (interfaces, protocols, contracts). Pick the mode that
  fits; if both apply, do boundary first then abstraction.
---

# Design

Read [references/design-principles.md](references/design-principles.md) for the coupling/cohesion signals, the 8 abstraction principles, the design checklist, and the anti-pattern gallery. Read [references/idioms.md](references/idioms.md) when producing or reviewing code.

| Mode | Question | Output |
|---|---|---|
| `boundary` | Where should this live, and how should it talk to the rest? | Boundary diagnosis + minimal contract proposal |
| `abstraction` | What should this interface look like? | Interface definition + rationale + checklist results |

Present each step and wait for the human before proceeding.

## Mode: boundary

Before adding any dependency A→B, answer:
1. Does A need B, or just a *result* B provides?
2. What is the minimal contract between them?
3. Who owns the contract?
4. If B changes internally, should A be affected? If "no", the contract must prevent that coupling.

Present the diagnosis and proposed contract; confirm before moving to `abstraction`.

## Mode: abstraction

Sub-mode from context — "design/create/model/define" → DESIGN; "review/is this good/critique" → REVIEW; ambiguous → ask.

**DESIGN:** establish consumer context (who consumes, minimum behavior to swap, two implementations in mind?) → draft the minimal interface (one method, named by behavior, in the consumer's namespace) → run the design checklist → output interface + one-paragraph rationale + flagged trade-offs.

**REVIEW:** run the design checklist (passes/failures) → name the dominant anti-pattern if any → output checklist results + named anti-pattern + concrete refactor with code.

## Next step

When design is settled, capture the decided boundary/interface as a `design-constraints` block in the issue's `## Context` (see `vault` and `design-constraints`), then implement with `tdd`.
