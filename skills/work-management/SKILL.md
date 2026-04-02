---
name: work-management
description: >
  Manages the full lifecycle of work units co-authored by a human and an AI agent.
  Work units are stories, spikes, bugs, and tasks. All work units live in shared memory.
  Session state lives locally per worktree. Use this skill whenever the user wants to
  plan, refine, or execute any work unit; when starting or ending a session; when
  checking what is in progress; or when scaffolding the .work/ structure in a new
  worktree. Triggers on phrases like "nova história", "próxima story", "vamos continuar
  o", "iniciar um spike", "encontrei um problema", "adicionar uma task", "o que está
  em andamento", "setup do .work", or any reference to the .work/ directory or work
  unit lifecycle.
---

# Work Management

---

## Storage layout

```
~/.config/shared-memory/work/
  stories/            ← all work units (stories, spikes, bugs, tasks)
  knowledge/
    {system}/
      knowledge-base.md   ← per-system knowledge base (used by legacy-analysis)

{worktree}/
  .work/
    session.md        ← this worktree's active session (local, never committed)
```

`stories/` is global — shared across all repos and worktrees.
`session.md` is local to each worktree — inside the repo boundary, no permission friction.

**One-time setup:** grant Claude Code read/write access to `~/.config/shared-memory/`
so it never prompts during a session.

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
Next id: `ls ~/.config/shared-memory/work/stories/ | tail -1` and increment.

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
repo:
tags: [backend, frontend]
refs:
  - label: "PR"
    url: "https://github.com/org/repo/pull/42"
---
```

Valid `type` values: `story` `spike` `bug` `task`

Valid `status` values: `backlog` `ready` `in-progress` `review` `done` `abandoned`

`repo` — the primary repo this unit is scoped to, if any. Leave blank for cross-repo work.
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

One `session.md` per worktree. It identifies which work unit is active here and
anchors current state across tool calls and agent switches.

For `spike` type, session.md also carries traversal state — it replaces
`session-state.md` from legacy-analysis. Both skills read and rewrite the same file.

See `assets/session-template.md` for format by type.

---

## Querying

```bash
# overview of all work units
head -8 ~/.config/shared-memory/work/stories/*.md | grep -E "(id:|type:|status:|title:|repo:)"

# by status
grep -rl "status: in-progress" ~/.config/shared-memory/work/stories/
grep -rl "status: review" ~/.config/shared-memory/work/stories/

# by type
grep -rl "type: spike" ~/.config/shared-memory/work/stories/

# by repo
grep -rl "repo: my-repo" ~/.config/shared-memory/work/stories/

# current worktree session
cat .work/session.md
```

---

## Session start — intent interpretation

The human's instruction is the session start signal. Interpret it and act:

| Human says | Action |
|---|---|
| "continue / work on NNN" | Find NNN, read it, update `session.md`, execute from Active task |
| "refine NNN" | Find NNN, help define ACs and tasks, set `status: ready` |
| "found a problem / X is broken" | Create `bug`, link to related unit in `refs` if applicable |
| "start a spike on X" | Create `spike`, hand off execution to `legacy-analysis` skill |
| "add logs / fix config / refactor X" | Create `task`, set `status: in-progress` |

Find an existing work unit by id: `ls ~/.config/shared-memory/work/stories/NNN-*.md`.

**After resolving intent:**

1. Read the work unit file
2. If `.work/session.md` exists: read it. If not: create from `assets/session-template.md`
3. **Rewrite `.work/session.md`** — update `agent`, `updated`, and `unit` fields
4. For `story`: verify Tasks are defined — if empty, stop and ask human to run `story-task-planner`
5. For `spike`: switch to `legacy-analysis` skill for execution
6. Confirm no ambiguity before proceeding

---

## Agent protocol — during execution

After each completed task:

1. Mark `[x]` in the work unit Tasks section
2. Add at least one line to Implementation Notes
3. **Rewrite `.work/session.md`:** move task to Completed, promote next to Active,
   update Working context and `updated` timestamp
4. New work outside scope → new work unit in shared-memory with `status: backlog`
5. New external resource → add to `refs` in front-matter

---

## Agent protocol — model handoff

**Outgoing:** finish at a task boundary. Write one sentence in Working context:
`Handoff: <what was done and what comes next>`. Rewrite `.work/session.md`.

**Incoming:** read work unit, read `.work/session.md`, rewrite it updating `agent`,
`updated`, and appending `Picked up from <previous-agent>`. Proceed from Active task.

---

## Agent protocol — session end

1. All completed tasks marked `[x]` in work unit and `session.md`
2. Set Active task to `(none — awaiting human review)`
3. Write final summary in Working context
4. Set `status: review` in work unit front-matter
5. Report: items completed, pending, blockers
6. Leave `.work/session.md` in place until human sets `status: done`

---

## Creating a new work unit

1. Determine next id: `ls ~/.config/shared-memory/work/stories/ | tail -1`
2. Create `~/.config/shared-memory/work/stories/NNN-slug.md` using the appropriate template
3. Set `status: backlog` (or `in-progress` directly for `bug`, `task`, `spike`)

Templates: `assets/story-template.md` `assets/spike-template.md`
`assets/bug-template.md` `assets/task-template.md`

---

## Anti-patterns

| Anti-pattern | Correct behavior |
|---|---|
| Starting without reading `session.md` | Read it, then rewrite before any tool call |
| Skipping `session.md` rewrite after a task | Rewrite after every completed task |
| Updating work unit but not `session.md` | Both files updated together |
| Handing off without a handoff note | One sentence in Working context first |
| Expanding scope mid-session | New work unit in shared-memory backlog |
| Setting `status: done` | Human only |
| Skipping Implementation Notes | At least one line per completed task |
| Storing session.md in shared-memory | session.md is always local to the worktree |

---

## Setup

```bash
mkdir -p ~/.config/shared-memory/work/stories
mkdir -p .work
```
