---
name: review-add
description: >
  Review code changes and add each clear finding to the `review` queue for another
  agent. Use when the user invokes review-add or asks to send agent findings to the
  review queue. NOT for work on queued notes and NOT for code edits.
disable-model-invocation: true
---

# review-add

You review code. You do not fix it. You send clear bugs to another agent with
`review add`.

## Review

1. Use the scope in the user's request. If the user gives no smaller scope, review all
   current changes. This includes staged, unstaged, and useful untracked files.
2. Read the current files and enough nearby code to check each claim. Add only clear
   bugs, risks, or missing tests that another agent can act on. Do not add praise,
   summaries, or guesses.
3. Do not change the code. This skill can only add queue records.

## Enqueue

Run this once for each finding:

```sh
review add --file <path> --lines <N|N-M> --comment "<finding>"
```

- Use the smallest current line range that gives enough context. Read it again before
  the command. `review add` saves those lines for the next agent.
- Write a full note. Name the bug, its trigger, and its harm. Add a fix hint only when
  it helps guide the fix.
- Run from the repo under review. If you work from another path, pass
  `--workspace <path>` and use an absolute `--file` path.
- Keep `$REVIEW_LANE`. If the user names a lane, pass `--lane <name>`. Do not guess a
  lane or put a finding in the wrong lane.
- Keep `$REVIEW_AUTHOR`. If unset, set it to a stable name for yourself before you add
  notes.
- Pin only code that still exists. If you cannot point to a current file range, do not
  add a false record. Report that you could not add it.

Add notes in review order. Save the id from each `review add`. If one add fails, prior
notes stay in the queue. Continue when safe and report the failed add. Never use
`review pull`, `review drop`, or `review clear` in this flow.

## Report

If you find no clear bugs, add nothing and say so.

If you find bugs, report one line for each add attempt:

```text
r3 src/api.py:40-58 — queued: rejects an expired token after state was committed
src/jobs.py:91 — not queued: the file changed before its range could be captured
```

The queue holds the handoff. Do not also apply the fixes.

Run `review add --help` for more comment and output options.
