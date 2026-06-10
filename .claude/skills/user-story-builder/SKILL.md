---
name: user-story-builder
description: >
  Shapes a raw idea into a user story, then breaks it into scoped development tasks.
  Use whenever a raw idea needs to become a story, or a ready story needs to be broken
  into tasks. Triggers on "quero implementar", "monta uma story", "tenho um problema
  que", "quebra essa história em tasks", "define as tasks para", "como implementar essa
  história", or any raw idea or ready story before development begins. Always use before
  starting implementation.
disable-model-invocation: true
---

# User Story

Three phases in sequence: **shape** a raw idea into a story, **plan** it into tasks, then **store** it as a tracked issue.

Entry point:
- Raw idea → start at Phase 1
- Story already exists (has As/I want/So that + criteria) → skip to Phase 3

Read [references/heuristics.md](references/heuristics.md) for quality signals and split heuristics.

---

## Phase 1 — Understand the problem

Don't write the story yet. Ask surgical questions — max 3 per round — until you have:

1. **Who** — the real user who benefits (role/persona, not "the system")
2. **What** — the concrete action, not the technical mechanism
3. **Why** — the business or technical value that justifies the effort
4. **Done when** — the observable criterion that indicates completion

If the "why" is unclear, that's always the first question. If scope seems large, ask for the smallest slice that delivers value.

---

## Phase 2 — Draft the story

```
As a [user type],
I want [concrete, small action],
so that [measurable business or technical outcome].

Acceptance criteria:
- [ ] [observable condition]
```

Rules: each criterion must be verifiable without ambiguity; no implementation criteria; max 5 criteria — more means the story is too large, propose a split; include what's explicitly out of scope if there's risk of expansion.

---

## Phase 3 — Decompose into tasks

Confirm you have: As/I want/So that, acceptance criteria, and what's out of scope. Ask if any is missing.

Break into atomic tasks (max 7; more means story needs a split):

```
### Task [N]: [short title]

**Goal:** [one sentence]
**Depends on:** [previous task / none]
**Scope:**
- Includes: [what will be touched]
- Excludes: [what must NOT be touched]
**Done when:**
- [ ] [verifiable condition — max 3]
```

---

## Phase 4 — Store as issue

Read [references/issue-template.md](references/issue-template.md), fill it (`{title}` slugified; `{id}`/`{today}` resolved by the skill; story, criteria, out-of-scope, confirmed tasks), then invoke the `vault` skill to allocate an ID, link facts, and write the file.
