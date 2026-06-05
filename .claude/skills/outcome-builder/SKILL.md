---
name: outcome-builder
description: >
  Shapes a raw idea into an outcome-driven user story with a strong logic-preserving ASSERT anchor.
  Use when you want to define value-centric specifications that prevent LLM mechanism-anchoring.
  Triggers on "outcome story", "outcome-driven", "outcome builder", "build outcome", "novo outcome", or any raw idea to be shaped by outcomes.
metadata:
  allowed-tools: Read Write Edit
---

# Outcome Builder

This skill shapes ideas and requirements into **Outcome-Driven Stories** centered around a strict logical assertion (the **Outcome Anchor**). This keeps LLMs in pairing environments aligned on the *value/outcome* rather than getting stuck on a pre-determined *mechanism/implementation*.

---

## Phase 1 — Uncover the Outcome

Do not draft the story yet. Ask up to 3 surgical questions to decouple the **Desired Outcome** from the **Proposed Mechanism**. We must identify:

1. **Outcome:** What new capability or state transition is achieved? (The *value*)
2. **Verification:** What concrete, testable signal proves we succeeded? (The *proof*)
3. **Proposed Path:** What was the initial implementation idea? (The *mechanism*)

*Example prompt to the user:*
> "Let's capture the outcome. What is the core capability we need to enable, how will we prove it works, and what is your initial idea for how to build it?"

---

## Phase 2 — Draft the Outcome Story and Anchor

Once the outcome, verification, and path are clear, draft the story. It must lead with the high-contrast **Outcome Anchor** to serve as a logical constraint for subsequent prompts.

Format:

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

### Rules for Drafting
* **Mechanism-Agnostic Criteria:** Do not include implementation steps in the criteria (e.g., use "User receives confirmation" instead of "Database writes status to active and sends SendGrid webhook").
* **Anchor Rigor:** Ensure the `ASSERT` line is clean, single-line, and clearly distinguishes the outcome from the path.

Present the draft and ask: *"Does this outcome assertion and verification define success accurately? Can we find a simpler path?"*

---

## Phase 3 — Decompose into Outcome-Aligned Tasks

Decompose the story into atomic tasks (max 7). Each task must focus on building towards the assertion, leaving room for path adjustment if friction is met.

Template per task:

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

Present the tasks and ask: *"Does this breakdown make sense? Are we over-engineering any step?"*

---

## Phase 4 — Store as issue

Once tasks are confirmed, store the work using the `issue` skill.

Read [references/issue-template.md](references/issue-template.md) and fill it with:
- `{title}` — slugified story title
- `{id}` and `{today}` — resolved by the issue skill
- Outcome anchor, narrative, acceptance criteria, and confirmed tasks

Then invoke the `issue` skill to allocate an ID, link facts, and write the file.
