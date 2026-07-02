# Classification rubric & templates

## Per-file decision (what a classification batch agent returns)

For each candidate file, read it (frontmatter + first lines + its `[[links]]`) and emit one
record. **Conservative bar: when any test below is uncertain, choose `triage`.**

```
{ "file": "<root-relative path>",
  "decision": "concept" | "artifact" | "triage",
  "domain": "domain/<Domain>" | "domain/<Domain>/<Sub>",   // concept only — the ONE owner
  "type": "issues" | "spikes" | "facts",       // artifact only
  "reason": "<why triaged>" }                  // triage only
```

### artifact — a work item, not a concept
Route to a type folder when it's clearly one of these (by frontmatter or filename):
- `facts` — `id: FACT-…` / filename `FACT-NNN-…` / frontmatter `confidence:`.
- `issues` — frontmatter `status:` + `## Objective`/`## Tasks`, or filename `NNN-Title`.
- `spikes` — `## Answer`/`## Evidence`, "spike" in title, research write-up.

### concept — a domain/model/term, with ONE unambiguous owner
A claim, definition, model, or term. Place only when **both** hold:
- the **kind** is clearly conceptual (not a work artifact, not a scratch/meeting/log note), and
- exactly **one** owning **domain** is obvious from its content (the domain that owns the concept's
  invariants). Prefer an existing domain in the tree; a genuinely new domain is fine.

**Not a domain:** system/service names (Billing System, Recurrence Engine, SeuBarriga, Cart-System).
Those stay at vault root; route their concepts to the domain they implement (`Bill`, `Recurrence`,
`Invoice`, `Entry`, …). When a note names a system in `parent:`, re-home under the domain unless
the note is purely about deployment/ops of that system.

### triage — anything that fails the bar
Quarantine with a concrete reason. Common reasons:
- `ambiguous owner` — plausibly belongs to two+ domains; no clear primary.
- `possible duplicate of [[X]]` — overlaps an existing note; needs a merge decision.
- `stub` — under ~20 meaningful words / no real claim.
- `no clear domain` — conceptual but doesn't map to any domain yet.
- `not a knowledge note` — scratch, meeting notes, journal, log, export, attachment.
- `spans domains` — one file carrying several concepts; needs splitting first.

## `_triage/MANIFEST.md` template

```markdown
# Triage — files needing attention

_Quarantined by tidy-kb on <date>. Each needs a human decision before it rejoins the vault._
_Resolve by: placing under a domain, merging into an existing note, splitting, or deleting._

| File | Why | Suggested resolution |
|------|-----|----------------------|
| `misc-notes.md` | spans domains | split into Billing + Catalog concepts |
| `old-draft.md` | stub (12 words) | merge into [[Refund Authorization]] or delete |
| `q3-sync.md` | not a knowledge note | meeting notes — move out of vault or delete |
```

## Domain folder-note skeleton (written on --apply when a `domain/<Domain>.md` is absent)

```markdown
# <Domain>

<1–3 sentence overview of what this domain is.>

## Concepts

- [[Child One]] — <one line>
- [[Child Two]] — <one line>

## Relationships

<!-- stub: fill labeled links to neighbour domains in a later curation pass -->
```
