---
name: term
description: >
  Steward of the domain's ubiquitous language — maintains a single GLOSSARY.md of
  domain terms with definitions, aliases, banned synonyms, and links to facts/issues.
  Enforces one-name-one-concept: dedups, detects alias/synonym collisions, cross-links
  to the KB, and audits the glossary. Use when defining, renaming, deprecating, or
  looking up a domain term, or auditing the vocabulary. Triggers on "define a term",
  "add to the glossary", "what does X mean in this domain", "ubiquitous language",
  "rename this term", "audit the glossary", "definir termo", "linguagem ubíqua",
  "adicionar ao glossário", "isso é um termo do domínio".
metadata:
  allowed-tools: Read Write Edit Bash(kb-index:*) Bash(kb-search:*) Bash(kb-peek:*) Bash(rg:*) Bash(grep:*) Bash(git:*) Bash(mkdir:*)
---

# Term

Steward of the **ubiquitous language**: the curated vocabulary the domain agrees to
speak, so that the same concept always wears the same name in conversation, issues,
facts, and code. The whole vocabulary lives in **one file** — `GLOSSARY.md` — under
`~/engineering/terms/`. A term is the long-lived naming counterpart to a `fact`: a fact
records something *true*; a term fixes what something is *called*.

The discipline this skill enforces is **one name per concept, one concept per name**.
Every operation defends that invariant.

## Step 1 — Resolve the glossary

```bash
ENGINEERING_DIR="${ENGINEERING_DIR:-$HOME/engineering}"
GLOSSARY="$ENGINEERING_DIR/terms/GLOSSARY.md"
mkdir -p "$ENGINEERING_DIR/terms"
```

If `GLOSSARY.md` does not exist yet, create it from `references/glossary-header.md`.

## Step 2 — Pick the operation

| Intent | Do |
|--------|-----|
| Define / update a term | Steps 3–6 |
| Look up / list terms | `kb-search <term>` or read the relevant `## ` section |
| Rename a term | Step 7 |
| Deprecate a term | Step 8 |
| Audit the whole glossary | Step 9 |

## Step 3 — Dedup before defining (defend the invariant)

Before writing a new `## ` entry, search for the concept under **any** name. Check the
glossary itself **and** the rest of the KB, including the proposed aliases:

```bash
grep -in -E "PROPOSED_NAME|ALIAS_1|ALIAS_2" "$GLOSSARY"
kb-search PROPOSED_NAME ALIAS_1   # surfaces facts/issues/spikes already using it
```

Resolve the three collision cases — **do not** create a duplicate:

- **Concept already defined under another name** → this is the canonical-naming
  decision. Keep one primary name; fold the other in as an alias. Update callers' refs.
- **Name already used for a different concept** → a genuine clash. Flag it to the user
  and disambiguate (qualify one name, e.g. *Billing Account* vs *Login Account*).
- **Proposed alias is already a primary term or another term's alias** → reject the
  alias; an alias must resolve to exactly one term.

## Step 4 — Shape the term

- **Term** — the canonical name (the `## ` heading). Title Case, as spoken in the domain.
- **Definition** — one sentence, present tense, what it *is* in this domain. Not a code
  description — the meaning the team shares.
- **Domain** — which bounded context / area it belongs to (e.g. `payments`, `auth`).
- **Aliases** — other names that mean the same thing (acronyms, informal forms).
- **Distinct from** — the terms it is most often confused with, and the difference.
- **Banned synonyms** — words that must **not** be used for this concept; the discipline
  is to say the canonical name instead. Omit if none.
- **Refs** — facts and issues that rely on or established this term.

## Step 5 — Cross-link the KB (both directions)

A term and a fact/issue reference each other by ID:

- In the term's **Refs**, list each `[[FACT-NNN-slug]]` and `issue NNN` it connects to.
- Where it materially matters, add the term name to that fact/issue so the link is
  navigable from either side. Don't force-link — only where the connection is real.

Use wiki links so they resolve: `[[FACT-012-refund-flow]]`, `[[Chargeback]]` (another
term in the same glossary).

## Step 6 — Write the entry

Insert the `## ` block (format in `references/glossary-entry.md`) into `GLOSSARY.md`,
keeping entries **alphabetical by term**. Then refresh the index so the term is
discoverable:

```bash
kb-index   # rebuilds INDEX.md including the Glossary section
```

Confirm: "Defined **<Term>** (<domain>) → GLOSSARY.md (linked to <refs or none>)".

## Step 7 — Rename a term

Renaming is a language decision with blast radius. Update the `## ` heading, move the old
name into **Aliases** (so old references still resolve), and update any `[[Old Name]]`
wiki links across the KB:

```bash
rg -l "\[\[Old Name\]\]" "$ENGINEERING_DIR"
```

Then `kb-index`.

## Step 8 — Deprecate a term

Don't delete — set `Status: deprecated` and add `Superseded by: [[New Term]]`. The entry
stays so stale references still resolve to an explanation. Delete only a term that was
never correct.

## Step 9 — Audit the glossary

Read `GLOSSARY.md` and report violations of the invariant:

- **Missing definitions** — `## ` headings with no `**Definition:**` line.
- **Alias collisions** — an alias that is also a primary term or another term's alias.
- **Banned-synonym leaks** — a banned synonym that appears as someone's primary name.
- **Dangling refs** — `[[FACT-NNN]]` / `[[Term]]` links that resolve to nothing.
- **Orphans** — terms with no domain, or no ref to any fact/issue.

Present the findings; fix only what the user approves.
