---
name: vocabulary
description: >
  Use the user's canonical names instead of coining terms when a request materially depends on
  shared domain meaning. Curate vocabulary entries only when the user explicitly asks.
---

# Vocabulary

Name things the way the user and their sources already name them. Do not invent a term, an
abbreviation, or a label for a concept that already has a name. Do not add jargon the user
did not use.

## Where canonical names come from

Use whichever of these is available in the current session, in this order:

1. The user's own words in the conversation.
2. `${ENGINEERING_HOME:-$HOME/engineering}/VOCABULARY.md` — canonical cross-project terms.
3. The project brief in `projects/<slug>.md` — its Glossary holds project-only terms.
4. Canonical workflow diagrams in `workflows/`, and spikes in `spikes/`.
5. The names in the area's code, schema, docs, and tickets.

Search only for the terms at hand and read only the matching entries. A source that does not
exist is skipped, not created. When sources disagree, prefer the higher one and mention the
conflict. When no source names the concept, ask the user for the term instead of making one
up. Use the preferred term and preserve established distinctions; do not swap a term for a
synonym to vary the prose.

Reading the vocabulary does not permit a change to it.

## Curate on explicit request

Creating, renaming, merging, splitting, retiring, or reorganizing entries requires explicit
user intent. Then:

1. Search the term, aliases, and nearby concepts before editing.
2. Clarify material ambiguity rather than inventing a meaning.
3. Make the smallest coherent edit and preserve unrelated or concurrent changes.
4. Search references before and after a rename.
5. Report entries created, changed, merged, moved, or retired.

Keep one alphabetized canonical line per concept:

```text
- **Preferred term** (ABBR; alias) — One-sentence definition. Optional boundary.
```

Use aliases on the canonical line. Keep a retired name as an alias when future searches need
it. Do not record secrets, transient task facts, generic dictionary definitions, or meanings
that the user or an authoritative source has not established.

When a project term becomes cross-project language, add the canonical entry here. Let the
project brief link or summarize it without creating a competing definition.
