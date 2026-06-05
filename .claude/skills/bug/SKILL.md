---
name: bug
description: >
  Frames a bug report into a tracked issue with reproduction steps, root cause hypothesis,
  and fix scope. Use when something is broken and needs to be investigated and fixed.
  Triggers on "bug", "broken", "not working", "regression", "fix this", "erro", "quebrado",
  or any description of unexpected behavior.
metadata:
  allowed-tools: Read Write Edit
---

# Bug

Frames a broken behavior into a tracked issue with a clear reproduction path and fix scope.

---

## Phase 1 — Capture the broken behavior

Ask up to 3 questions to nail the reproduction and scope:

1. **What breaks** — what is the symptom, not the guess about cause
2. **Reproduction** — exact steps to trigger it reliably; if intermittent, frequency and conditions
3. **Expected vs actual** — what should happen, what does happen instead

If the user has a hypothesis about the root cause, record it separately — don't let it collapse the problem description.

---

## Phase 2 — Scope the fix

Once the reproduction is clear:

1. **Root cause** — confirmed or hypothesized; mark clearly which
2. **Fix scope** — which files or areas will change; bound it tightly
3. **Off-limits** — what must not change to avoid regressions

Ask: "Is the root cause confirmed or a hypothesis? Are there areas of the code you want to avoid touching?"

---

## Phase 3 — Acceptance criteria

Write the criteria that prove the bug is fixed:
- Primary: reproduction steps no longer exhibit the broken behavior
- Secondary: regression guards (related paths that must keep working)

Max 4 criteria. More means the scope is wider than a single bug fix.

Present and ask: "Does this capture the fix? Are there other areas we need to guard against regression?"

---

## Phase 4 — Store as issue

Once confirmed, store the work using the `issue` skill.

Read [references/issue-template.md](references/issue-template.md) and fill it with the reproduction steps, root cause, fix scope, off-limits, and acceptance criteria.

Then invoke the `issue` skill to allocate an ID, link facts, and write the file.
