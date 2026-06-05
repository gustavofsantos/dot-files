# Glossary Entry Template

Each term is one `## ` section in `GLOSSARY.md`. Keep sections alphabetical by term.
The `**Definition:**` line is mandatory and machine-read by `kb-index` / `kb-peek`, so
keep it on its own line, exactly as shown.

```markdown
## Refund Authorization
**Definition:** The approval that releases funds back to a customer once a refund request passes validation.
**Domain:** payments · **Status:** active
**Aliases:** RA, refund auth
**Distinct from:** [[Chargeback]] — a chargeback is bank-initiated and disputed; a refund authorization is merchant-initiated and agreed.
**Banned synonyms:** "refund permission", "money-back approval" — always say *Refund Authorization*.
**Refs:** [[FACT-012-refund-flow]], issue 034
```

## Field notes

**Term** — the `## ` heading is the canonical name and the link target. `[[Refund
Authorization]]` from any fact, issue, or other term resolves here.

**Definition** — one sentence, present tense, falsifiable in meaning. The shared
domain meaning, not an implementation note. First line of every entry.

**Status** — `active` (default), `proposed` (under discussion), or `deprecated`
(kept for resolution but no longer used; pair with `**Superseded by:** [[New Term]]`).

**Aliases** — every other name the concept answers to. Each alias must resolve to
exactly **one** term across the whole glossary — that is the invariant the `term`
skill defends.

**Banned synonyms** — words the team has decided *not* to use for this concept. Omit
the line if there are none. A banned synonym must never be another term's primary name.

**Refs** — the back-links. Facts as `[[FACT-NNN-slug]]`, issues as `issue NNN`. Where
the connection is load-bearing, add the term name to that fact/issue too.
