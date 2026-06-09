---
name: kb-map
description: >
  Maintains DOMAIN_MAP.md — a compact, domain-clustered mind map of the engineering
  knowledge base that groups terms, facts, issues, and spikes by bounded context and
  is small enough to fit in any LLM prompt. If a map already exists, asks the user
  whether to enhance (preserve curated domains, sync new artifacts), rebuild from
  scratch, or review-only. Use when you want a structured overview of the KB, need to
  orient an LLM to the domain landscape, or want to discover which domain owns a
  concept. Triggers on "map the knowledge base", "domain map", "kb-map", "organize by
  domain", "show me the domains", "what domains exist", "mapa de domínios",
  "organizar por domínio", "atualizar mapa de domínios".
metadata:
  allowed-tools: Read Write Edit Bash(kb-index:*) Bash(kb-search:*) Bash(kb-peek:*) Bash(cat:*) Bash(grep:*) Bash(rg:*) Bash(ls:*) Bash(find:*)
---

# KB Map

Produces `~/engineering/DOMAIN_MAP.md`: a compact, structured file that groups every
KB artifact by **bounded context / domain**, shows cross-domain edges, and fits in an
LLM prompt as orientation context.

The discipline: **domains are user-defined** — they live as headings in the existing
map (enhance mode) or are derived from Folgezettel clusters (rebuild mode). Root notes
cluster naturally through `parent: [[note]]` links; the root of each link tree becomes
a proto-domain. Issues and spikes are assigned by their `tags:` frontmatter. Anything
unassigned lands in `_unclustered` for the user to review.

## Step 1 — Resolve the KB root

```bash
ENGINEERING_DIR="${ENGINEERING_DIR:-$HOME/engineering}"
INDEX="$ENGINEERING_DIR/INDEX.md"
MAP="$ENGINEERING_DIR/DOMAIN_MAP.md"
```

If `INDEX.md` is missing or older than any artifact file, run `kb-index` first.

## Step 2 — Check for an existing map and ask the user

If `$MAP` exists, read it and present it to the user. Then ask:

> "A domain map already exists (shown above). How would you like to proceed?
> 1. **Enhance** — keep your domain names and Concept lines as-is; only sync the artifact lists (Facts/Issues/Spikes) and Neighbors from the current KB state.
> 2. **Rebuild** — discard the existing map and regenerate fully from root-note `parent:` clusters + artifact tags.
> 3. **Review only** — show me what new artifacts are unclustered without touching the file."

Wait for the user's answer before continuing. Default to **Enhance** if they say "yes", "go ahead", or similar without specifying.

If `$MAP` does not exist, skip this step and proceed directly.

## Step 3 — Determine the domain list

**Enhance mode:** the existing map's `## <domain>` headings are the domain list — preserve their names and `**Concept:**` lines verbatim. Skip deriving new domains.

**Rebuild mode / no existing map:** scan root notes for `parent:` links. Build a directed graph; nodes with no parent (root nodes) become proto-domain names. Fall back to common `tags:` values from issues/spikes if no `parent:` links exist.

## Step 4 — Read all artifact metadata

Root notes:
```bash
find "$ENGINEERING_DIR" -maxdepth 1 -name "*.md" \
  ! -name "INDEX.md" ! -name "DOMAIN_MAP.md"
```
For each root note: slug (filename without `.md`) is the ID; extract `parent: [[...]]` line if present.

Issues and spikes:
```bash
grep -rh "^tags:" "$ENGINEERING_DIR/issues/" "$ENGINEERING_DIR/spikes/" 2>/dev/null
```
Also extract `id:` and `title:` per artifact. Build a table: `artifact_id → [tag_list]`.

## Step 5 — Assign artifacts to domains

Root notes: assign by `parent:` link chain — follow links to the root node; that root
node's slug is the domain. Notes with no `parent:` and no tag match → `_unclustered`.

Issues/spikes: match `tags:` against domain names (case-insensitive substring). No
match → `_unclustered`.

**Enhance mode:** only process artifacts not already listed in the existing map.

## Step 6 — Extract cross-domain edges

Cross-domain edges exist when an artifact in domain A links to a note in domain B.
Detect via `[[wikilinks]]` in note bodies and `refs:` frontmatter in issues/spikes:

```bash
grep -rh "\[\[" "$ENGINEERING_DIR"/*.md "$ENGINEERING_DIR/issues/" 2>/dev/null
```

Represent edges as `DomainA → DomainB` (directed, deduplicated).

## Step 7 — Build DOMAIN_MAP.md

Write the file with this structure:

```markdown
# KB Domain Map
_Generated <date>. Source of truth: root notes (`parent:` clusters) + artifact tags._
_Read this before INDEX.md when you want domain context, not a flat artifact list._

---

## <domain-name>

**Concept:** <one-line summary — the definition of the most representative term>
**Notes:** note-slug · another-slug
**Issues:** 007 · 009
**Spikes:** spike-slug
**Neighbors:** → other-domain · → another-domain

---

## _unclustered
_Artifacts with no parent: link and no matching domain tag. Add a `parent: [[note]]`
to root notes, or add a matching tag to issues/spikes, then re-run `kb-map`._

**Notes:** orphan-slug
**Issues:** NNN
```

Rules:
- Omit any line whose list is empty (don't write `**Facts:**` if there are no facts).
- Keep each domain section under 8 lines.
- Neighbors list only domains, not artifact IDs.
- The whole file should fit in ~100 lines.

## Step 8 — Write and confirm

**Review only mode:** do not write the file. Present what would change as a diff-style
summary: new artifacts found, which domain they'd slot into, and any that would land
in `_unclustered`. Let the user decide whether to proceed.

**Enhance / Rebuild mode:** write the file to `$MAP`. Then run `kb-index` so INDEX.md
references the map.

Confirm:
```
KB domain map written → ~/engineering/DOMAIN_MAP.md
Domains: <count> | Notes: <count> | Issues: <count> | Unclustered: <count>
```

If `_unclustered` is non-empty, list them so the user can decide whether to add
`parent:` links or domain tags, or leave them for later.

## When to re-run

Re-run `kb-map` after:
- Adding a new root note (via `vault`)
- Adding a new issue or spike
- Adding or changing `parent:` links between notes

In Enhance mode the map is safe to re-run at any time — curated domain names and
Concept lines are never touched.
