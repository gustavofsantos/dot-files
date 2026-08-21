---
description: Pull the review comments queued from the editor and work them.
---

# review

Drain this workspace's review queue and act on every comment in it. The full rules are
in the `review-queue` skill; the essentials:

1. Run `review pull` from inside the repo you are working in — the queue is keyed by
   workspace, and a subdirectory still resolves to the git root.
2. Nothing pending → say so in one line and stop. Do not invent work.
3. Otherwise work the comments in the order printed; that is the user's reading order.
   Each snapshot shows the code as it read when the note was written, so re-read the
   file before editing it — the lines may have moved.
4. Report one line per comment, by id: `r3 src/api.py:40-58 — <what you did>`. A comment
   you disagree with gets an answer, never silence.

That single `pull` dequeued them and there is no second copy: do not pull again until
this batch is done, and never `review clear` or `review drop` — those throw the user's
notes away. Use `review pull --peek` when they only want to know what is waiting.
