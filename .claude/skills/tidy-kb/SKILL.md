---
name: tidy-kb
description: >
  Reorganize a messy/flat ~/engineering vault into the domain-axis folder-note tree,
  quarantining anything uncertain into _triage/ for human review. Default is a reviewable
  dry-run plan; --apply executes. Trigger on: "tidy the vault", "organize the knowledge
  base", "clean up ~/engineering", "reorganize the vault into domains", "migrate the flat
  vault to a tree", "/tidy-kb". Does NOT trigger on casual mentions of organizing code or
  unrelated files.
---

# tidy-kb

Turn a flat or messy `~/engineering` vault into a domain-axis tree, moving each file to its
home and **quarantining whatever can't be placed with confidence** into `_triage/`. You
orchestrate, keep it safe, and apply; **per-file judgment is fanned out to classification
subagents** primed with this skill's own rubric.

**Two modes:** the default is a **dry-run plan** — show the proposed tree + triage list and
stop, moving nothing. Only `--apply` (or explicit approval of the plan) executes the moves.

## Conventions this skill applies

Self-contained — the full placement rules are in `references/classification.md`. In short:

- **Two axes.** Conceptual notes (domains, models, terms) nest **by domain**; work artifacts
  (`issues/`, `spikes/`, `facts/`) live in **type folders**.
- **Folder-notes.** A domain is `Domain.md` sitting **beside** a `Domain/` folder holding its
  child concepts and sub-domain folder-notes. The folder *is* the parent — no `Parent:` field.
  Keep nesting shallow (2–3 levels).
- **One canonical home** per concept, chosen by ownership; link from the others, never duplicate.
- **Relationships** between domains are labeled `[[wikilinks]]` in a folder-note's
  `## Relationships` section. This skill only **stubs** that section — enriching it is a
  separate curation pass, not tidy's job.

## Bar for placement (conservative)

Move a file into the tree **only when its domain and kind are unambiguous.** When in doubt —
ambiguous owner, possible duplicate, stub with no real claim, spans multiple domains, no
clear domain at all — it goes to `_triage/` with a reason. A clean tree plus an honest pile
beats a full tree full of guesses.

## Operating loop

Load the rubric and manifest template before classifying:
```bash
cat ~/.claude/skills/tidy-kb/references/classification.md
```

### 1. Preconditions — never reorganize a dirty tree
```bash
V=~/engineering
git -C "$V" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo: $V"; exit 1; }
[ -n "$(git -C "$V" status --porcelain)" ] && { echo "Vault dirty — commit or stash first, then re-run."; exit 1; }
base=$(git -C "$V" rev-parse --short HEAD)        # restore point
```
On `--apply`, isolate the work on a branch so it's trivially reversible (the vault
auto-commits, so a branch keeps the churn off `master`):
```bash
git -C "$V" switch -c "kb/tidy-$(date +%Y%m%d-%H%M)"
```

### 2. Inventory the candidates
Candidates are **root-level `.md` files that aren't already organized**: skip any legacy
index files (`DOMAIN_MAP.md`, `INDEX.md`) — removing those is out of scope — and skip any
`X.md` that already has a sibling `X/` folder (it's already a folder-note).
```bash
fd -e md -d 1 . "$V"      # then drop DOMAIN_MAP.md / INDEX.md and existing folder-notes
```
Already-nested content (`Domain/…`, `issues/`, `spikes/`, `facts/`) is left untouched — the
skill is re-runnable and only acts on the unorganized root.

### 3. Classify — fan out to classification subagents
Split candidates into batches of ~30–40 and spawn one subagent per batch, each given this
skill's rubric (`references/classification.md`) and its batch's file list. Each agent reads
each file and returns, per the schema in the rubric, one record per file: `concept` (+ owning
`domain`), `artifact` (+ `type`: issues|spikes|facts), or `triage` (+ `reason`). Collect all
classifications.
> The rubric is self-contained, so a general subagent works. If a convention-aware vault
> curator (e.g. a `mira` agent) happens to be installed, it's a fine choice — but not required.
> For a very large vault (hundreds of files) the Workflow harness gives resumability; the
> Agent-tool fan-out here is the default.

### 4. Assemble the plan
- Derive the **domain set** from the `concept` placements; each domain gets a `Domain.md`
  folder-note whose `## Concepts` lists its children.
- Group `artifact` moves by type folder.
- Build the `_triage/` list, each entry carrying its reason.

### 5. Present the PLAN — then STOP unless `--apply`
Show the proposed tree (domains → children), artifact moves, the triage list **with reasons**,
and counts. End with: *"Nothing moved. Re-run with `--apply` (or say apply) to execute."*
Do not move anything in this mode.

### 6. Apply (`--apply` or approved plan only)
For each move use `git mv` (preserve history); **never delete, never overwrite, never touch
already-nested content**:
- Create each `Domain/` dir and, if absent, its `Domain.md` folder-note — a 1–3 sentence
  overview, a `## Concepts` list of its children, and an empty `## Relationships` (a stub to
  fill in a later curation pass; tidy does structure, not relationship enrichment).
- `git mv` each `concept` into its `Domain/`; each `artifact` into its type folder.
- `git mv` each `triage` file into `_triage/`, and write `_triage/MANIFEST.md` (template in
  references) listing every quarantined file, its reason, and a suggested resolution.

### 7. Verify & report
```bash
# Links resolve by basename, so moves don't break them — but flag any wikilink whose target
# file exists nowhere in the vault (a pre-existing gap, not caused by tidy):
rg -o '\[\[[^]#|]+' "$V" -g '*.md' | sed 's/.*\[\[//' | sort -u   # cross-check against fd
```
Report: counts (placed / by-type / triaged), the branch name, how to review `_triage/`, the
**undo** (`git -C ~/engineering switch master && git branch -D kb/tidy-…`, or `git reset --hard {base}`),
and the reminder that folder-note `## Relationships` are stubs — enrich them in a separate
curation pass.

## Scope (v1)

In: structural reorganization + quarantine. Out: filling `## Relationships`, merging
duplicates, repairing stubs (curation follow-ups on the `_triage/` pile), and removing the
legacy index files. Keep it to moving files to the right home and honestly flagging the rest.
