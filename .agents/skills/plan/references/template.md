# Plan template

Copy everything below the line into `PLAN.md` at the repository root. Replace each
`<…>`. Remove a section only if it would stay empty.

---

~~~~markdown
# Plan: <goal in one line>

Branch: `<branch>` · Base: `<base>`

## How to work this plan

This file is the source of truth for this branch. It is deleted before the pull request.

1. Read the whole file before you change code.
2. Take the first slice whose status is not `done`. Work only that slice.
3. Stay inside its files and the decisions below. Do not reopen a decision.
4. Run its **Done when** and the **Verification** commands. All must pass.
5. Update this file: slice status to `done` with the commit subject, new **Notes**,
   one **Log** line.
6. Commit the slice's code and this file together, in one commit.
7. If a decision, a later slice, or the scope must change: set the slice to `blocked`,
   write the finding under **Open questions**, commit this file, and stop.

## Goal

<What changes for the user or system, and why. Two to five sentences.>

## Context

<What an executor must know that the code does not say: the current behavior, the
relevant modules and how they connect, constraints, links.>

## Decisions

- <Decision>. Reason: <why>. Rejected: <alternative and why not>.

## Out of scope

- <What this branch must not change.>

## Verification

```bash
<command that runs the relevant tests>
<lint / typecheck / benchmark command>
```

## Slices

### 1. <slice title>

Status: todo  <!-- todo | in progress | done (<commit subject>) | blocked -->

- **Goal:** <the observable result of this slice>
- **Files:** `<path>`, `<path>`
- **Steps:**
  1. <step>
  2. <step>
- **Done when:** <check a command can prove, e.g. `<test command>` passes and covers X>

### 2. <slice title>

Status: todo

…

## Notes

<Findings the next session needs. Append; do not rewrite history.>

## Open questions

<Findings that need the plan's author. Empty while the plan holds.>

## Log

- <YYYY-MM-DD> · slice <n> · <one-line outcome>
~~~~
