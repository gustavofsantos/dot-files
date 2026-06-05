---
name: vault
description: >
  Operating protocol for ~/engineering/ knowledge base. Use whenever writing,
  updating, or querying knowledge notes, issues, or spikes in the engineering vault.
  Activate on any mention of "fact", "issue", "spike", "vault", "term", "glossary",
  "bug", "hypothesis", "epic", "~/engineering/", or when capturing engineering knowledge.
  Handles all KB artifact types: atomic knowledge notes (facts, terms, definitions —
  same thing), tracked issues (bugs, stories, investigations), and research spikes.
---

# vault

Unified protocol for `~/engineering/`. Read this fully before touching any file.

## Structure

```
~/engineering/
  Title Case Name.md   ← atomic knowledge notes — facts, terms, concepts all live here
  issues/
    NNN-Title Case.md  ← tracked work items
  spikes/
    NNN-Title Case.md  ← research artifacts
```

Notes at root are the living glossary. A term definition and a factual claim are the
same kind of artifact — one concept, one file. No `facts/` dir. No `GLOSSARY.md`.

## Type map

| Intent | Artifact |
|--------|----------|
| Something is true / was discovered | **note** at root |
| Domain term / concept definition | **note** at root |
| This refines or branches from an existing note | **note** at root with `parent:` link |
| Bug / broken behavior / regression | **issue** (type: bug) in `issues/` |
| Open question / needs investigation | **issue** (type: investigation) in `issues/` |
| Feature / story / epic | **issue** (type: implementation) in `issues/` |
| Spike result to preserve | **spike** in `spikes/` |

## Operating loop

1. **Search first** — `rg -l <term> ~/engineering/*.md` + `kb-search <term>` before writing
2. **Dedup** — if a note covering this concept already exists, update it; never create a duplicate
3. **Folgezettel check** — does this idea branch from or continue an existing note? If yes, link with `Parent: [[Existing Note]]`
4. **Ask only what's missing** — don't interrogate; fill gaps conversationally and write
5. **Write** — follow the contract in `references/write-contracts.md`

## Hard rules

- **No write without search first**
- **One concept, one note** — update rather than duplicate
- **Root notes only for knowledge** — never create a `facts/` or `terms/` subdir
- **Every note links to something** — at minimum one `[[wikilink]]` to an existing note

## Reference files

Load on demand — do not load preemptively:
- `references/write-contracts.md` — schemas for note, issue, spike
