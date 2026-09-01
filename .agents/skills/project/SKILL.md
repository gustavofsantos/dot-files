---
name: project
description: >
  Create or update a project brief in ~/engineering/projects/ when the user explicitly asks.
  The brief holds stable project context and links to canonical artifacts, not work status.
---

# Project

A project brief gives a new agent the stable context that no single issue owns. It is not a
tracker and does not copy canonical workflow diagrams.

The vault is `${ENGINEERING_HOME:-$HOME/engineering}`. Store briefs in `projects/`.
A campaign can move to `projects/done/`. A domain brief stays open while the team owns it.

## Operating loop

1. Search `projects/` for the topic. Update an existing brief instead of making a duplicate.
2. For a new brief, run `scripts/new.sh "<slug>"`. Use a stable
   `kebab-case-noun-phrase` with no date.
3. Fill only established facts. Leave a section empty instead of guessing.
4. Run `scripts/members.sh "<slug>"` when current issue membership matters. Do not copy that
   derived list into the brief.

## Sections

| Section | Holds |
|---|---|
| Objective | One sentence that states the project's stable purpose |
| Glossary | Project-only terms, one per line |
| Workflow context | Links to the relevant standalone files owned by `biz-workflows` |
| Data map | Each dataset, what one row means, and non-obvious traps |
| Standing questions | Open falsifiable unknowns |
| Key artifacts | The few canonical files worth reading cold |

## Boundaries

- The project brief owns stable summary and context. An `issue` owns a work delta, tasks,
  and completion state.
- Do not embed a second workflow topology. Link the relevant `workflows/*.mermaid` files and
  add only the context needed to explain why they matter.
- Do not list issues. Each issue names its project, and `members.sh` derives the reverse.
- Curate key artifacts. Do not turn the section into an index.
- Phrase each standing question so `spike` can settle it. When settled, update the relevant
  stable section and keep the spike as evidence.
- Keep each prose section to one short paragraph. Link larger material instead of copying it.

Move a finished campaign brief to `projects/done/`. Do not move its issues, evidence, spikes,
or workflows.
