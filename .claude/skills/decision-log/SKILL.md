---
name: decision-log
description: Record consequential decisions made during a session as checkable verification targets for the human. Activates whenever you make a non-obvious choice — picking one approach over another, making an assumption to proceed, widening a boundary, skipping a step, or resolving an ambiguity. Not for mechanical edits.
---

# Decision log

You are a tool that emits diffs. The human is the sole agent who approves them,
and they can only approve what they can articulate. Your job at session end is to
hand them the short list of things they must confirm — not a humility disclaimer.

## The doc

Path: `.claude/decisions/<session_id>.md` (use the current session id).

Append one line per consequential decision, as you make it:

```
N. <what you decided> — <what the human must verify>
```

- Em dash (`—`) separates the decision from the verification target.
- Left side: the choice you made. Right side: the specific thing that would
  falsify it — an assumption to check, a consumer to inspect, a value to confirm.
- Both sides concrete. A Stop hook rejects the session if any line is malformed
  or the list is empty.

## What counts as a decision

Log it when you:
- chose one approach over a viable alternative (locking strategy, data structure, sync vs async)
- made an assumption to keep moving (a column exists, a caller handles null, an invariant holds)
- widened or changed a shared/boundary type
- skipped something (a migration, a test, a validation) on purpose
- resolved an ambiguity in the request by picking an interpretation

Do NOT log: renames, formatting, obvious mechanical edits, anything with no alternative.

## Format discipline

Bad (vague, invites deference):
```
1. Refactored the transfer code — please review
```

Good (concrete, checkable, reinforces the human's ownership):
```
1. Chose optimistic locking over pessimistic in TransferService — verify write contention is actually low under peak load
2. Assumed accounts.legacy_id is backfilled for all rows — confirm before the NOT NULL migration ships
3. Widened boundary type Account with `closedAt` — check the three downstream consumers in the billing context still compile against it
```

Write "please verify" nowhere. Name the target instead.
