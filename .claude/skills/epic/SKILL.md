---
name: epic
description: >
  Frames a large initiative into a tracked epic issue with a clear objective, motivation,
  and a decomposed set of child issues. Use when the work is too large for a single story
  or bug and needs to be broken into multiple tracked issues.
  Triggers on "epic", "large feature", "initiative", "projeto grande", "grande mudança",
  or any description of work that spans multiple issues or releases.
metadata:
  allowed-tools: Read Write Edit
---

# Epic

Frames a large initiative into a tracked epic with a clear objective and a decomposed set of child issues.

---

## Phase 1 — Understand the initiative

Ask up to 3 questions to scope the initiative:

1. **Objective** — what new capability exists when this epic is done? One sentence.
2. **Motivation** — why now? What breaks or stays broken if we skip it?
3. **Boundary** — what is explicitly out of scope?

If the scope feels open-ended, ask: "What is the smallest version of this that would be worth shipping?"

---

## Phase 2 — Decompose into child issues

Break the epic into child issues. Each child must be:
- Independently trackable (has its own ID)
- Completable without the others being done first (or declare the dependency explicitly)
- Framed with the right skill: `user-story-builder`, `outcome-builder`, `bug`, or `hypothesis`

List the children as titles + intended framing skill. Ask: "Does this decomposition cover the full epic? Are any children too large and need further splitting?"

Do not write child issues now — that happens when each child is worked.

---

## Phase 3 — Done-when conditions

Define what it means for the epic to be closed:
- All child issues done (automatic)
- Any integration or system-level condition that only holds when all children are complete

Ask: "Is there a system-level check that only passes once all children are done?"

---

## Phase 4 — Store as issue

Once confirmed, store the epic using the `issue` skill.

Read [references/issue-template.md](references/issue-template.md) and fill it with the objective, motivation, child issue list, off-limits, and done-when conditions.

Then invoke the `issue` skill to allocate an ID, link facts, and write the file.
