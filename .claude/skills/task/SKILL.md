---
name: task
description: >
  Frames a concrete unit of work as a tracked task with an explicit contract, boundary, and
  done-when conditions. Use when the work is well-understood and just needs to be bounded and
  stored — no story shaping or hypothesis needed.
  Triggers on "task", "tarefa", "I need to", "preciso", "do this", "track this",
  or any concrete action that needs a clear contract before execution.
metadata:
  allowed-tools: Read Write Edit
---

# Task

Frames a concrete unit of work into a tracked task with a tight contract and explicit boundaries.

---

## Phase 1 — Write the contract

Ask: "What must be delivered? Describe it without mentioning how."

Refine until the contract is a statement of outcome, not a description of steps.
If the user describes implementation steps, ask: "What would be true in the world once this is done?"

---

## Phase 2 — Draw the boundary

Ask: "What is explicitly in scope? What is explicitly out of scope?"

Both sides are mandatory. A task without an explicit exclusion is a task with invisible scope creep.

---

## Phase 3 — Define done

Ask: "What verifiable condition proves this task is complete?"

Max 3 conditions. More means the task should be split or promoted to a story.

---

## Phase 4 — Store as issue

Once confirmed, store the task using the `issue` skill.

Read [references/issue-template.md](references/issue-template.md) and fill it with the contract, boundary, and done-when conditions.

Then invoke the `issue` skill to allocate an ID, link facts, and write the file.
