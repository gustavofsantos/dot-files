---
name: hypothesis
description: >
  Frames an investigation as a falsifiable hypothesis with explicit questions, a method,
  and done-when conditions. Use when something is unknown and needs to be found out before
  (or instead of) building. The `dead-reckoning` skill executes the investigation;
  findings become facts via the `fact` skill.
  Triggers on "hypothesis", "hipótese", "investigate", "I want to understand", "find out",
  "not sure if", "test whether", or any question that needs to be answered before building.
metadata:
  allowed-tools: Read Write Edit
---

# Hypothesis

Frames an open question as a falsifiable hypothesis before investigation begins.

---

## Phase 1 — State the belief

Ask one question: "What do you believe is true, and what made you believe it?"

Help the user express it as: "We believe that {X} is true because {Y}."

If the user doesn't have a belief yet — just a question — that's fine. Frame the null hypothesis: "We don't yet know whether {X} is true."

---

## Phase 2 — Make it falsifiable

Ask: "What would you need to see to confirm this? What would disprove it?"

For each answer, extract:
- **Q** — the concrete question
- **Confirming signal** — the observation that would answer it yes
- **Falsifying signal** — the observation that would answer it no

Max 5 questions. If more are needed, the hypothesis is too broad — propose splitting it.

---

## Phase 3 — Define the method

Ask: "How do you plan to investigate this? What tools or sources will you use?"

Record the approach as a list of methods and what each will reveal. Flag if any method is unlikely to produce a falsifiable result.

---

## Phase 4 — Bound the scope

Ask: "What is this investigation explicitly NOT trying to answer?"

This becomes the Off-limits section — prevents scope creep during `dead-reckoning`.

---

## Phase 5 — Store as issue

Once confirmed, store the hypothesis using the `issue` skill.

Read [references/issue-template.md](references/issue-template.md) and fill it with the hypothesis statement, questions, method, off-limits, and done-when conditions.

Then invoke the `issue` skill to allocate an ID, link facts, and write the file.
