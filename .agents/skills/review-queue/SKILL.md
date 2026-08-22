---
name: review-queue
description: >
  Pull the review comments waiting in the `review` queue and work them, then record what
  became of each one. The queue holds comments pinned to file ranges, raised in an editor
  or by another reviewing agent; pulling dequeues them, so they are handed over exactly
  once. Trigger on "pull my reviews", "check the review queue", "I left you comments",
  "address my review comments", "any reviews pending?", or whenever the user refers to
  notes left on code rather than pasting them. NOT for reviewing a PR on GitHub and NOT
  for producing a review of your own.
---

# review-queue

Comments are raised where the code is read — the user in nvim (`<CR>` on a visual
selection), or a reviewing agent running `review add`. You are the consumer: drain the
queue, do the work, and leave a decision behind on every comment.

## Loop

1. **Look before you pull** — `review count`. Zero means nothing is waiting; say so and stop.
2. **Pull** — `review pull` prints every pending comment as markdown (who raised it, file,
   line range, the code as it read when the note was written, the note itself) and dequeues
   them. One pull per batch: they are gone from the queue, so do not pull again until you
   have finished the batch, and never discard the output mid-task.
3. **Work them in order** — the numbering is the reviewer's reading order. Treat each as a
   request against that file range. The snapshot is the code at writing time — re-read the
   file before editing, it may have moved.
4. **Record the decision** — as you finish each one:
   `review resolve <id> --note "<what you did>"`, or
   `review reject <id> --note "<why not>"` when you are not making the change. A reason is
   required to reject: the queue exists so nothing is declined silently.
5. **Report by id** — one line per comment: `r3 src/api.py:40-58 — <what you did>`.

## Lanes

One working tree can carry several branches at once (GitButler), so a comment names the
lane it belongs to. If the session is pinned — `$REVIEW_LANE`, or `--lane NAME` — every
read and pull is scoped to that lane, and a pull reports on stderr when comments are
waiting in other lanes. Leave those alone: they belong to whoever is working that lane.
Never pass `--all-lanes` to widen a pull; only the user decides that.

## Rules

- `review pull --peek` reads the queue without draining it. Use it when the user asks what
  is pending but has not asked you to act.
- Never `review clear` or `review drop` — those delete the user's notes with no decision
  recorded. Dequeuing is what `pull` already does; accounting is what `resolve`/`reject` do.
- Set `$REVIEW_AUTHOR` for yourself if it is not already set, so the record says which
  agent raised or decided a comment.
- The workspace is resolved from your cwd (git root). Run the command from inside the repo
  the comments were written in, or pass `--workspace PATH`.
- `review pull --format json` when you want structured records instead of markdown;
  `review list --status open` for everything raised but not yet decided.

`review --help`, and `review <command> --help`, document the rest.
