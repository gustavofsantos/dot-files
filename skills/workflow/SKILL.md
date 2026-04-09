---
name: workflow
description: >
  Protocol for managing work using The Painter CLI — a tmux-native personal workflow system.
  Use this skill whenever working inside a painter worktree, when the user mentions a card,
  session, or painter script, when starting a new task, when asked to create or update a card,
  when context is needed about what is currently being worked on, or when the user says things
  like "new card", "start a session", "what are we working on", "recall", or "painter".
---

# Painter Workflow

Two abstractions. One source of truth.

**Card** — unit of intent. Lives at `~/.painter/cards/<nnn>-<slug>.md`.
**Session** — unit of execution for one repo front. Lives at `~/.painter/sessions/<nnn>-<repo>.md`.

The card is the source of truth. Sessions are derived. Tmux sessions are ephemeral — always reconstructable.

---

## Directory layout

```
~/.painter/
  cards/
    001-api-authentication.md
    archive/            ← archived cards and sessions — never read these
  sessions/
    001-api.md
    archive/
  .counter              ← sequential ID counter
```

---

## Card frontmatter schema

```yaml
---
id: "001"
title: "Fix auth bug"
status: inbox | not-now | active | done
tags: [feature, api, sentry]
sessions:
  - /Users/you/.painter/sessions/001-api.md
created: 2026-04-08
updated: 2026-04-08
---

## Objective
What the card is trying to accomplish and why.

## Context
Relevant background. Links to Jira, Sentry, docs.

## Current focus
What is being worked on right now.
```

**Valid statuses:** `inbox` `not-now` `active` `done`
Tags are free-form. Status is the only validated field.

---

## Session file schema

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
What is being worked on right now in this specific front.
```

---

## Scripts — reference

All scripts output JSON by default. Pass `--format text` for human-readable output.

| Script | Purpose |
|---|---|
| `painter-card-create` | Scaffold a new card |
| `painter-card-list` | List cards, filter by status or tag |
| `painter-card-archive` | Move a done card and its sessions to archive |
| `painter-session-create` | Create a session file and link it to a card |
| `painter-session-attach` | Attach to tmux session, restores if dead |
| `painter-session-restore` | Restore dead tmux sessions without attaching |
| `painter-recall` | Inject current focus into context (hook script) |

---

## Protocol

### Starting a new task

1. Determine the entry point — Jira ticket, Sentry issue, spike, planning, or scratch.
2. Create the card:
   ```
   painter-card-create --title "<title>" [--status inbox] [--tags feature,api]
   ```
3. Open the card file. Fill in `## Objective` and `## Context` from available information. Leave `## Current focus` empty until work starts.
4. If work starts immediately, update status to `active` in the frontmatter and fill `## Current focus`.

### Starting a session (one repo front)

Prerequisites: worktree must already exist. Run any project-specific worktree setup scripts first.

```
painter-session-create --card 001 --repo <repo> --branch <branch> --worktree /abs/path
```

Then attach:
```
painter-session-attach --session 001-<repo>
```

### Resuming work

```
painter-session-attach --session 001-api
```

If the tmux session is dead, `painter-session-attach` restores it automatically from the session file.

### Updating current focus

Update `## Current focus` in the session file at natural checkpoints — when switching context, before a long search, after completing a subtask. Keep it short and specific.

Update it proactively. Do not wait to be asked. It is what keeps the session anchored during long runs across large codebases.

Example:
```
## Current focus
Tracing the auth token refresh path in middleware.clj.
Hypothesis: the token is being validated before the refresh window closes.
```

### Completing a card

1. Set `status: done` in the card frontmatter.
2. Archive:
   ```
   painter-card-archive --card 001
   ```
   This moves the card and all linked session files to `archive/`.

### Recovering after a reboot

```
painter-session-restore --all
```

Then attach to the session you need:
```
painter-session-attach --session PAINT-001-api
```

---

## Rules

- Never read from `~/.painter/cards/archive/` or `~/.painter/sessions/archive/`. Stale context.
- Never create fields not in the schema. The card must be valid without any tool running.
- Worktree paths must be absolute. Expand `~` on write.
- Status must be one of the four valid values. Reject anything else.
- Tags are free-form but normalize on create — no duplicates, lowercase, hyphen-separated.
- The card body is what makes agent delegation effective. Populate it, don't leave placeholder comments.
