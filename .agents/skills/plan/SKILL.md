---
name: plan
description: Keep a PLAN.md on a feature branch that describes the whole change as ordered slices, guides every session that works the branch, gets a commit per slice, and is deleted before the pull request. Use when the user asks to plan a branch with PLAN.md, or when PLAN.md exists at the root of the current branch.
---

# Plan

`PLAN.md` at the repository root is the branch's working memory. One session writes it;
any session, on any model, works it. It is committed with every slice, so `git log` shows
how the plan evolved. The last commit deletes it, so the pull request diff never shows it.

Find the phase from the branch state:

- No `PLAN.md` and the user asked for a plan → **Author**.
- `PLAN.md` with an open slice → **Execute**.
- `PLAN.md` with every slice done → **Close**.

This skill replaces the in-conversation plan of `way-of-planning`. Its EARS phrasing still
fits a slice's **Goal**, and `way-of-work` can drive a slice's red-green loop.

## Author

1. Confirm you are on a feature branch, not the default branch. If `PLAN.md` already exists
   on the base branch, stop and ask: this workflow needs the file to be branch-only.
2. Explore until you can name the files, the risks, and the commands that prove the change.
   Phrase domain terms in the user's ubiquitous language (`vocabulary`).
3. Write `PLAN.md` from [references/template.md](references/template.md). Write for a
   cheaper model that has not seen this conversation:
   - Each slice is thin and vertical. It goes green on its own, does not break an earlier
     slice, and ends in one commit.
   - Each slice names its files, its steps, and a **Done when** that a command can check.
   - Put every decision and its reason in **Decisions**, so an executor does not reopen it.
   - Put what the change must not touch in **Out of scope**.
   - Keep the **How to work this plan** section from the template. An executor may not
     have this skill loaded; the file must carry its own protocol.
4. Show the plan and wait for approval. Apply requested changes.
5. Commit only `PLAN.md`: `plan: <goal>`. Stop. Execution is a separate session or an
   explicit go-ahead.

## Execute

Read `PLAN.md` in full before you touch code. It overrides your own idea of the next step.

1. Take the first slice whose status is not `done`. Work only that slice.
2. Run the slice's steps. Stay inside the slice's files and the plan's decisions.
3. Run the **Done when** checks and the plan's **Verification** commands. Do not mark a
   slice done on a failing or skipped check.
4. Update `PLAN.md`:
   - Set the slice's status to `done` and add the short commit subject.
   - Add to **Notes** what the next session needs: a surprise, a workaround, a number
     from a benchmark, a file that turned out to matter.
   - Add a line to **Log**: date, slice, one-line outcome.
5. Commit the slice's code and the `PLAN.md` update together, in one commit. The commit
   at `HEAD` is then always a valid resume point.
6. Stop after one slice unless the user asked you to continue through the plan.

If the plan is wrong:

- A detail the slice did not foresee (a renamed file, an extra import) → adapt, and
  record it in **Notes**.
- A change to a decision, to a later slice's intent, or to scope → do not rewrite the
  plan. Set the slice to `blocked`, write the finding under **Open questions**, commit
  `PLAN.md`, and return control to the user. The plan's author revises it.

## Close

1. Run every **Verification** command once more on the full branch.
2. If the user wants a pull request, draft its description from `PLAN.md` now, while the
   file still exists (`create-pull-request`). Goal, Decisions and Notes are the source.
3. Delete `PLAN.md` and commit: `plan: remove PLAN.md`. Do not squash or rewrite earlier
   commits; the plan's history stays in the branch.
4. Confirm `git diff <base>...HEAD -- PLAN.md` is empty.
