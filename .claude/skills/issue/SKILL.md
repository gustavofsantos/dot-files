---
name: issue
description: >
  Create or update a tracked work item in ~/engineering/issues/. Trigger only on
  explicit intent to file work: "create an issue", "file a bug", "track this as an issue",
  "new story", "new feature", "/issue", or when another skill says to invoke the issue skill.
  Does NOT trigger on casual code discussion that mentions the word "issue".
---

# issue

A tracked work item is a single markdown file. Everything it produces — notes,
transcripts, spikes, data, diagrams — is a separate file in `~/engineering/artifacts/`,
linked from the issue. Issues move between states; artifacts never move.

```
~/engineering/
├── issues/
│   ├── 2026-08-04-extract-ledger-projection.md      ← active
│   ├── backlog/
│   │   └── 2026-07-22-characterize-fee-rounding.md  ← planned, not started
│   └── done/
│       └── 2026-06-30-retry-storm-in-settlement.md
└── artifacts/
    ├── 2026-08-04-ledger-retry-sequence.md
    └── 2026-06-30-settlement-load-profile.csv
```

Three locations, three states. Moving the file is the only transition. There is no
status field.

`backlog/` → `issues/` → `done/`

## Naming

`YYYY-MM-DD-kebab-case-imperative-phrase` — for issues and artifacts alike.

The date is the creation date and never changes. No sequential numbers: allocating
one requires enumerating the whole namespace, which races across concurrent sessions
and fails in weaker agents. The clock needs no coordinator.

On an artifact, the date prefix is what makes staleness visible in a flat folder.
On an issue, it means a stale link still resolves by globbing the date prefix if the
title is later revised.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/issues/ 2>/dev/null` — searches
   active, backlog and done. If a similar item exists, update it instead of creating
   a duplicate. This is the only guard against near-duplicate names; do not skip it.
2. **Create the file** — in `issues/` if starting now, in `issues/backlog/` if
   filing for later.
3. **Decide what kind of work this is** — bug, investigation, prototype,
   characterization, implementation, or something with no name yet. This decision
   selects which optional sections to add. Do not record it as a field.
4. **Write the kernel** (below). Add optional sections from
   [references/sections.md](references/sections.md) as the work warrants.
   Fill missing fields conversationally — ask only what cannot be inferred.

## Kernel

Every issue has exactly these, in this order:

```markdown
---
paths: []            # absolute paths to work in — repo roots, or project dirs
                     # inside a monorepo. List the primary one first.
tags: []             # open vocabulary, for scanning
created: YYYY-MM-DD
---

## Objective
One sentence. What this work is for.

## Context
What situation or observation created this. 2–4 sentences.

## Model
One mermaid diagram: the shape of the work. Before/after where something changes,
the failing path for a defect, the region under question for an investigation.
If the work touches a single point and has no sequence, write
`Single-point change: {what}` and draw nothing.

## Done when
The observable condition that ends this issue. Specific enough to check without
re-reading the whole file.

## Tasks
- [ ] Present-tense imperative, one action, completable in one agent turn

## Artifacts
- [[2026-08-04-ledger-retry-sequence]] — what it is and why it exists
```

Optional sections go between `Tasks` and `Artifacts`, except sections that record
outcomes (`Findings`, `Decision`, `Resolution`), which go after `Artifacts`.

`paths:` locates the work; it does not describe repository structure. A monorepo
project is just a path. Anything needing a git root derives it —
`git rev-parse --show-toplevel` — rather than having it declared here.

## Artifacts

Written to `~/engineering/artifacts/`, date-prefixed, linked from the issue that
produced them. The link is authored in one direction only; the reverse is derived
by the vault, so an artifact needs no knowledge of its issue.

An artifact serving a second issue is simply linked twice — nothing moves, nothing
is promoted.

## Invariants

- **`Done when` must be checkable.** "Investigate the retry path" is not a
  condition; "the retry path's failure modes are written up in an artifact" is.
  A vague `Done when` is design feedback — the work isn't understood yet. Say so
  rather than writing a placeholder.
- **No unlinked artifacts.** Every file written to `artifacts/` is linked from at
  least one issue, with a line saying what it is. An unlinked artifact is invisible
  to later sessions, and unindexed context is worse than no context.
- **Draw structure, write judgment.** Anything that is structure, sequence, state,
  or flow is a diagram. Prose that narrates a call path, a lifecycle, or an ordering
  is a bug — replace it with the diagram it was describing. Rationale, intent,
  hypotheses and decisions stay prose, and stay short. See the diagram vocabulary in
  `references/sections.md`.
- **Prose is budgeted.** No section exceeds one short paragraph. When a section
  wants to grow, the content belongs in an artifact behind an `## Artifacts` line,
  or it wanted to be a diagram. Length is not thoroughness.
- **Issues hold deltas, not system state.** A diagram here describes the change or
  the failing path, and is frozen at close. A diagram of how the system currently
  works belongs in the topology map, not in an issue — it will be wrong within
  weeks and will still look authoritative.
- **Sections are composed, not selected from a fixed set.** The list in
  `references/sections.md` is a vocabulary, not an enum. Add a new section when the
  work needs one; do not force work into an existing shape.

## Closing

Add `## Resolution`, then move the file into `done/`. Artifacts stay where they are.
