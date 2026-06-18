# Engineering knowledge base

`~/engineering/` holds durable artifacts from every project. Consult it before
reading source code — the signal is already distilled.

The vault has **two axes** (see issue 017):

- **Conceptual knowledge** nests by **domain** as a tree of *folder-notes* —
  `Domain.md` sits beside a `Domain/` folder holding that domain's child concepts
  and sub-domain folder-notes. The folder a note lives in *is* its parent
  (containment); there is no `Parent:` field for the domain axis. Shallow (2–3
  levels). One canonical home per concept, chosen by ownership — link from the rest,
  never duplicate.
- **Work artifacts** stay in **type folders** (`issues/`, `spikes/`, `facts/`),
  tagged by domain and linking *into* the domain tree.

| File/Dir | Purpose |
|----------|---------|
| `Domain.md` + `Domain/` | Domain folder-note (overview/map) beside its child concepts |
| `Domain/Concept.md` | Atomic concept note — one idea, ≤150 words, flat `[[wikilinks]]` |
| `issues/NNN-*.md` | Tracked work: `## Objective`, `## Scope`, `## Tasks` |
| `spikes/NNN-*.md` | Research: `## Answer`, `## Evidence` |
| `facts/FACT-NNN-*.md` | Code-anchored claims: `confidence`, `## Statement`, `## Evidence` |
| `thinking/*/` | `progress.md`, `flush.md` from thinking sessions |

**Relationships are labeled links, not folders.** The tree carries containment; the
navigable relationship graph lives in **`## Relationships` sections on folder-notes**,
written as labeled `[[wikilinks]]` (`depends on`, `realized by`, `triggers`, …) so it's
greppable *with its meaning*. Concept notes have no headers — their links are flat
associative `[[wikilinks]]`, so put structural/cross-domain relationships on the owning
domain's folder-note. Wikilinks resolve by basename, so moving a note between folders
never breaks them.

## Retrieval protocol

On any non-trivial task, before reading source files:

1. **Orient** — list the domain catalog (depth 1), then *descend* into the relevant
   domain folder-note, whose `## Concepts` / `## Relationships` lists walk you down:
   ```bash
   fd -e md -d 1 . ~/engineering              # the catalog: one Domain.md per domain
   cat ~/engineering/DOMAIN_MAP.md 2>/dev/null   # legacy map — read if still present
   ```
   Don't list the whole tree — depth-1 + descent is the progressive disclosure that keeps
   this navigable at hundreds of notes.
2. **Search** — `rg -il 'term1|term2' ~/engineering/ -g '*.md' -l 2>/dev/null`
3. **Peek** — extract the key section from a hit:
   ```bash
   # Concept/domain note — skip frontmatter
   awk '/^---$/{fm++;next} fm==1{next} NF{print}' file.md | head -6
   # Issue — Objective section
   awk '/^## Objective/{p=1;next} /^## /{p=0} p&&NF' file.md | head -4
   # Spike — Answer section
   awk '/^## Answer/{p=1;next} /^## /{p=0} p&&NF' file.md | head -4
   ```
4. **Trace** — follow labeled `[[wikilinks]]` to neighbours; `rg -l '\[\[<Note>\]\]'`
   finds what links back.
5. **Code** — open source files using KB context to guide what matters

Relationships are discovered by traversal — no generated map is maintained. (The
nesting migration is tracked in issue 017; until it completes on a given vault,
`DOMAIN_MAP.md` may still be present and is read in step 1.)

## Citing KB context

Reference notes by `[[Note Title]]` and issues by `NNN`. Code
investigation loads note context as axioms before traversing code.
