---
name: project
description: >
  Create or update a project brief in ~/engineering/projects/ — the durable context that
  issues and spikes orbit: glossary, topology, data map, standing questions. Trigger only
  on explicit intent to open or update a brief: "create a project", "open a project brief",
  "add this to the <name> project", "/project", or when another skill says to invoke the
  project skill. Does NOT trigger on casual use of the word "project" to mean a repository,
  a codebase, or a unit of work.
---

# project

A project is one markdown file. It holds the durable context that no single issue
owns: the vocabulary, the map of the system, the shape of the data, and the open
unknowns.

Write the brief for an agent that reads it cold. The brief is not a tracker. It
carries no progress, no status, and no list of its issues.

```
~/engineering/
├── projects/
│   ├── database-write-performance.md      ← open
│   └── done/
│       └── ledger-cutover-2025.md
├── issues/
├── artifacts/
└── spikes/
```

Two locations, two states. Moving the file is the only transition. There is no
status field.

A campaign ends, so its file moves to `done/`. A domain that the team owns has no
end date, so its file never moves. Both use the same shape.

## Naming

`kebab-case-noun-phrase`. The slug alone, with no date prefix.

An issue carries a date because a flat folder must show staleness. A project is
different. Its name is a key: other files point at it, and a reader types it. The
key must stay stable when the title changes, so the name holds no date.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/projects/`. If a brief already
   covers this topic, update it. Do not open a second brief for the same topic.
2. **Create the file** — `scripts/new.sh "<slug>"` prints the path and seeds the
   sections.
3. **Fill what you know** — leave a section empty rather than guessing. An empty
   Glossary is honest. A wrong Glossary costs every later session.
4. **List the work** — `scripts/members.sh "<slug>"` prints the issues that name
   this project, active first. Read it when you need the current state of the
   work. Do not copy the output into the brief.

## Sections

| Section | Holds |
|---|---|
| Objective | One sentence. What this project is for. |
| Glossary | The vocabulary, in plain words. One term per line. |
| Topology | How the system works today. Mermaid. |
| Data map | Each dataset, what one row means, and the traps. |
| Standing questions | The open unknowns. |
| Key artifacts | The few files worth reading cold. |

## Invariants

- **The brief holds system state, not deltas.** An issue holds the change. The
  project holds how the system works today. This is the opposite rule to the issue
  skill, and it is deliberate.
- **The brief holds no list of its issues.** An issue names its project in its
  frontmatter, and `members.sh` derives the reverse. A hand-written list rots
  within weeks.
- **Key artifacts is curation, not an index.** List the files a new reader must
  read. Do not list every file the project produced.
- **A standing question is falsifiable.** Phrase it so that a spike can answer it
  wrong. A topic is not a question.
- **An answer moves up.** When a spike answers a standing question, copy the answer
  into Glossary, Topology, or Data map, then tick the question. The spike file stays
  where it is and keeps the evidence.
- **Prose is budgeted.** No section is longer than one short paragraph. Content that
  wants to grow belongs in an artifact, linked from Key artifacts.

## Closing

Move the file into `projects/done/`. Issues, artifacts and spikes stay where they
are. `new.sh` makes `done/` up front, so the move cannot rename the brief.

A domain has no end date. Leave its file in `projects/` for as long as the team
owns the system.
