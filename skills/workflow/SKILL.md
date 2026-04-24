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

**Card** — unit of intent. Lives at `~/engineering/cards/<nnn>-<slug>.md`.
**Session** — unit of execution for one repo front. Lives at `~/engineering/sessions/<nnn>-<repo>.md`.

The card is the source of truth. Sessions are derived. Tmux sessions are ephemeral.

---

## Directory layout

```
~/engineering/
  cards/
    001-fix-auth-bug.md
    archive/            ← completed cards — never read these
  sessions/
    001-api.md
    archive/
  facts/                ← managed by the knowledge skill
  spikes/               ← managed by the knowledge skill
  .counters/
    cards
    facts
    spikes
```

---

## MCP tools — engineering server

Card and session operations use the `engineering` MCP server directly. No scripts.

| Tool | Purpose |
|---|---|
| `card_create(title, status?, tags?)` | Scaffold a new card |
| `card_list(status?, tag?)` | List non-archived cards |
| `card_get(id)` | Read full card content |
| `card_set_status(id, status)` | Update card status |
| `card_archive(id, force?)` | Move done card + sessions to archive |
| `session_create(card_id, repo, branch, worktree)` | Create session and link to card |
| `session_get(session_id)` | Read full session content |
| `session_update_focus(session_id, done[], in_progress, next[])` | Rewrite Current focus |

**Valid statuses:** `inbox` `not-now` `active` `done`

## Shell scripts — tmux and hooks only

Scripts that have no MCP equivalent live at `~/.claude/skills/workflow/scripts/`.

| Script | Purpose |
|---|---|
| `work-session-attach.py` | Attach to tmux session, restores if dead |
| `work-session-restore.py` | Restore dead tmux sessions without attaching |
| `work-recall.py` | PostToolUse hook — injects Current focus into context |

```bash
SCRIPTS=~/.claude/skills/workflow/scripts

python3 $SCRIPTS/work-session-attach.py --session 001-api
python3 $SCRIPTS/work-session-restore.py --all
```

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
  - /abs/path/to/engineering/sessions/001-api.md
spikes:
  - "[[001-auth-token-investigation]]"
facts:
  - "[[FACT-007-auth-token-refresh-window]]"
  - "[[FACT-012-billing-cycle-immutability]]"
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

**On card completion:** when all tasks in `## Tasks` are checked `[x]`, the agent
signals the human: "All tasks are complete. Ready for review." The human then
runs the review skill and archives the card. The agent never moves a card to `done`
unilaterally.

`facts` — wiki links to facts in `~/engineering/facts/` discovered while working this card.
`spikes` — wiki links to spike narratives in `~/engineering/spikes/`.
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
- [x] Example: scaffolded migration file

### In progress
- [ ] Example: implementing the query with optional filter

### Next
- [ ] Example: handler wiring and integration test
```

**The agent calls `session_update_focus` after each completed subtask** — never
manually edits the session file. The tool atomically rewrites the Current focus
section, moving done items, updating in-progress, and reordering next.

`work-recall.py` extracts the entire `## Current focus` block and injects it after
every tool call. The agent always sees the current state of Done / In progress / Next.

---

## Skill integration

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

```
knowledge_query(query: "<card title> <card objective>", min_score: 0.5, n: 8)
```

Load the returned facts into working context.
If nothing scores above threshold, proceed without — do not ask the human.
If something relevant surfaces that the human hasn't mentioned, note it:

> "Before we start — [[FACT-012-auth-token-refresh]] covers auth token refresh behavior in this system.
> Worth keeping in mind."

Do not read spike narratives unless a fact ID points to one that is directly relevant.
Spikes are large; facts are small.

---

## Phase 1 — Planning a card

Entry points: Jira ticket, Sentry issue, verbal description, scratch idea.

1. Create the card:
   ```
   card_create(title: "<title>", status: "inbox", tags: ["feature", "api"])
   ```
2. Fill `## Objective` from available information using `card_get(id)` then write.
3. Fill `## Context` with background, links, and any constraints.
4. Run knowledge retrieval. Surface relevant facts to the human.
5. If the objective requires investigation before planning:
   → invoke `dead-reckoning`. The spike document is linked in the card's `spikes:` field.
   → facts discovered are promoted to `~/engineering/facts/` and listed in `facts:`.
6. If the objective is clear enough to implement:
   → invoke `user-story-builder` if the scope needs shaping.
   → invoke `user-story-planner` to break into tasks.
   → write the resulting tasks into `## Tasks` in the card.
   → `card_set_status(id, "active")`

**Card stays lean.** Objective + context + tasks + pointers. No prose that belongs in a spike.

---

## Phase 2 — Executing a card

### Starting a session

Prerequisites: worktree must already exist. Card must have tasks defined in `## Tasks`.

```
session_create(card_id: "001", repo: "<repo>", branch: "<branch>", worktree: "/abs/path")
```

Then attach via tmux:
```bash
python3 ~/.claude/skills/workflow/scripts/work-session-attach.py --session 001-<repo>
```

### Session start protocol

1. Run knowledge retrieval (see above).
2. `card_get("001")` — read objective, context, and full `## Tasks` list.
3. `session_get("001-<repo>")` — read current focus if session exists.
4. Call `session_update_focus` to set initial state:
   - `done: []`
   - `in_progress: "<first unchecked task from card ## Tasks>"`
   - `next: [<remaining unchecked tasks in order>]`
5. State what you understand and what you're about to do. Wait for confirmation
   if anything is ambiguous.

### During execution

**After each completed subtask:**

1. Call `session_update_focus(session_id, done, in_progress, next)`:
   - Move the finished item to `done` (it will render as `[x]`)
   - Set `in_progress` to the next task
   - Pass remaining tasks in `next`
2. Mark the corresponding task `[x]` in the card's `## Tasks` (edit the card file directly).
3. Update `updated:` date in the card frontmatter.

**When `next` is empty and `in_progress` is done:**

Signal to the human:
> "All planned tasks are complete. Ready for review."

Do not set card status to `done`. That is the human's action after review passes.

**Scope discipline:**

- New work that surfaces outside card scope → `card_create(title, status: "inbox")`, do not expand scope.
- New fact discovered → invoke `knowledge` skill. Add wiki link to card's `facts:` field.

### Context recovery

When resuming an interrupted session or switching worktrees:

1. `session_get("001-<repo>")` → Current focus is the anchor.
2. `card_get("001")` → confirms which tasks are checked overall.
3. Run knowledge retrieval.
4. Reconstruct: "We were doing X because of Y. The next step was Z."
5. State the reconstruction to the human before proceeding.

### Model handoff

**Outgoing:** finish at a task boundary. Call `session_update_focus` to ensure state is
current. Append one sentence to `in_progress`: `Handoff: <what was done and what comes next>`.

**Incoming:** `card_get`, `session_get`, run knowledge retrieval. Call `session_update_focus`
if state is stale. Proceed.

---

## Phase 3 — Reviewing a card

When all tasks are complete, invoke `review` skill.
The review skill handles both safety/scope review and architectural depth.
Do not reproduce its protocol here.

After review passes:
1. `card_set_status(id, "done")`
2. `card_archive(id)` — moves card and linked session files to `archive/`.
   Spike documents and facts remain in `~/engineering/` — they outlive the card.

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
- Facts and spikes are pointers only. Never copy content into the card. Reference by wiki link.
- The agent calls `session_update_focus` after every completed subtask — never appends or edits the session file directly.
- The agent checks off tasks in the card's `## Tasks` as they complete — never at session end in bulk.
- The human updates `## Objective`, `## Context`, and `## Tasks`. The agent does not rewrite these.
