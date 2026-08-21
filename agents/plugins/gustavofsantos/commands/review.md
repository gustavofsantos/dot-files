---
description: Pull the review comments queued from the editor and work them.
---

# review

Drain this workspace's review queue and act on every comment in it. The full rules are
in the `review-queue` skill; the essentials:

1. Run `review pull` from inside the repo you are working in — the queue is keyed by
   workspace, and a subdirectory still resolves to the git root. If this session is
   pinned to a lane (`$REVIEW_LANE`, or `--lane NAME`), the pull is scoped to it, and
   anything waiting in another lane is reported on stderr but left alone. Never widen
   the scope to take another lane's comments.
2. Nothing pending → say so in one line and stop. Do not invent work.
3. Otherwise work the comments in the order printed; that is the reviewer's reading
   order. Each header names who raised it. The snapshot shows the code as it read when
   the note was written, so re-read the file before editing it — the lines may have moved.
4. Record the outcome of every comment as you finish it, one call each:
   `review resolve <id> --note "<what you did>"`, or `review reject <id> --note "<why
   not>"` when you are not making the change. Then report the same list back in chat,
   one line per id.

That single `pull` dequeued them and there is no second copy: do not pull again until
this batch is done, and never `review clear` or `review drop` — those throw the notes
away without a decision. Use `review pull --peek` when the user only wants to know what
is waiting.
