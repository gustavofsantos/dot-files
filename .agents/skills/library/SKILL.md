---
name: library
description: The librarian's manual for the private domain library — entry format, workflow diagrams, and the `library` script. Loaded by the `librarian` agent; not for the main agent.
disable-model-invocation: true
---

# Library

A private folder of small entries about the systems and business domain we work on, across
projects. One concept per entry, every entry tied to sources that can be checked. Business
workflows are entries that carry a diagram. The `librarian` agent is the only reader and writer.

Root: `${LIBRARY_HOME:-$HOME/librarian/library}`. Diagrams: `${WORKFLOWS_HOME:-$HOME/librarian/workflows}`.
This is deliberately apart from the engineering vault (`ENGINEERING_HOME`). Never edit either by
hand; go through the script, which validates and pins.

The script is `$HOME/.agents/skills/library/scripts/library`, written `library` below. Always
run it by that full path; it is not on `PATH`.

| Command | Use |
|---|---|
| `library search [-n N] <term>...` | Ranked hits, one line each: `id  score  flag  confidence  title — summary`. Substring match, so `settle` finds `settlement`. A workflow shows `[workflow]`. |
| `library show [--raw] <id>` | The entry, its diagram, then the state of each source. `--raw` prints the entry alone, to edit and `put` back. |
| `library list` | Every entry: `id  flag  confidence  title`. |
| `library put <id> [--update] [--diagram FILE]` | Entry on stdin. Validates, pins sources and diagram, stamps `verified`. Refuses an existing id without `--update`. |
| `library reverify <id>` | Re-pin and re-stamp, content unchanged. Only after you re-read the sources and the entry still holds. |
| `library check [id...]` | Stale sources or diagrams and broken `related` links. Exit 1 if any. |

**Flag** is the word to check before trusting an entry: `ok`, `stale` (a source or the diagram
changed or vanished since it was pinned), `unchecked` (a source is a URL or otherwise cannot be
hashed), `deprecated`.

There is no delete. A concept that is gone becomes `status: deprecated`.

## Entry

```markdown
---
title: Settlement batch
aliases: batch, sweep
tags: ledger, payments
summary: One sentence, at most 200 characters. Shown in search, so make it carry the answer.
confidence: documented
status: current
related: ledger-entry, settlement-cutoff
source: ~/work/payments/docs/adr/0007-settlement.md
source: ~/work/payments/src/settle.clj
---
Free text, at most 40 lines.
```

- `title`, `summary`, `confidence` and at least one `source` are required. `verified` is
  stamped, never typed. Other keys are refused.
- `source:` is one absolute or `~` path, or one URL. No spaces, no notes. Local files are
  pinned by hash on `put`. Qualify nothing else: the path is the evidence entry point.
- `confidence`, by how the claim is known — never promote one level on a hunch:
  - `documented` — a doc, ADR, schema or comment states it.
  - `verified` — observed by running something: a test, a query, a reproduction.
  - `inferred` — read from code and reasoned about. Say in the body what would confirm it.
- A new entry may not reuse the id, title or alias of another. Update that one instead.
- Ids are lowercase hyphen-case nouns for the concept. Add a qualifier only to split one term
  with two meanings (`ledger-settlement`, `bank-settlement`).

## What an entry says

A map legend, not documentation. Say only what a competent agent would likely get wrong without
it, in whichever of these the concept needs:

- local vocabulary, and the smallest conceptual model
- a few stable invariants
- ownership boundaries: source of truth, decision owner, derived state, repair paths
- plausible but wrong readings, under **Do not infer**

Encode conclusions that are expensive to rediscover. Link evidence that is cheap to fetch.
Treat code names as claims. Prefer authoritative evidence at decision boundaries: schemas,
transaction functions, events, integration tests, ADRs. Keep documented fact, verified
behavior, and inference apart; never promote an inference to an invariant. Leave out method,
walkthroughs, history, exhaustive file lists.

One capability too wide for 40 lines is several entries joined by `related`. Durable domain
facts only: not task status, not opinions, not how to do the task.

## Workflow entries

A workflow is an entry with a diagram: the entry's `summary` states the one question the
diagram answers, and its body names the stages in words. The diagram is a standalone
`<id>.mermaid` file, written by `library put <id> --diagram FILE`. The file holds Mermaid
source only: no code fence, no frontmatter, no prose.

A diagram from anywhere else comes in with `--diagram FILE`, which copies it into the diagrams
folder as `<id>.mermaid`; the original is left untouched. One that already sits in the diagrams
folder can be adopted by putting `diagram: name.mermaid` in the entry instead. It is pinned in
place, not copied.

- The default view is a business-level, end-to-end panorama: upstream trigger, cross-system
  handoffs, downstream outcome. `flowchart TB` with system or phase subgraphs, at most about 20
  nodes and five numbered stages.
- Keep implementation symbols (functions, handlers, jobs, flags) out of the panorama. Requested
  depth is its own entry (`<id>-detail`, `related: <id>`). `sequenceDiagram` for cross-boundary
  choreography. One abstraction level per diagram.
- Follow existing ids, orientation, labels and styles. Add no new taxonomy. Use canonical
  business terms from the brief or authoritative sources.
- Verify every edge against code, schemas, events, logs or documents, and list those as
  `source:`. Never invent an actor, state, rule or umbrella term. If the evidence cannot settle
  a name or edge, leave it out and report the gap.
- Update with the smallest coherent change: `show --raw`, edit, `put --update`. Validate the
  syntax with the closest available Mermaid parser before `put`.
