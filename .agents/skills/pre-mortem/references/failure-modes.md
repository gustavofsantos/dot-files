# Failure modes

Run every category against every write path in the blast radius. Each question names a
trigger; answer it from the code, not from the diff's intent.

## Partial failure and atomicity

- Does one logical operation write to more than one place (two tables outside one
  transaction, a database and a queue, a database and a cache, a database and an external
  API, a file and its index)? What remains if the process dies between the writes?
- Is an external call made inside a transaction? If the transaction rolls back, the call
  has still happened. If the call times out, did it succeed?
- Is a message published before the transaction commits (consumers see data that does not
  exist yet) or after (a crash loses the message)? Is there an outbox?
- Does a batch, loop, or backfill commit per item? If it stops at item N, can it resume
  without redoing 1..N or skipping the rest?
- Are files written in place rather than to a temporary path and renamed?
- Does cleanup on failure (rollback, compensation, `finally`) itself fail silently?

## Idempotency and repeated execution

- Can this run twice? Sources: queue redelivery (at-least-once), HTTP client and gateway
  retries, job re-runs after failure or timeout, user double submit, webhook retries,
  scheduler overlap, manual replay.
- On the second run, does it insert a duplicate, increment twice, send twice, charge twice,
  or append twice?
- Is there an idempotency key, a unique constraint, or an upsert that makes the repeat a
  no-op? Is the key stable across retries, or generated fresh each attempt?
- Is the message acknowledged before the work is done (lost on crash) or after a
  non-idempotent side effect (duplicated on crash)?

## Concurrency

- Check-then-act: read, decide, write, with no lock or constraint between them. Two
  instances can both pass the check.
- Read-modify-write on a counter, balance, list, or JSON blob: lost updates.
- Is uniqueness enforced only in code, not by the database?
- Can two consumers process messages for the same entity in parallel or out of order?
- Lock ordering across resources (deadlock), and lock or connection held across an external
  call.
- In-memory state (caches, singletons, module globals) assumed to be shared across
  instances, or assumed to be private to one request.

## Schema and data evolution

- Migrations: does the old version still running during a rolling deploy work against the
  new schema? Does the new version work before the migration has run?
- Column renamed or dropped while old code, other services, reports, or ETL still read it.
- New non-null column, new enum value, narrowed type, or new constraint on a table with
  existing rows that violate it.
- Backfill: locks a large table? Bounded? Resumable? Correct for rows written while it runs?
- Serialized data that outlives the deploy — queue payloads, cache entries, session data,
  stored JSON, scheduled jobs' arguments: can the new code read what the old code wrote, and
  the reverse?
- Cache key or cache shape changed without invalidation.

## Rollout and rollback

- If this is rolled back after running for an hour, is the data it wrote readable by the
  previous version? Is any migration irreversible?
- Feature flag toggled mid-flight: are processes that started under one value finished under
  the other, leaving mixed state?
- Ordering between this deploy and another service's deploy that the change depends on.

## Silent loss and swallowed errors

- `catch` that logs and continues past a failed write, leaving later steps to run on a false
  assumption.
- Fire-and-forget calls, unawaited promises, background threads whose failure nobody sees.
- Default values that hide a missing record (`?? 0`, `getOrDefault`, empty list) and then get
  persisted as if real.
- Error paths that return success to the caller, so the caller never retries.
- Dead-letter queues that receive messages and that nothing drains.

## Contracts with other consumers

- Public API, event schema, database columns, file formats, or config read by something
  outside the diff: removed field, changed meaning, changed unit, changed nullability,
  changed ordering, changed default.
- Changed semantics behind an unchanged signature: same name, different behavior for
  existing callers found in step 2.

## Time and ordering

- Events assumed to arrive in order; timestamps compared across machines.
- Time zones and DST in date keys, partitions, scheduled jobs, and "once per day" logic.
- Timeouts shorter than the work they bound, so the work continues after the caller has
  given up and retried.

## Destructive and irreversible operations

- Deletes, cascades, truncates, and bulk updates: is the `WHERE` correct for every caller
  found in step 2, including when a filter is empty or null?
- Soft delete assumed but hard delete performed, or the reverse.
- Side effects to the outside world (payments, emails, notifications, third-party writes)
  reachable from a path that can repeat or partially fail.

## Resource exhaustion on the write path

- Unbounded queries, loops, or payloads on a hot path; memory growth per request.
- Connection-pool or lock exhaustion that stalls writes mid-process.
- A job that, when it dies from exhaustion, leaves partial work behind (see the first
  category).
