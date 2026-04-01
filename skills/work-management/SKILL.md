---
name: work-management
description: >
  Manages the full lifecycle of user stories co-authored by a human and an AI agent,
  using a flat file-based backlog inside the repository. Use this skill whenever the user
  wants to plan, refine, or execute a user story; when starting or ending a development
  session; when checking what is currently in progress; or when scaffolding the
  .work/ structure in a new repository. Triggers on phrases like "nova história",
  "próxima story", "o que está em andamento", "setup do .work", "iniciar sessão",
  "concluir story", "mover para ready", or any reference to the .work/ directory or
  the story lifecycle.
---

# Work Management

A file-based story lifecycle that lives inside the repository.
Stories are Markdown files with YAML front-matter. State is metadata, not directories.
History is Git. The agent and the human collaborate through the same files.

---

## Directory layout

```
.work/
  stories/        ← all stories, regardless of status
  session.md      ← current context snapshot (created when a session starts)
```

No subdirectories per state, no scripts, no templates directory.
Stories are plain Markdown files. The agent creates them directly.
`session.md` is the recitation document — rewritten after every completed task.

---

## Story file format

### Naming convention

`NNN-slug.md` where NNN is a zero-padded sequential id and slug is a short kebab-case
title. Examples:

```
001-setup-fretboard-canvas.md
002-stripe-checkout-flow.md
003-refactor-chord-voicings.md
```

To find the next id: `ls .work/stories/ | tail -1` and increment.

### Front-matter schema

Every story file starts with this YAML front-matter:

```yaml
---
id: "003"
title: "Setup fretboard canvas rendering"
status: backlog
created: 2026-03-31
started:
completed:
tags: [backend, frontend]
refs:
  - label: "Jira"
    url: "https://company.atlassian.net/browse/PROJ-123"
  - label: "PR"
    url: "https://github.com/org/repo/pull/42"
---
```

**Field rules:**

- `status` — one of: `backlog`, `ready`, `in-progress`, `review`, `done`, `abandoned`
- `created` — date the file was created (YYYY-MM-DD)
- `started` — date the story entered `in-progress` (null until then)
- `completed` — date the story was moved to `done` (null until then)
- `tags` — freeform list, useful for filtering by project or domain
- `refs` — list of `{label, url}` pairs linking to external resources (Jira tickets,
  GitHub PRs, Figma files, Slack threads, Google Docs, etc). Add refs as they become
  available throughout the story lifecycle, not only at creation time.

### Body structure

After the front-matter, the story body follows this structure:

```markdown
## História

Como [tipo de usuário],
quero [ação concreta],
para que [resultado mensurável].

## Critérios de aceitação

- [ ] condição observável 1
- [ ] condição observável 2
- [ ] condição observável 3

## Fora do escopo

- item explicitamente excluído

## Tasks

### Task 1: título curto
**Objetivo:** uma frase
**Depende de:** nenhuma | Task N
**Escopo:**
- Inclui: o que será tocado
- Exclui: o que NÃO deve ser tocado

**Pronto quando:**
- [ ] condição verificável

### Task 2: ...

## Notas de implementação

[preenchido pelo agente durante a execução]
```

---

## Story lifecycle

```
backlog → ready → in-progress → review → done
                                           ↘ abandoned (from any state)
```

State transitions happen by editing the `status` field in the front-matter.
The **agent** sets `status: review` when all tasks are complete. This frees the WIP slot.
Only the **human** sets `status: done` (accepted) or moves back to `in-progress` (rework needed).

**WIP limit:** at most ONE story with `status: in-progress` at any time.
A story in `review` does not count against the WIP limit.

---

## Querying stories

No scripts needed. Use standard unix commands:

```bash
# what is in progress right now?
grep -l "status: in-progress" .work/stories/*.md

# what is waiting for human review?
grep -l "status: review" .work/stories/*.md

# list all stories in the backlog
grep -l "status: backlog" .work/stories/*.md

# all stories tagged with a project
grep -l "fretfire" .work/stories/*.md

# quick overview: id, status, title for all stories
head -6 .work/stories/*.md | grep -E "(id:|status:|title:)"

# read the first 20 lines of a story (front-matter + história)
head -20 .work/stories/003-setup-fretboard-canvas.md

# is there an active session?
cat .work/session.md

# which story is the session tracking?
head -5 .work/session.md | grep story

# what agent last touched the session?
head -5 .work/session.md | grep agent
```

---

## Roles

### Human responsibilities
- Write the initial story draft (use `user-story-builder` skill)
- Break it into tasks (use `story-task-planner` skill)
- Set `status: ready` when tasks are defined
- Set `status: in-progress` to start a session
- Review stories in `review` against acceptance criteria
- Set `status: done` after review passes, or `status: in-progress` if rework is needed
- Delete `session.md` after setting `status: done`

### Agent responsibilities
- Find and read the `in-progress` story before doing anything
- Read and rewrite `session.md` at session start (create if absent)
- Derive the session contract from Acceptance Criteria and Tasks
- Work through tasks in declared order
- After each task: update both the story file and `session.md`
- Stop and ask if any AC is ambiguous before starting

---

## session.md

The story is the **contract** — stable, authoritative, permanent.
`session.md` is **current state** — volatile, always overwritten, tail-anchored.

Together they let any agent pick up a session cold with no context loss.
The story gives the goal; `session.md` gives where things stand right now.

Only one `session.md` exists at a time, mirroring the WIP limit on stories.

### Format

```markdown
---
story: "NNN-slug"
agent: claude-code | cursor | gemini | ...
started: YYYY-MM-DDTHH:MM:SS
updated: YYYY-MM-DDTHH:MM:SS
---

# Session: <story title>

## Active task
- [ ] <the single task currently being worked on>

## Remaining tasks
- [ ] <next task>
- [ ] <task after that>

## Completed this session
- [x] <task 1>
- [x] <task 2>

## Working context
<!-- Written for a fresh agent that has never seen this session. -->
<!-- Mandatory. At minimum one line after each completed task. -->
<!-- What was decided, which files were touched, what the current state is. -->

## Blockers / questions
<!-- Empty means none. -->
```

The task lists mirror the story's Tasks section. The story remains authoritative —
`session.md` only tracks position and live context.

---

## Agent protocol — session start

Before writing a single line of code:

1. `grep -l "status: in-progress" .work/stories/*.md` — find the active story
2. Read the full story file (establishes the contract)
3. Check if `.work/session.md` exists
   - **Exists:** read it — current state left by the previous agent or session
   - **Does not exist:** create it, populate task lists from the story's Tasks section
4. **Rewrite `session.md` immediately** — update `agent` and `updated` fields.
   This recitation act anchors the current goal at the tail of the context
   before any tool call is made.
5. Verify Tasks are defined in the story — if empty, stop and ask the human to run
   `story-task-planner` first
6. Confirm no AC is ambiguous — ask before proceeding

**If no story is in-progress:** stop. Do not invent scope. Ask the human to set a
story to `in-progress` first.

---

## Agent protocol — during execution

- Work task by task in declared order
- After completing each task:
  1. Mark it `[x]` in the **story file** Tasks section (permanent record)
  2. Add at least one line to Implementation Notes in the **story file**
  3. **Rewrite `session.md`:**
     - Move the completed task from Active/Remaining into Completed
     - Promote the next task to Active
     - Update Working context with the decision or state change just made
     - Update the `updated` timestamp
- Scope boundary: if new work surfaces that is not in the ACs, create a new story
  in `.work/stories/` with `status: backlog` — do not fold it into the current session
- When a relevant external resource appears (PR opened, doc created), add it to
  `refs` in the story front-matter

The `session.md` rewrite is the recitation. It keeps the goal visible at the context
tail across the entire session, regardless of how many tool calls accumulate.

---

## Agent protocol — model handoff

When switching agents mid-story (Claude Code → Cursor, etc.):

**Outgoing agent — before stopping:**
1. Complete or pause at a clean task boundary (do not hand off mid-task)
2. Write a handoff note in Working context:
   `Handoff: <one sentence on what was just done and what the next step is>`
3. Rewrite `session.md` with the handoff note in place

**Incoming agent — before starting:**
1. Read the story (contract)
2. Read `session.md` (current state, with handoff note)
3. Rewrite `session.md` — update `agent` and `updated`, append
   `Picked up from <previous-agent>` in Working context
4. Proceed from Active task

The rewrite on pickup is mandatory. It recites the goals into the incoming
agent's context tail before any work begins.

---

## Agent protocol — session end

1. All completed tasks marked `[x]` in both story and `session.md`
2. Implementation Notes have at least one entry per completed task
3. Set Active task in `session.md` to `(none — awaiting human review)`
4. Write a final summary line in Working context: what was done, what remains, blockers
5. Set `status: review` in the **story front-matter** (frees the WIP slot)
6. Report to human: which ACs are satisfied, which are not, any blockers
7. Do NOT set `status: done` — that is the human's action after review
8. Leave `session.md` in place until the human sets `status: done`

---

## Creating a new story

When the human asks for a new story (or when scope expansion requires one):

1. Determine the next id from existing files
2. Create `.work/stories/NNN-slug.md` with the front-matter and body structure
3. Set `status: backlog`
4. Fill what is known — the rest gets filled during refinement

No script, no template file to copy. Just write the Markdown file directly.

---

## Anti-patterns

| Anti-pattern | Correct behavior |
|---|---|
| Starting without an in-progress story | Stop. Ask the human. |
| Starting without reading `session.md` | Always read it if it exists, then rewrite |
| Skipping the `session.md` rewrite after a task | Rewrite after every completed task |
| Updating story tasks but not `session.md` | Both must be updated together |
| Expanding scope mid-session | New story with `status: backlog`. Keep current scope. |
| Marking task done based on intent | Verify against actual observable behavior first |
| Setting `status: done` | Only the human does this after review |
| Leaving story as `in-progress` after finishing | Set `status: review` to free the WIP slot |
| Skipping Implementation Notes | At least one line per completed task |
| Batch-updating notes at session end | Update notes after each task, not at the end |
| Handing off without a handoff note | Write one sentence in Working context first |
| Leaving Working context empty | At minimum one line after any task completion |
| Deleting `session.md` before human sets `done` | Leave it in place through review |
| Reading all story files to find status | Use `grep` on front-matter |

---

## Setup in a new repository

```bash
mkdir -p .work/stories
```
