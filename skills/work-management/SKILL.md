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
```

That's it. No subdirectories per state, no scripts, no templates directory.
Stories are plain Markdown files. The agent creates them directly.

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

### Agent responsibilities
- Find and read the `in-progress` story before doing anything
- Derive the session contract from Acceptance Criteria and Tasks
- Work through tasks in declared order
- Check off tasks as completed (`- [x]`)
- Update Implementation Notes after each task completion
- Stop and ask if any AC is ambiguous before starting

---

## Agent protocol — session start

Before writing a single line of code:

1. Run `grep -l "status: in-progress" .work/stories/*.md` to find the active story
2. Read the full story file
3. Verify Tasks section is populated — if empty, tell the human to use
   `story-task-planner` first
4. Confirm no AC is ambiguous — ask before proceeding

**If no story is in-progress:** stop. Do not invent scope. Ask the human to set a
story to `in-progress` first.

---

## Agent protocol — during execution

- Work task by task in declared order
- After completing each task:
  - Mark it `[x]` in the story file
  - Add at least one line to Implementation Notes describing the decision or approach
- Scope boundary: if new work surfaces that is not in the ACs, create a new story
  file in `.work/stories/` with `status: backlog` — do not fold it into the current
  session
- When a relevant external resource appears (a PR is opened, a doc is created),
  add it to the `refs` list in the front-matter

---

## Agent protocol — session end

1. Ensure all completed tasks are marked `[x]`
2. Implementation Notes must have at least one entry per completed task
3. Set `status: review` — this signals the human that work is ready for evaluation
4. Report to human: which ACs are satisfied, which are not, any blockers
5. Do NOT set `status: done` — that is the human's action after review

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
| Expanding scope mid-session | New story with `status: backlog`. Keep current scope. |
| Marking task done based on intent | Verify against actual observable behavior first |
| Setting `status: done` | Only the human does this after review |
| Leaving story as `in-progress` after finishing | Set `status: review` to free the WIP slot |
| Skipping Implementation Notes | At least one line per completed task |
| Batch-updating notes at session end | Update notes after each task, not at the end |
| Reading all story files to find status | Use `grep` on front-matter |

---

## Setup in a new repository

```bash
mkdir -p .work/stories
```

