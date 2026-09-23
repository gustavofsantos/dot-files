---
name: issue
description: >
  Create or update a tracked work item in ~/engineering/issues/. Only on explicit intent to
  file work ("create an issue", "file a bug", "new story", "/issue") or a handoff from another
  skill, not on casual mentions of the word "issue".
---

# issue

One Markdown file per work item in `${ENGINEERING_HOME:-$HOME/engineering}/issues/`. It owns
the work delta, tasks, and completion state. It links raw evidence in `artifacts/` and
durable answers in `spikes/`, but does not copy them.

State is location only, with no status field: `issues/backlog/` → `issues/` → `issues/done/`.
Name files `YYYY-MM-DD-kebab-case-imperative-phrase`. The date is the creation date and never
changes. Never use sequential numbers.

## Loop

1. **Search first.** Run `rg -il 'term' "${ENGINEERING_HOME:-$HOME/engineering}/issues/"`. If
   a match exists, update it instead of creating a duplicate.
2. Create the file in `issues/` (starting now) or `issues/backlog/` (later).
3. Write the kernel. Add optional sections from
   [references/sections.md](references/sections.md) as the kind of work needs them. Ask only
   for what you cannot infer.

## Kernel

```markdown
---
paths: []            # absolute work paths (repo roots or monorepo subdirs), primary first
project:             # optional project brief slug; members.sh derives the reverse
tags: []
created: YYYY-MM-DD
---

## Objective
One sentence.

## Context
2–4 sentences on what created this.

## Model
One mermaid diagram: before/after, the failing path, or the region in question.
Or `Single-point change: {what}` with no diagram.

## Done when
An observable, checkable condition.

## Tasks
- [ ] Imperative, one action, one agent turn

## Artifacts
- [[2026-08-04-ledger-retry-sequence]] — what it is and why it matters
```

Optional sections go between `Tasks` and `Artifacts`. Outcome sections (`Findings`,
`Decision`, `Resolution`) go after `Artifacts`.

## Invariants

- `Done when` must be checkable. A vague one means the work isn't understood yet. Say so.
- Every file written to `artifacts/` is date-prefixed and linked from at least one issue with
  a reason. Links go one way only: from the issue to the artifact.
- Draw structure and write judgment. Sequences, states, and flows are diagrams. Rationale and
  decisions stay as short prose.
- No section exceeds one short paragraph. Push overflow into an artifact.
- Issues hold deltas. Current workflows belong to `biz-workflows`.

## Closing

Add `## Resolution`, then move the file to `done/`. Artifacts stay where they are.
