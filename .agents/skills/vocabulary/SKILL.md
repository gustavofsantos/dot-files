---
name: vocabulary
description: >
  Read and apply established cross-project terminology when a request materially depends on
  shared domain meaning. Curate vocabulary entries only when the user explicitly asks.
---

# Vocabulary

`${ENGINEERING_HOME:-$HOME/engineering}/VOCABULARY.md` owns the user's canonical
cross-project terms. A project brief owns project-only terms.

## Read and apply

When shared semantics matter, search the vocabulary for the relevant terms and aliases. Read
only the matching entries unless the user asks for a broad audit. Use the preferred terms and
preserve established distinctions. If the file does not exist, continue without creating it.

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
