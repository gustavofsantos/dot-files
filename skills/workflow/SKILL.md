---
name: workflow
description: >
  Protocol for managing daily engineering work. The orchestrator skill — coordinates
  all other skills across the three phases of work: planning, execution, and review.
  Use whenever the user mentions a card, starts a task, wants to know what's in progress,
  needs context recovery, or says things like "new card", "start a session", "what are
  we working on", "recall", "continue", "create a card for X", or "let's work on X".
  This skill is the entry point. It decides which other skills to invoke.
---

# Workflow

One abstraction. One source of truth.

**Card** — unit of intent and execution state. Lives at `~/engineering/cards/<nnn>-<slug>.md`.

The card carries everything needed to resume work across sessions without any additional
state file. Plan Mode handles transient session state. The card handles everything else.

---

## Directory layout

```
~/engineering/
  cards/
    001-fix-auth-bug.md
    archive/            ← completed cards — never read these
  facts/                ← managed by the knowledge skill
  spikes/               ← managed by the knowledge skill
  thinking/               ← managed by the thinking parter skill
  .counters/
    cards
    facts
    spikes
```

---

## Scripts

All scripts live at `~/.claude/skills/workflow/scripts/` and are invoked with `python3`.

| Script | Purpose |
|---|---|
| `work-card-create.py` | Scaffold a new card |
| `work-card-list.py` | List cards, filter by status or tag |
| `work-card-archive.py` | Move a done card to archive |

```bash
SCRIPTS=~/.claude/skills/workflow/scripts

python3 $SCRIPTS/work-card-create.py --title "Fix auth bug" --status inbox
python3 $SCRIPTS/work-card-list.py --status active --format text
python3 $SCRIPTS/work-card-archive.py --card 001
```

All scripts accept `--format json` (default) or `--format text`.

---

## Card schema

```yaml
---
id: "001"
title: "Fix auth bug"
status: inbox | not-now | active | done
branch: feat/fix-auth          # optional — used for worktree context
tags: [feature, api]
facts:
  - "[[FACT-007-auth-token-refresh-window]]"
spikes:
  - "[[001-auth-investigation]]"
created: 2026-04-27
updated: 2026-04-27
---

## Objective

One sentence. What "done" looks like when this card closes.

## Scope

**In:** what is explicitly included.
**Off-limits:** what will not be touched and why.

## Context

Relevant background. Links to Jira, Sentry, docs, prior decisions.
If design constraints apply (evolutionary-design, incremental-refactor),
state them here as named constraints — not as prose.

## Open questions

Questions that must be answered before or during execution.
If non-empty when work begins, consider dead-reckoning before writing tasks.

- [ ] ?

## Tasks

- [ ] Task 1
- [ ] Task 2
```

**Valid statuses:** `inbox` `not-now` `active` `done`

**On task completion:** agent marks the task `[x]` and updates `updated:` in frontmatter.

**On card completion:** when all tasks are `[x]`, agent signals:
> "All tasks complete. Ready for review."

The agent never sets status to `done` unilaterally. That is the human's action after review.

**`facts`** — wiki links to facts in `~/engineering/facts/` relevant to this card.
**`spikes`** — wiki links to spike narratives in `~/engineering/spikes/`.
**`branch`** — optional. When present, used to locate worktree context and filter knowledge retrieval.

---

## Skill integration

| Moment | Skill |
|---|---|
| Raw idea needs shaping | `user-story-builder` |
| Card needs tasks broken down | `user-story-planner` |
| Objective is unclear or complex | `thinking-partner` |
| Open questions remain before execution | `dead-reckoning` |
| Implementation with new behavior | `test-design` → `tdd-design` |
| Design choice feels coupled or tangled | `thinking-lenses` (Braided) |
| Bug keeps recurring or fix feels like a patch | `thinking-lenses` (Iceberg) |
| Review before PR | `review` |
| Code smell or duplication found | `incremental-refactor` constraints (in card Context) |
| New feature, unsure where to start | `evolutionary-design` constraints (in card Context) |

---

## Knowledge retrieval — session start

Run at the start of every session, silently, before any other action:

```bash
qmd query "<card title> <card objective>" --min-score 0.5 -n 8 --files
```

Load returned facts and spike excerpts into working context.
If nothing scores above threshold, proceed without — do not ask the human.

If something surfaces that the human hasn't mentioned:
> "Before we start — [[FACT-012-auth-token-refresh]] covers token refresh behavior here.
> Worth keeping in mind."

If a loaded fact contradicts something in the card's Context: surface it immediately
before any execution begins.

---

## Phase 1 — Planning a card

Entry points: Jira ticket, Sentry issue, verbal description, scratch idea.

1. Create the card:
   ```bash
   python3 ~/.claude/skills/workflow/scripts/work-card-create.py \
     --title "<title>" [--status inbox] [--tags feature,api] [--branch feat/slug]
   ```
2. Fill `## Objective` — one sentence, defines done.
3. Fill `## Scope` — in and off-limits. Both fields required before the card goes active.
4. Fill `## Context` with background, links, and constraints.
5. Run knowledge retrieval. Surface relevant facts.
6. Fill `## Open questions` with anything unresolved.

**If open questions exist before tasks are written:**
→ invoke `dead-reckoning`. Link resulting spike in `spikes:`. Promote confirmed
  facts to `~/engineering/facts/` and list in `facts:`. Clear resolved questions.

**If objective is clear enough to proceed:**
→ invoke `user-story-builder` if scope needs shaping.
→ invoke `user-story-planner` to break into tasks.
→ write tasks into `## Tasks`. Set status to `active`.

**Card stays lean.** Objective + scope + context + questions + tasks + pointers.
Narrative belongs in spikes. Facts belong in the knowledge library.

---

## Phase 2 — Executing a card

### Session start protocol

User informs the card to work on. If not provided, ask before proceeding — do not guess.

1. Run knowledge retrieval.
2. Read the card — objective, scope, context, open questions, tasks.
3. If `## Open questions` has unresolved items:
   > "There are open questions on this card. Recommend resolving them before execution.
   > Want to run dead-reckoning, or proceed and treat them as known risks?"
   Wait for the human's decision.
4. State what you understand and what you're about to do. Wait for confirmation
   if anything is ambiguous.

### During execution

**After each completed task:**
1. Mark `[x]` in `## Tasks`.
2. Update `updated:` in frontmatter.

**When a discovery warrants permanent storage:**
→ invoke `knowledge` skill. Add wiki link to card's `facts:` field.

**When work surfaces something outside card scope:**
→ create a new card in `inbox`. Do not expand scope silently.
→ if it is an open question that blocks current work, add it to `## Open questions`
  and surface it to the human before continuing.

**When all tasks are `[x]`:**
> "All tasks complete. Ready for review."

### Context recovery

When resuming after any interruption:

1. User informs the card.
2. Run knowledge retrieval.
3. Read the card — tasks tell you exactly where execution stopped.
4. State the reconstruction: "We were doing X. The remaining tasks are Y and Z."
5. Wait for confirmation before proceeding.

---

## Phase 3 — Reviewing a card

When all tasks are complete, invoke `review` skill.

After review passes:
1. Set card status to `done`.
2. Archive:
   ```bash
   python3 ~/.claude/skills/workflow/scripts/work-card-archive.py --card 001
   ```
   Moves card to `archive/`. Spikes and facts remain — they outlive the card.

---

## Rules

- Never read `archive/` directories. Stale context.
- `## Scope` with explicit off-limits is required before a card goes `active`.
- `## Open questions` must be reviewed at session start. Non-empty = risk. Name it.
- The agent marks tasks `[x]` as they complete — never in bulk at session end.
- The agent never rewrites `## Objective`, `## Scope`, or `## Context`. Those belong to the human.
- Scope violations are not silent. New work goes to a new card in `inbox`.
- Facts and spikes are pointers only. Never copy content into the card.
- The agent never sets status to `done`. That is the human's action.
