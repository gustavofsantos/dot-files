---
name: review-queue
description: >
  Pull submitted reviews and standalone comments from the `review` queue. Work each
  comment and record its result. Use when the user asks to pull reviews, check the
  review queue, or address notes left on code. NOT for producing a new code review.
---

# review-queue

Reviewers add comments where they read code. A user can add one in nvim with `<CR>`
on a visual selection. An agent can run `review add`. A comment can stay standalone
or belong to a submitted review. A submitted review has a decision and summary.

You consume the queue. Do the work and record a resolution for every comment.

## Loop

1. **Look before you pull** — Run `review count`. If it prints zero, report that the
   queue is empty and stop.
2. **Pull once** — Run `review pull`. It prints and dequeues submitted reviews and
   standalone comments. Keep the output until you finish the batch.
3. **Read review context first** — Read a review's decision and summary before its
   comments. The comments identify the file work. A summary-only review can contain
   clear feedback without a file comment.
4. **Work comments in order** — Treat each comment as a request against its file
   range. Re-read the file before editing because the saved code can be old. Apply
   the same rule to standalone comments.
5. **Record each resolution** — When you finish a comment, run:
   `review resolve <id> --note "<what you did>"`, or
   `review reject <id> --note "<why not>"`. Always give a reason when you reject a
   comment.
6. **Report by id** — Name each review id and its decision. Then report one line for
   each comment: `r3 src/api.py:40-58 — <what you did>`. Report only the review-level
   result for a summary-only review.

## Lanes

A GitButler working tree can carry more than one branch. Each comment names its lane.
`$REVIEW_LANE` or `--lane NAME` pins the session to one lane. A pinned pull reports
work waiting in other lanes. Leave that work alone. Only the user can choose
`--all-lanes`.

## Rules

- `review pull --peek` reads the queue without draining it. Use it when the user asks what
  is pending but has not asked you to act.
- Never run `review clear` or `review drop`. Those commands delete notes without a
  recorded result. Use `pull`, then `resolve` or `reject`.
- Set `$REVIEW_AUTHOR` when the environment does not define it. The value identifies
  the agent that acts on a comment.
- Run the command inside the target repository. You can instead pass `--workspace PATH`.
- Use `review pull --format json` for structured records. The `submitted_reviews`
  field holds reviews with nested `comments`. The `reviews` field holds standalone
  comments.
- Use `review list --status open` to find comments that still need a resolution.

`review --help`, and `review <command> --help`, document the rest.
