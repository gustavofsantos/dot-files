---
name: kb-map
description: >
  Generates a compact domain map of the engineering knowledge base — a mind-map-style
  DOMAIN_MAP.md that groups terms, facts, issues, and spikes by bounded context, shows
  cross-domain relationships, and is small enough to be included in any LLM context.
  Use when you want a structured overview of the KB, need to orient an LLM to the
  domain landscape, or want to discover which domain owns a concept. Triggers on
  "map the knowledge base", "domain map", "kb-map", "organize by domain",
  "show me the domains", "what domains exist", "mapa de domínios", "organizar por domínio".
metadata:
  allowed-tools: Read Write Edit Bash(kb-index:*) Bash(kb-search:*) Bash(kb-peek:*) Bash(cat:*) Bash(grep:*) Bash(rg:*) Bash(ls:*) Bash(find:*)
---

# KB Map

Produces `~/engineering/DOMAIN_MAP.md`: a compact, structured file that groups every
KB artifact by **bounded context / domain**, shows cross-domain edges, and fits in an
LLM prompt as orientation context.

The discipline: **domains come from the GLOSSARY** — the `domain:` field on each term
is the canonical domain registry. Facts, issues, and spikes are assigned to domains
by matching their `tags:` frontmatter to domain names; anything that doesn't match
lands in `_unclustered` for the user to review.

## Step 1 — Resolve the KB root

```bash
ENGINEERING_DIR="${ENGINEERING_DIR:-$HOME/engineering}"
GLOSSARY="$ENGINEERING_DIR/terms/GLOSSARY.md"
INDEX="$ENGINEERING_DIR/INDEX.md"
MAP="$ENGINEERING_DIR/DOMAIN_MAP.md"
```

If `INDEX.md` is missing or older than any artifact file, run `kb-index` first.

## Step 2 — Extract domains from GLOSSARY

Read `GLOSSARY.md`. For each `## Term` entry, extract the `**Domain:**` line.
Build the canonical domain list: a sorted, deduplicated set of domain names.

Each domain will become one section in the map.

If GLOSSARY.md is empty or has no domain-tagged terms, note that and continue —
the map will show only `_unclustered`.

## Step 3 — Read all artifact metadata

For each artifact directory (`facts/`, `issues/`, `spikes/`):

```bash
grep -rh "^tags:" "$ENGINEERING_DIR/facts/" "$ENGINEERING_DIR/issues/" "$ENGINEERING_DIR/spikes/" 2>/dev/null
```

Also extract `id:` and `title:` (or the filename as fallback) per artifact.

Build a table: `artifact_id → [tag_list]`.

## Step 4 — Assign artifacts to domains

**If GLOSSARY.md has domain-tagged terms:** match each artifact's tags against the
domain list (case-insensitive substring — `gemini` matches `gemini-integration`).
Multiple tags may match multiple domains — assign to all matches.
No match → `_unclustered`.

**Fallback — empty glossary or no domain-tagged terms:** treat the most common tags
across all artifacts as proto-domains. Cluster each artifact under its most specific
matching proto-domain tag. This lets the map be useful before the ubiquitous language
is built out. Add a note to the output file:
`_Domains derived from artifact tags — no domain-tagged terms in GLOSSARY.md yet._`

## Step 5 — Extract cross-domain edges

Cross-domain edges exist when an artifact assigned to domain A references an artifact
assigned to domain B. Detect them via the `refs:` frontmatter block:

```bash
grep -rh "refs:" -A 10 "$ENGINEERING_DIR/facts/" "$ENGINEERING_DIR/issues/" 2>/dev/null
```

Also look for `[[...]]` wiki links in issue bodies that resolve to terms in another domain.

Represent edges as `DomainA → DomainB` (directed, deduplicated).

## Step 6 — Build DOMAIN_MAP.md

Write the file with this structure:

```markdown
# KB Domain Map
_Generated <date>. Source of truth: GLOSSARY.md (terms/domains) + artifact tags._
_Read this before INDEX.md when you want domain context, not a flat artifact list._

---

## <domain-name>

**Concept:** <one-line summary — the definition of the most representative term>
**Terms:** Term A · Term B · Term C
**Facts:** FACT-001 · FACT-002
**Issues:** 007 · 009
**Spikes:** spike-slug
**Neighbors:** → other-domain · → another-domain

---

## _unclustered
_Artifacts whose tags didn't match any domain. Add a `domain:` to the relevant term
in GLOSSARY.md, or add a matching tag to the artifact, then re-run `kb-map`._

**Facts:** FACT-XXX
**Issues:** NNN
```

Rules:
- Omit any line whose list is empty (don't write `**Facts:**` if there are no facts).
- Keep each domain section under 8 lines.
- Neighbors list only domains, not artifact IDs.
- The whole file should fit in ~100 lines.

## Step 7 — Write and confirm

Write the file to `$MAP`. Then run `kb-index` so INDEX.md references the map.

Confirm:
```
KB domain map written → ~/engineering/DOMAIN_MAP.md
Domains: <count> | Terms: <count> | Facts: <count> | Issues: <count> | Unclustered: <count>
```

If `_unclustered` is non-empty, list the unclustered artifact IDs so the user can
decide whether to tag them or leave them for a future domain.

## When to re-run

Re-run `kb-map` after:
- Adding a new term with a new domain (via `term` skill)
- Adding a new fact or issue (via `fact` or `issue` skill)
- Manually adding a `domain:` tag to a fact/issue frontmatter

The map is generated output — never edit it by hand.
