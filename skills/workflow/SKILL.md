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

Two abstractions. One source of truth.

**Card** — unit of intent. Lives at `~/.work/cards/<nnn>-<slug>.md`.
**Session** — unit of execution for one repo front. Lives at `~/.work/sessions/<nnn>-<repo>.md`.

The card is the source of truth. Sessions are derived. Tmux sessions are ephemeral.

---

## Directory layout

```
~/.work/
  cards/
    001-fix-auth-bug.md
    archive/            ← completed cards — never read these
  sessions/
    001-api.md
    archive/
  .counter              ← sequential ID counter

~/.knowledge/           ← managed by the knowledge skill
  facts/
  spikes/
```

---

## Scripts

All scripts live at `~/.claude/skills/workflow/scripts/` and are invoked with `python3`.

| Script | Purpose |
|---|---|
| `work-card-create.py` | Scaffold a new card |
| `work-card-list.py` | List cards, filter by status or tag |
| `work-card-archive.py` | Move a done card and its sessions to archive |
| `work-session-create.py` | Create a session file and link it to a card |
| `work-session-attach.py` | Attach to tmux session, restores if dead |
| `work-session-restore.py` | Restore dead tmux sessions without attaching |
| `work-recall.py` | Inject current focus into context (hook script) |

**Invocation pattern:**

```bash
SCRIPTS=~/.claude/skills/workflow/scripts

python3 $SCRIPTS/work-card-create.py --title "Fix auth bug" --status inbox
python3 $SCRIPTS/work-card-list.py --status active --format text
python3 $SCRIPTS/work-card-archive.py --card 001
python3 $SCRIPTS/work-session-create.py --card 001 --repo api --branch feat/fix-auth --worktree /abs/path
python3 $SCRIPTS/work-session-attach.py --session 001-api
python3 $SCRIPTS/work-session-restore.py --all
```

All scripts accept `--format json` (default) or `--format text`. Use `--help` on any script for full usage.

**Hook registration** (`.claude/settings.local.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Read",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/skills/workflow/scripts/work-recall.py"
          }
        ]
      }
    ]
  }
}
```

---

## Card schema

```yaml
---
id: "001"
title: "Fix auth bug"
status: inbox | not-now | active | done
tags: [feature, api]
repo:
sessions:
  - ~/.work/sessions/001-api.md
spikes:
  - ~/.knowledge/spikes/001-auth-token-investigation.md
facts:
  - FACT-007
  - FACT-012
created: 2026-04-08
updated: 2026-04-08
---

## Objective
What this card is trying to accomplish and why. One paragraph maximum.

## Context
Relevant background. Links to Jira, Sentry, docs, prior decisions.
If design constraints apply (evolutionary-design, incremental-refactor),
state them here as named constraints — not as prose.

## Tasks
Tasks defined by the human before execution begins. The agent checks these off.
- [ ] Task 1: description
- [ ] Task 2: description
- [ ] Task 3: description

## Current focus
What is being worked on right now. Kept current by the agent. See session file
for the structured Done / In progress / Next breakdown.
```

**Valid statuses:** `inbox` `not-now` `active` `done`

**On card completion:** when all tasks in `## Tasks` are checked `[x]`, the agent
signals the human: "All tasks are complete. Ready for review." The human then
runs the review skill and archives the card. The agent never moves a card to `done`
unilaterally.

`facts` — IDs of facts in `~/.knowledge/facts/` discovered while working this card.
`spikes` — paths to spike narratives produced during planning or investigation.
Keep both lean — IDs and paths only, never copy content.

---

## Session schema

```yaml
---
id: 001-api
card: "001"
repo: api
branch: feat/fix-auth-bug
worktree: /abs/path/to/worktree
tmux-session: 001-api
---

## Current focus

### Done
<!-- Items completed this session. Agent marks here after each finished task. -->
- [x] Example: scaffolded migration file

### In progress
<!-- The single item being worked on right now. One item maximum. -->
- [ ] Example: implementing the query with optional filter

### Next
<!-- Remaining items planned for this session, in order. -->
- [ ] Example: handler wiring and integration test
```

**The agent fully rewrites `## Current focus` after each completed subtask.**
It never appends — it rewrites the entire section, moving finished items to `### Done`,
keeping one item in `### In progress`, and maintaining the ordered `### Next` list.

`work-recall.py` extracts the entire `## Current focus` block and injects it after
every tool call. The agent always sees the current state of Done / In progress / Next.

---

## Skill integration

This table is the orchestration map. When a lifecycle moment occurs, invoke the skill.

| Moment | Skill |
|---|---|
| Raw idea needs shaping into a card | `user-story-builder` |
| Card needs tasks broken down | `user-story-planner` |
| Card objective is unclear or complex — understand before acting | `thinking-partner` |
| Card requires understanding existing behavior before implementing | `dead-reckoning` |
| Implementation session with new behavior | `test-design` → `tdd-design` |
| Design choice feels coupled or tangled | `thinking-lenses` (Braided) |
| Bug keeps recurring or fix feels like a patch | `thinking-lenses` (Iceberg) |
| Review before PR | `review` |
| Code smell or duplication found during execution | `incremental-refactor` constraints (see card Context) |
| New feature, unsure where to start | `evolutionary-design` constraints (see card Context) |

Invoke skills by name. Do not reproduce their protocol here.

---

## Knowledge retrieval — session start

Run this at the start of every session, silently, before any other action:

```bash
qmd query "<card title> <card objective>" --min-score 0.5 -n 8 --files
```

Load the returned facts and spike excerpts into working context.
If nothing scores above threshold, proceed without — do not ask the human.
If something relevant surfaces that the human hasn't mentioned, note it:

> "Before we start — FACT-012 covers auth token refresh behavior in this system.
> Worth keeping in mind."

Do not read the full spike narratives unless a fact ID points to one that is
directly relevant. Spikes are large; facts are small.

---

## Phase 1 — Planning a card

Entry points: Jira ticket, Sentry issue, verbal description, scratch idea.

1. Create the card:
   ```bash
   python3 ~/.claude/skills/workflow/scripts/work-card-create.py --title "<title>" [--status inbox] [--tags feature,api]
   ```
2. Fill `## Objective` from available information.
3. Fill `## Context` with background, links, and any constraints.
4. Run knowledge retrieval. Surface relevant facts to the human.
5. If the objective requires investigation before planning:
   → invoke `dead-reckoning`. The spike document is linked in the card's `spikes:` field.
   → facts discovered are written to `~/.knowledge/facts/` and listed in `facts:`.
6. If the objective is clear enough to implement:
   → invoke `user-story-builder` if the scope needs shaping.
   → invoke `user-story-planner` to break into tasks.
   → write the resulting tasks into `## Tasks` in the card.
   → set status to `active`.

**Card stays lean.** Objective + context + tasks + pointers. No prose that belongs in a spike.

---

## Phase 2 — Executing a card

### Starting a session

Prerequisites: worktree must already exist. Card must have tasks defined in `## Tasks`.

```bash
python3 ~/.claude/skills/workflow/scripts/work-session-create.py \
  --card 001 --repo <repo> --branch <branch> --worktree /abs/path

python3 ~/.claude/skills/workflow/scripts/work-session-attach.py --session 001-<repo>
```

### Session start protocol

1. Run knowledge retrieval (see above).
2. Read the card — objective, context, and full `## Tasks` list.
3. Read the session file if it exists.
4. Populate `## Current focus` in the session file:
   - `### Done` — empty (or carry over from prior interrupted session)
   - `### In progress` — first unchecked task from the card's `## Tasks`
   - `### Next` — remaining unchecked tasks in order
5. State what you understand and what you're about to do. Wait for confirmation
   if anything is ambiguous.

### During execution

**After each completed subtask:**

1. Rewrite `## Current focus` in full:
   - Move the finished item from `### In progress` to `### Done` (mark `[x]`)
   - Pull the next item from `### Next` into `### In progress`
   - Remove it from `### Next`
2. Mark the corresponding task `[x]` in the card's `## Tasks`.
3. Update `updated:` date in the card frontmatter.

**When `### Next` is empty and `### In progress` is marked done:**

Signal to the human:
> "All planned tasks are complete. Ready for review."

Do not set card status to `done`. That is the human's action after review passes.

**Scope discipline:**

- New work that surfaces outside card scope → create a new card in `inbox`, do not expand scope.
- New fact discovered → write to `~/.knowledge/facts/`, add ID to card's `facts:` field,
  run `qmd update`.

### Context recovery

When resuming an interrupted session or switching worktrees:

1. Read session file → `## Current focus` is the anchor. Done / In progress / Next tell you exactly where execution stopped.
2. Read card → `## Tasks` confirms which tasks are checked overall.
3. Run knowledge retrieval.
4. Reconstruct: "We were doing X because of Y. The next step was Z."
5. State the reconstruction to the human before proceeding.

### Model handoff

**Outgoing:** finish at a task boundary. Ensure `## Current focus` is fully up to date before handing off. Write one sentence at the bottom of `### In progress`: `Handoff: <what was done and what comes next>`.

**Incoming:** read card, read session, run knowledge retrieval. Rewrite `## Current focus` if stale. Proceed.

---

## Phase 3 — Reviewing a card

When all tasks are complete, invoke `review` skill.
The review skill handles both safety/scope review and architectural depth.
Do not reproduce its protocol here.

After review passes:
1. Set card status to `done`.
2. Archive:
   ```bash
   python3 ~/.claude/skills/workflow/scripts/work-card-archive.py --card 001
   ```
   Moves card and linked session files to `archive/`.
   Spike documents and facts remain in `~/.knowledge/` — they outlive the card.

---

## Recovering after a reboot

```bash
python3 ~/.claude/skills/workflow/scripts/work-session-restore.py --all
python3 ~/.claude/skills/workflow/scripts/work-session-attach.py --session 001-<repo>
```

---

## Rules

- Never read `archive/` directories. Stale context.
- Card body is what makes agent delegation effective. Populate it; never leave placeholders.
- Worktree paths must be absolute.
- Status must be one of the four valid values.
- Facts and spikes are pointers only. Never copy content into the card.
- The agent rewrites `## Current focus` in the session file after every completed subtask — never appends.
- The agent checks off tasks in the card's `## Tasks` as they complete — never at session end in bulk.
- The agent updates `## Current focus` in the card with a one-line summary of what's actively happening.
- The human updates `## Objective`, `## Context`, and `## Tasks`. The agent does not rewrite these.
