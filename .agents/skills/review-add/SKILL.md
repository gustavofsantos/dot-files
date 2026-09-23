---
name: review-add
description: >
  Review code changes, add each clear finding to the `review` queue, and submit a review for
  another agent. Not for working queued notes or editing code.
disable-model-invocation: true
---

# review-add

Review. Don't fix. Scope is the user's request, or else all current changes (staged,
unstaged, and relevant untracked). Queue only clear, actionable bugs, risks, or missing
tests. The full assessment goes in the review summary.

## Enqueue each finding

```sh
review add --file <path> --lines <N|N-M> --comment "<bug, trigger, harm, optional fix hint>"
```

- Re-read the smallest useful current range just before adding. `review add` snapshots it.
  If no current range exists, don't add it. Report it instead.
- Run from the repo under review, or pass `--workspace <path>` and an absolute `--file`.
- Keep `$REVIEW_LANE`. Pass `--lane` only if the user names one. Set `$REVIEW_AUTHOR` to a
  stable name if it is unset.
- Record each returned id. If an add fails, continue when that is safe and report the failure.
- Never run `review pull`, `drop`, or `clear` here.

## Submit one review

```sh
review submit --id r3 --id r4 --decision request-changes --summary "<assessment>"
```

- Use `request-changes` when any finding was queued. With no findings, run
  `--decision comment --no-comments` and state any limit on the review.
- Use `approve` only when the user explicitly grants approval authority and nothing is
  actionable.
- Pass every queued id explicitly, with the same workspace, lane, and author.
- If the submit fails, the comments stand alone. Don't re-add them. Say that the submit
  failed.

## Report

```text
rv1 request-changes — submitted with r3, r4
r3 src/api.py:40-58 — queued: rejects an expired token after state was committed
src/jobs.py:91 — not queued: the file changed before its range could be captured
```

See `review add --help` and `review submit --help`.
