---
name: handoff
description: Write a path-free handoff prompt to a temp file that lets another agent investigate, discuss, or pick up a specific task in a fresh session.
---

# Handoff

Write a standalone prompt for a fresh agent to investigate, discuss, or work a task. Triggers: `handoff <task>`, "write a handoff", "delegate this".

## Workflow

1. Identify the task; if given only a label, infer from repo, recent discussion, branch, linked issue/PR, nearby context.
2. Gather enough to orient the receiver — repo/product identity, issue/PR/branch names, likely modules, constraints, symptoms. Don't do their review or decide their technical direction.
3. Write the prompt (template below) to `/tmp/handoff-<short-slug>.txt`.
4. Reply with the task title and the temp file path. Don't paste the full prompt unless asked.

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

Write to `/tmp/handoff-<short-slug>.txt` using the Write tool (not shell heredocs — inline quoting breaks on backticks/`$`/quotes). No clipboard interaction; the user copies it manually. Report the path.

## Quality bar

No invented facts. No path leakage — use portable identifiers: repo owner/name, issue/PR URLs, branch names, package names, exact error text. Enough to orient a fresh agent, not a brain dump.
