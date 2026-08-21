---
name: review-queue
description: >
  Pull the review comments the user wrote in their editor and work them. The `review`
  CLI holds a per-workspace queue of comments pinned to file ranges; pulling dequeues
  them, so they are handed over exactly once. Trigger on "pull my reviews", "check the
  review queue", "I left you comments", "address my review comments", "any reviews
  pending?", or whenever the user refers to notes they left on code rather than pasting
  them. NOT for reviewing a PR on GitHub and NOT for producing a review of your own.
---

# review-queue

The user annotates code in nvim (`<CR>` on a visual selection) and each note lands in a
queue keyed by the workspace. You are the consumer: drain it, do the work, report back.

## Loop

1. **Look before you pull** — `review count`. Zero means nothing is waiting; say so and stop.
2. **Pull** — `review pull` prints every pending comment as markdown (file, line range,
   the code as it read when the note was written, the note itself) and dequeues them.
   One pull per batch: pulled comments are gone from the queue, so do not pull again
   until you have finished the batch, and never discard the output mid-task.
3. **Work them in order** — they are numbered; the order is the user's reading order.
   Treat each as a request against that file range. The snapshot shows the code at
   writing time — re-read the file before editing, it may have moved.
4. **Report by id** — one line per comment: `r3 src/api.py:40-58 — <what you did>`.
   A comment you disagree with is answered, not silently skipped.

## Rules

- `review pull --peek` reads the queue without draining it. Use it when the user asks
  what is pending but has not asked you to act.
- Never `review clear` or `review drop` — those throw the user's notes away. Dequeuing
  is what `pull` already does.
- The workspace is resolved from your cwd (git root). Run the command from inside the
  repo the comments were written in, or pass `--workspace PATH`.
- `review pull --format json` when you want structured records instead of markdown.

`review --help`, and `review <command> --help`, document the rest.
