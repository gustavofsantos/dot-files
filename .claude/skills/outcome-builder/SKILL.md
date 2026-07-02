---
name: outcome-builder
description: >
  Shapes a raw idea into an outcome-driven user story with a strong logic-preserving ASSERT anchor.
  Use when you want to define value-centric specifications that prevent LLM mechanism-anchoring.
  Triggers on "outcome story", "outcome-driven", "outcome builder", "build outcome", "novo outcome", or any raw idea to be shaped by outcomes.
disable-model-invocation: true
---

# Outcome Builder

Shapes ideas into **Outcome-Driven Stories** anchored on a strict logical assertion (the **Outcome Anchor**) — keeping a pairing LLM aligned on the *value/outcome* instead of fixating on a pre-decided *mechanism*.

## Phase 1 — Uncover the Outcome

Don't draft yet. Ask up to 3 questions to decouple the **outcome** from the **mechanism**, identifying:

1. **Outcome** — what capability or state transition is achieved (the *value*)
2. **Verification** — the concrete, testable signal that proves success (the *proof*)
3. **Proposed Path** — the initial implementation idea (the *mechanism*)

## Phase 2 — Draft the Outcome Story and Anchor

Lead with the high-contrast **Outcome Anchor** so it constrains later prompts.

```markdown
# Outcome Story: [Short Title]

> [!IMPORTANT]
> **Outcome Anchor:**
> `ASSERT: The system satisfies [desirable outcome] (Verification: [testable condition]), regardless of whether we use [proposed path] or a simpler alternative.`

### Narrative
**In order to** [resolve pain / enable opportunity],
**We will achieve** [desirable outcome],
**Using** [proposed path] (as the default baseline mechanism).

### Acceptance Criteria
- [ ] [Primary Verification Condition]
- [ ] [Secondary Guardrail/Safety Condition]
- [ ] [Boundary Condition/Constraint] (Max 4 total)
```

Rules: criteria must be mechanism-agnostic (use "User receives confirmation", not "Database writes status"). The `ASSERT` line must be single-line and clearly separate outcome from path.

---

## Phase 3 — Decompose into Outcome-Aligned Tasks

Decompose into atomic tasks (max 7). Each must focus on the assertion, leaving room for path adjustment.

```markdown
### Task [N]: [Short Title]

**Outcome Goal:** [How this task moves us closer to the assertion]
**Depends on:** [Previous task / None]
**Scope:**
- Includes: [Logical area or files to touch]
- Excludes: [What to avoid to keep the implementation minimal]
**Done when:**
- [ ] [Verifiable condition — max 2]
```

---

## Phase 4 — Store as issue

Read [references/issue-template.md](references/issue-template.md), fill it (`{title}` slugified; `{id}`/`{today}` resolved by the skill; outcome anchor, narrative, criteria, confirmed tasks), then invoke the `issue` skill to allocate an ID and write the file.
