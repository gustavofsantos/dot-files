---
name: work-management
description: >
  Manages the full lifecycle of work units co-authored by a human and an AI agent,
  using a flat file-based backlog inside the repository. Work units are stories, spikes,
  bugs, and tasks. Use this skill whenever the user wants to plan, refine, or execute
  any work unit; when starting or ending a session; when checking what is in progress;
  or when scaffolding the .work/ structure in a new repository. Triggers on phrases
  like "nova história", "próxima story", "vamos continuar o", "iniciar um spike",
  "encontrei um problema", "adicionar uma task", "o que está em andamento",
  "setup do .work", or any reference to the .work/ directory or work unit lifecycle.
---

# Work Management

---

## Directory layout

```
.work/
  stories/      ← all work units, shared across worktrees (symlinked)
  session.md    ← this worktree's active claim (one per worktree)
```

`stories/` is shared. `session.md` is local to each worktree.
Multiple worktrees can have different work units in progress simultaneously.

---

## Work unit types

| Type | Use for |
|---|---|
| `story` | Feature work with user-facing value |
| `spike` | Timeboxed exploration to answer a specific question |
| `bug` | Observed defect with expected vs actual behavior |
| `task` | Everything else: refactors, logs, config, one-offs |

---

## File naming

`NNN-slug.md` — zero-padded sequential id + kebab-case slug.
Next id: `ls .work/stories/ | tail -1` and increment.

---

## Front-matter schema

```yaml
---
id: "003"
title: "Setup fretboard canvas rendering"
type: story
status: backlog
created: 2026-03-31
started:
completed:
tags: [backend, frontend]
refs:
  - label: "PR"
    url: "https://github.com/org/repo/pull/42"
---
```

Valid `type` values: `story` `spike` `bug` `task`

Valid `status` values: `backlog` `ready` `in-progress` `review` `done` `abandoned`

`started` — set when entering `in-progress`. `completed` — set when entering `done`.
Add `refs` as they become available.

Body structure varies by type — see `assets/`.

---

## Lifecycle

```
backlog → ready → in-progress → review → done
                                           ↘ abandoned
```

`ready` (tasks defined) is required for `story`. Optional for `spike`, `bug`, `task` —
those can move directly from `backlog` to `in-progress`.

Agent sets `status: review` when work is complete. Human sets `status: done` or
returns to `in-progress` for rework.

---

## session.md — worktree claim

`session.md` is this worktree's active claim. It identifies which work unit is in
progress here and anchors current state for context continuity across tool calls
and agent switches.

One `session.md` per worktree at a time. See `assets/session-template.md` for format.

---

## Querying

```bash
# overview of all work units
head -8 .work/stories/*.md | grep -E "(id:|type:|status:|title:)"

# by status
grep -rl "status: in-progress" .work/stories/
grep -rl "status: review" .work/stories/

# by type
grep -rl "type: spike" .work/stories/

# current worktree session
cat .work/session.md
```

---

## Session start — intent interpretation

The human's instruction is the session start signal. Interpret it and act:

| Human says | Action |
|---|---|
| "continue / work on NNN" | Find NNN, read it, claim in `session.md`, execute from Active task |
| "refine NNN" | Find NNN, help define ACs and tasks, set `status: ready` |
| "found a problem in NNN / X is broken" | Create `bug`, link to NNN in `refs` if applicable, claim in `session.md` |
| "start a spike on X" | Create `spike`, set `status: in-progress`, create `session.md` |
| "add logs / fix config / refactor X" | Create `task`, set `status: in-progress`, create `session.md` |

Find an existing work unit by id: `ls .work/stories/NNN-*.md`.

**After resolving intent:**

1. Read the work unit file
2. If `session.md` exists: read it. If not: create from `assets/session-template.md`
3. **Rewrite `session.md`** — update `agent`, `updated`, and `unit` fields
4. For `story`: verify Tasks are defined — if empty, stop and ask human to run `story-task-planner`
5. Confirm no ambiguity before proceeding

---

## Agent protocol — during execution

After each completed task:

1. Mark `[x]` in the work unit Tasks section
2. Add at least one line to Implementation Notes (or Findings for spikes)
3. **Rewrite `session.md`:** move task to Completed, promote next to Active, update Working context and `updated` timestamp
4. New work outside scope → new work unit in `backlog`, do not expand current scope
5. New external resource → add to `refs` in front-matter

---

## Agent protocol — model handoff

**Outgoing:** finish at a task boundary. Write one sentence in Working context:
`Handoff: <what was done and what comes next>`. Rewrite `session.md`.

**Incoming:** read work unit, read `session.md`, rewrite `session.md` updating `agent`,
`updated`, and appending `Picked up from <previous-agent>`. Proceed from Active task.

---

## Agent protocol — session end

1. All completed tasks marked `[x]` in work unit and `session.md`
2. Set Active task to `(none — awaiting human review)`
3. Write final summary in Working context
4. Set `status: review` in work unit front-matter
5. Report: items completed, pending, blockers
6. Leave `session.md` in place until human sets `status: done`

---

## Creating a new work unit

1. Determine next id: `ls .work/stories/ | tail -1`
2. Create `.work/stories/NNN-slug.md` using the appropriate asset template
3. Set `status: backlog` (or `in-progress` directly for `bug`, `task`, `spike`)

Templates: `assets/story-template.md` `assets/spike-template.md`
`assets/bug-template.md` `assets/task-template.md`

---

## Anti-patterns

| Anti-pattern | Correct behavior |
|---|---|
| Grepping for in-progress to start a session | Read human intent, find or create the unit |
| Starting without reading `session.md` | Read it, then rewrite before any tool call |
| Skipping `session.md` rewrite after a task | Rewrite after every completed task |
| Updating work unit but not `session.md` | Both files updated together |
| Handing off without a handoff note | One sentence in Working context first |
| Expanding scope mid-session | New work unit in backlog |
| Setting `status: done` | Human only |
| Skipping Implementation Notes | At least one line per completed task |

---

## Setup

```bash
mkdir -p .work/stories
```
