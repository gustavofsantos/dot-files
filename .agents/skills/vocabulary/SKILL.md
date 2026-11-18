---
name: vocabulary
description: >
  Speak the user's ubiquitous language instead of coining terms when a request materially
  depends on shared domain meaning. Curate the semiotic triangles in ~/GLOSSARY.md only when
  the user explicitly asks.
---

# Vocabulary

Speak the user's **ubiquitous language**: the one set of terms the user, their code, and their
documents share. Name things the way the user already names them. Do not invent a term, an
abbreviation, or a label for a concept that already has one. Do not add jargon the user did
not use.

## The glossary holds semiotic triangles

`$HOME/GLOSSARY.md` holds one **semiotic triangle** per entry, bounded to the user's
ubiquitous language:

- **Symbol** — the term the user says, with its aliases.
- **Concept** — the meaning the user holds when they say it.
- **Referent** — the thing in the user's world the term points to: the record, table, event,
  service, document, or real-world object.

A term is canonical only when all three corners are established. The corners keep distinct
things distinct:

- Two symbols for one concept and referent are **aliases**. Use the preferred one.
- One symbol for two concepts is a **homonym**. Name which concept you mean, or ask.
- A concept with no referent, or a referent with no symbol, is a **gap**. Ask the user to
  close it; do not fill it with a coined term.

The boundary is the user's language, not general usage. A dictionary meaning, a framework's
meaning, or a meaning from another domain does not override the user's concept for the same
symbol.

## Where the ubiquitous language comes from

Use whichever of these is available in the current session, in this order:

1. The user's own words in the conversation.
2. `$HOME/GLOSSARY.md` — the canonical triangles, across projects.
3. The project brief in `projects/<slug>.md` — its Glossary holds project-only terms.
4. Canonical workflow diagrams in `workflows/`, and spikes in `spikes/`.
5. The names in the area's code, schema, docs, and tickets — mostly referents.

Search only for the terms at hand and read only the matching entries. A source that does not
exist is skipped, not created. When sources disagree, prefer the higher one and mention the
conflict. When no source names the concept, ask the user for the term instead of making one
up. Use the preferred symbol and preserve established distinctions; do not swap a term for a
synonym to vary the prose.

Reading the glossary does not permit a change to it.

## Curate on explicit request

Creating, renaming, merging, splitting, retiring, or reorganizing entries requires explicit
user intent. Then:

1. Search the symbol, aliases, and nearby concepts before editing.
2. Establish each corner from the user or an authoritative source. Leave a corner the
   evidence cannot settle as an open question; never invent a meaning or a referent.
3. Merge entries that share concept and referent. Split an entry whose symbol carries two
   concepts.
4. Make the smallest coherent edit and preserve unrelated or concurrent changes.
5. Search references before and after a rename.
6. Report entries created, changed, merged, split, or retired.

Keep entries alphabetized by preferred symbol, one per concept:

```markdown
### Preferred term
- **Symbol:** Preferred term (ABBR; alias, alias)
- **Concept:** One sentence on what the user means by it. Optional boundary: what it is not.
- **Referent:** What it points to, e.g. an `orders` table row, the `OrderPlaced` event, the signed PDF.
```

Keep a retired symbol as an alias when future searches need it. Do not record secrets,
transient task facts, or generic dictionary definitions.

Keep the glossary at `$HOME/GLOSSARY.md`, never in the engineering vault or a repository.
When a project term becomes cross-project language, add its triangle there. Let the project
brief link or summarize it without creating a competing definition.
