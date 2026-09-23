---
name: review-queue
description: >
  Pull submitted reviews and standalone comments from the `review` queue, work each comment,
  and record its result. Not for producing a new code review.
disable-model-invocation: true
---

# review-queue

Comments come from nvim (`<CR>` on a visual selection) or from agents (`review add`). They can
stand alone or belong to a submitted review, which carries a decision and a summary.

1. Run `review count`. If it prints zero, report that the queue is empty and stop.
2. Run `review pull` once. It dequeues the items, so keep the output. Use `--format json` for
   structure: `submitted_reviews[].comments` holds review comments, and `reviews` holds
   standalone ones.
3. Read each review's decision and summary before its comments. A summary alone can carry
   feedback.
4. Work the comments in order. Re-read the file first, because the saved snippet may be stale.
5. For each comment, run `review resolve <id> --note "<what you did>"` or
   `review reject <id> --note "<why not>"`.
6. Report each review id with its decision. Then write one line per comment:
   `r3 src/api.py:40-58 — <what you did>`.

## Rules

- Use `review pull --peek` when the user only asks what's pending.
- Never run `review clear` or `review drop`. They delete comments without recording a
  decision.
- A lane-pinned session (`$REVIEW_LANE`, `--lane`) leaves other lanes alone. Only the user
  chooses `--all-lanes`.
- Set `$REVIEW_AUTHOR` if it is unset. Run inside the repo, or pass `--workspace PATH`.
- `review list --status open` shows the comments that still need a decision.
