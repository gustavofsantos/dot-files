---
name: handoff
description: Write a path-free handoff prompt to a temp file that lets another agent investigate, discuss, or pick up a specific task in a fresh session.
---

# Handoff

Write a standalone prompt for a fresh agent to investigate, discuss, or work a task. Triggers: `handoff <task>`, "write a handoff", "delegate this".

## Workflow

1. Identify the task; if given only a label, infer from repo, recent discussion, branch, linked issue/PR, nearby context.
2. Gather enough to orient the receiver — repo/product identity, issue/PR/branch names, likely modules, constraints, symptoms. Don't do their review or decide their technical direction.
3. Write the prompt (template below) to a temp file: `/tmp/handoff-<short-slug>.txt`.
4. Reply with the task title and the temp file path so the user can open and copy it manually. Don't paste the full prompt unless asked.

## What makes this handoff distinct

- **It opens a discussion, not a work order.** The receiver's *first* instruction is to review and assess — decide whether the task is still real, already solved, over-scoped, or better done differently — and they own that review.
- **It is path-free.** No absolute/home/repo-relative paths or checkout names. Anchor with portable identifiers instead: repo owner/name, product/module names, issue/PR URLs, branch names, package names, public symbols, command names, config keys, exact error text, docs titles, search terms. The receiver finds the repo from cwd, a parent, or the workspace.
- **It fences side effects.** Tell the receiver not to push, merge, close issues/PRs, label, or post public comments unless the handoff explicitly says so, and to re-check live repo/CI state.

## Template

```text
I want to discuss and possibly work on: <short task title>

Context:
- <portable repo/product context>
- <what triggered this>
- <current state; branch/issue/PR names or URLs if relevant>
- <constraints and ownership boundaries>

Before any implementation:
- Find the right repo from cwd, a parent, or the usual workspace.
- Read the local agent/repo instructions.
- Inspect relevant code, docs, tests, recent commits, linked issue/PR state.
- Decide whether this is still real, whether the direction is sound, whether a smaller fix exists.
- Call out stale assumptions, hidden risks, and anything that should stop the work.

Task:
- <what to investigate or implement if the review supports it>
- <expected behavior / decision criteria>
- <non-goals>

Validation:
- <focused tests/checks/live proof expected, and what evidence to include>
- <what is explicitly not required>

Output:
- Start with review findings and a recommendation, then the plan or patch summary.
- Keep any edits scoped; report the exact proof run.
- Do not push, merge, close issues/PRs, label, or comment publicly unless explicitly told.
```

## Output file

Write the prompt to `/tmp/handoff-<short-slug>.txt` (use the Write tool, not shell heredocs — inline quoting breaks on backticks/`$`/quotes). No clipboard interaction; the user copies it manually. Report the path so they can open it.

## Quality bar

No invented facts (mark a fact reviewed only after checking it). No path leakage. Enough to orient a fresh agent, not a brain dump.
