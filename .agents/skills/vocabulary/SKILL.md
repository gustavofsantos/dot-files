---
name: vocabulary
description: >
  Keep the user's language alive: eagerly load and apply the canonical shared vocabulary in
  $ENGINEERING_HOME/VOCABULARY.md whenever interpreting, choosing, defining, correcting,
  renaming, or organizing terminology, concepts, jargon, abbreviations, aliases, naming, or
  ubiquitous language—and whenever wording could affect plans, requirements, code, docs, or
  agent communication. Use this skill to create, read, update, merge, split, rename, retire,
  or reorganize terms, and to make every agent consistently speak the user's established
  language. When in doubt, load it: a small terminology check prevents expensive semantic drift.
---

# vocabulary

Treat the vocabulary as the user's canonical, cross-project language. Consult it before choosing
terms, then use its preferred terms consistently in the current response and work. Load only the
entries relevant to the task unless the task requires a whole-vocabulary review.

The vocabulary is `${ENGINEERING_HOME:-$HOME/engineering}/VOCABULARY.md`. Never substitute a
repository-local glossary or hardcode `~/engineering`.

## Operating loop

1. Resolve `vault="${ENGINEERING_HOME:-$HOME/engineering}"` and
   `vocabulary="$vault/VOCABULARY.md"`.
2. If the file exists, identify the task's domain terms, invented terms, abbreviations, and short
   forms. Search for those terms and likely aliases with `rg -in -C 1 -- 'term|alias' "$vocabulary"`.
   Read the whole file only for a broad terminology audit or reorganization. If the file does not
   exist, treat the vocabulary as empty; create it only when asked to record or curate a term.
3. Search for the term, its aliases, and nearby concepts before editing. Prefer updating an
   existing line over creating a synonym entry.
4. Clarify genuine ambiguity instead of inventing the user's meaning. Preserve distinctions the
   user makes even when common usage differs.
5. Make the smallest coherent edit. Reorganize only when it improves retrieval or removes an
   actual inconsistency.
6. Re-read affected entries and check aliases, preferred wording, and alphabetical order.
7. Apply the resulting vocabulary throughout the current work. Briefly report terms created,
   changed, moved, merged, or retired.

## File shape

Create the file with this heading when it is absent:

```markdown
# Vocabulary
```

Keep one term per line, alphabetized by preferred term. Use `## A`, `## B`, and so on only when
the file is large enough that letter sections make scanning easier. Omit empty letter sections.

```markdown
## N

- **Net operating income** (NOI) — Property income after operating expenses, before financing and taxes.
- **Net rentable area** (NRA; rentable area) — Floor area used as the denominator for rent per area.
```

Use this compact grammar:

```text
- **Preferred term** (ABBR; short form; alias) — One-sentence definition. Optional qualifier.
```

- Put abbreviations, short forms, and aliases in parentheses so search finds them without separate
  entries. Omit the parentheses when there are none.
- Make the definition the shortest sentence that preserves the important boundary. Prefer plain
  language; do not add an example that merely repeats the definition.
- Add a short `Not X.` or `Use X when …` qualifier only to prevent a likely misunderstanding.
- Add `See [[Related term]].` only when the link materially helps navigation.
- Record a retired name as an alias of its replacement. Add `Retired.` only when an agent might
  otherwise keep using it.

## Editing rules

- Preserve the user's voice and meaning. Improve clarity without silently broadening or narrowing
  a definition.
- Keep one concept per line and one canonical line per concept. Split overloaded terms; merge
  duplicates; retain old names as aliases when useful.
- Rename a heading and update references across the vault when the preferred term changes. Search
  before and after with `rg` rather than assuming references are local to this file.
- Prefer alphabetical lookup over category trees. Categories overlap in complex systems and force
  agents to read more context to find a term.
- Do not record secrets, transient task details, generic dictionary definitions, or a term whose
  meaning has not been established.
- Do not overwrite concurrent or unrelated vault edits. Inspect the diff when the vault is a Git
  repository and limit changes to the requested vocabulary work.

## Scope boundaries

`VOCABULARY.md` owns language meant to follow the user across projects and agent sessions. A
project brief's Glossary owns project-specific terms. When a project term becomes broadly useful,
add a canonical vocabulary entry and link or summarize it in the project brief without duplicating
competing definitions.
