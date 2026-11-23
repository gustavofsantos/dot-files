---
name: pre-mortem
description: Assume the change already broke production and find how. Reports only critical failures — corrupted, incomplete, duplicated, or lost state, non-idempotent processes, and partial failures that leave leftover data.
disable-model-invocation: true
---

# Pre-mortem

Assume the change shipped and caused an incident. Your job is to find the incident before
it happens. Do not change the code under review.

## The bar

Report a finding only if it can leave production in a state that stays wrong after the bug is
fixed, or takes production down. That is:

- **Corrupted state** — persisted data that is wrong, inconsistent across stores, written
  under the wrong tenant or owner, or violates an invariant.
- **Incomplete state** — a multi-step process that can fail midway and leave part of its work
  behind (rows without their children, a record without its event, a file without its index).
- **Duplicated or lost effects** — a step that is not idempotent under retry, redelivery,
  re-run, or double submit; or work that is acknowledged and then dropped.
- **Irreversible side effects** — money moved, emails sent, external calls made, data deleted,
  in a way a redeploy or rollback cannot undo.
- **Production-wide outage** — a crash, deadlock, or exhaustion on a hot path.

A broken contract (another service, job, or consumer, or the previous version during a
rolling deploy, disagreeing with what the change reads or writes) qualifies only when it
leads to one of the outcomes above. A consumer that fails loudly and is retried is an error.
A consumer whose failures land in a dead-letter queue nobody drains is lost data.

Everything else is out of scope: style, naming, test coverage, performance that does not
cause an outage, an error the user sees but that leaves state intact. Security has its own
review. Do not pad the report. "No critical findings" is a valid, useful result.

## 1. Pin the change

Do not stop to ask what to review. Use, in order: the diff, commit range, or paths the user
named; otherwise the current branch against its merge-base with the default branch,
including uncommitted changes. State the chosen scope at the top of the report.

Read the intent: the pull request description, the linked ticket or issue, and the commit
messages. A changed behavior is a finding candidate only when you can tell it apart from
the intended one.

Read the whole diff, then list every changed symbol: functions, methods, types, fields,
columns, queries, migrations, config keys and environment variables, event and queue names,
endpoints, feature flags, schedules, and infrastructure settings (retry, timeout,
dead-letter, concurrency).

Read the surrounding context: the project brief and `workflows/` in
`${ENGINEERING_HOME:-$HOME/engineering}` when they exist, and the repository's own docs.
They tell you which flows the change sits inside.

## 2. Map the blast radius

The diff is not the change. The change is everything that reaches, or is reached by, the
changed symbols.

**Find the language server first.** Check your tools for a language-server tool, including
tools that are listed by name only and must be loaded before use. Record in the coverage
section whether you found one and used it. A run without it covers much less code.

**Use the language server when one is available.** It sees what text search misses:
overloads, interface dispatch, inherited methods, renamed imports, generated code. For each
changed symbol:

- **Find references** — every caller and reader, including tests that encode assumptions.
- **Call hierarchy** — incoming calls up to the entry points (HTTP handlers, consumers, jobs,
  CLI commands, schedulers); outgoing calls down to the writes and external calls.
- **Go to implementation** — every implementer of a changed interface or abstract method.
- **Type hierarchy / type definition** — subclasses and overrides that inherit changed
  behavior.
- **Diagnostics** — type errors the change introduced in files the diff does not touch.

**Then search text anyway.** Some links are invisible to a language server: reflection,
dependency-injection by name, string-dispatched handlers, ORM field names, raw SQL, column
names in other services, serialized payloads, config and env keys, event and topic names,
templates, cron definitions, deployment manifests. Search each changed name in every
spelling it can take (`snake_case`, `camelCase`, `kebab-case`, quoted, as a column).

When no language server is available, widen the text search to compensate.

Use subagents to fan out across entry points or services when the radius is large. Give each
one a single entry point or symbol to trace, and ask for the write path it found, not a
verdict.

## 3. Trace write paths, most dangerous first

You will not always reach every path. Trace in this order, and stop only when the budget
runs out, never silently:

1. Paths that reach irreversible external effects: payments, emails, notifications,
   third-party writes, deletes.
2. Paths that write persisted state: databases, queues, caches, files, object storage.
3. Paths that only read, when a changed contract can make them misinterpret data and act
   on it.

For each path, walk it step by step and ask, at every step: *what if the process dies right
here? what if this runs twice? what if another instance runs this at the same moment? what
if the previous version reads what this wrote? is this still scoped to the right tenant?*

Load `references/failure-modes.md` and run its questions against each path. A category
counts as checked only when you can name the code path you checked it against. Do not
answer a category from the diff alone.

## 4. Try to refute each candidate

A candidate is not a finding until it survives an attempt to kill it.

- Write the failure as a concrete scenario: the state before, the exact sequence of events
  (including the crash, retry, or interleaving), and the state after.
- Look for the guard that would prevent it: a transaction boundary, a unique constraint, an
  idempotency key, a lock, an outbox, a retry policy with deduplication, a reconciliation
  job, a framework guarantee. Read the guard's code or configuration; do not assume it.
- Check the runtime facts the scenario depends on: is the consumer at-least-once? Does the
  client retry? Is the job re-run on failure? Does the deploy roll out gradually? Which
  config value does production actually have?

**Reproduce only in isolation.** A reproduction may run only against in-memory fakes,
containers you start for it, or a local database you create and destroy. Never use
credentials, URLs, or connections to shared, staging, sandbox, or production systems,
including a shared dev database or a real queue. If the failure cannot be reproduced in
isolation, describe the scenario and do not run it. Delete every throwaway file you wrote.

Drop candidates you refuted, but keep a one-line note of each for the report.

## 5. Report

Load `references/report.md` and write the reply in exactly that format. Separate runs, by
different models, are merged by comparing their reports, so do not change the headings,
field names, or value vocabularies.
