---
name: pre-mortem
description: Assume the change already broke production and find how. Reports only critical failures — corrupted, incomplete, duplicated, or lost state, non-idempotent processes, and partial failures that leave leftover data.
disable-model-invocation: true
---

# Pre-mortem

Assume the change shipped and caused an incident. Your job is to find the incident before
it happens. Read the code; do not change it.

## The bar

Report a finding only if it can leave production in a state that stays wrong after the bug is
fixed, or takes production down. That is:

- **Corrupted state** — persisted data that is wrong, inconsistent across stores, or violates
  an invariant.
- **Incomplete state** — a multi-step process that can fail midway and leave part of its work
  behind (rows without their children, a record without its event, a file without its index).
- **Duplicated or lost effects** — a step that is not idempotent under retry, redelivery,
  re-run, or double submit; or work that is acknowledged and then dropped.
- **Irreversible side effects** — money moved, emails sent, external calls made, data deleted,
  in a way a redeploy or rollback cannot undo.
- **Broken contracts** — another service, job, consumer, or the previous version during a
  rolling deploy reads or writes data the change no longer agrees with.
- **Production-wide outage** — a crash, deadlock, or exhaustion on a hot path.

Everything else is out of scope: style, naming, test coverage, performance that does not
cause an outage, an error the user sees but that leaves state intact. Security has its own
review. Do not pad the report. "No critical findings" is a valid, useful result.

## 1. Pin the change

Identify exactly what is under review: the diff against the base branch, a commit range, or
the paths the user named. If it is ambiguous, ask. Read the whole diff, then list every
changed symbol: functions, methods, types, fields, columns, queries, migrations, config keys,
event and queue names, endpoints, feature flags.

Read the surrounding context: the project brief and `workflows/` in
`${ENGINEERING_HOME:-$HOME/engineering}` when they exist, and the repository's own docs.
They tell you which flows the change sits inside.

## 2. Map the blast radius

The diff is not the change. The change is everything that reaches, or is reached by, the
changed symbols. Map it before judging anything.

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
templates, cron definitions. Search each changed name in every spelling it can take
(`snake_case`, `camelCase`, `kebab-case`, quoted, as a column).

When no language server is available, say so in the report and widen the text search to
compensate.

Use subagents to fan out across entry points or services when the radius is large. Give each
one a single entry point or symbol to trace, and ask for the write path it found, not a
verdict.

## 3. Trace every write path through the failure lens

For each entry point that reaches a write, an external call, or a message publish, walk the
path step by step and ask, at every step: *what if the process dies right here? what if this
runs twice? what if another instance runs this at the same moment? what if the previous
version reads what this wrote?*

Load `references/failure-modes.md` and run its questions against each path. It is the
checklist; do not skip a category because the diff looks unrelated to it. The worst
incidents come from the category nobody checked.

## 4. Try to refute each candidate

A candidate is not a finding until it survives an attempt to kill it.

- Write the failure as a concrete scenario: the state before, the exact sequence of events
  (including the crash, retry, or interleaving), and the state after.
- Look for the guard that would prevent it: a transaction boundary, a unique constraint, an
  idempotency key, a lock, an outbox, a retry policy with deduplication, a reconciliation
  job, a framework guarantee. Read the guard's code or configuration; do not assume it.
- Check the runtime facts the scenario depends on: is the consumer at-least-once? Does the
  client retry? Is the job re-run on failure? Does the deploy roll out gradually?
- When a cheap reproduction exists (a throwaway test that injects the failure or runs the
  step twice), run it. Remove it afterwards.

Drop candidates you refuted. Keep the ones you could not refute, and say which you
reproduced and which you only reasoned about.

## 5. Report

Order findings by severity, most damaging first. For each one:

```
### <one-line title: what goes wrong in production>

- **Category:** <failure-mode category>
- **Where:** <file:line of the step that fails or is missing>
- **Trigger:** <the real-world event that sets it off: crash, retry, redelivery, concurrent request, rolling deploy, rollback, …>
- **Scenario:** <state before → sequence of events → state after>
- **Damage:** <what is corrupted, incomplete, duplicated, or lost; who notices, and when>
- **Guards checked:** <what you looked for that would prevent it, and why it does not>
- **Evidence:** reproduced | traced in code | inferred
- **Fix direction:** <one or two sentences; not a patch>
```

End with a coverage section, so separate runs can be compared and merged:

- How the blast radius was mapped (language server, text search, or both) and which
  symbols could not be resolved.
- Entry points traced, and entry points known but not traced.
- Failure-mode categories checked with nothing found.
- Assumptions about runtime behavior you could not verify (delivery semantics, retry
  policy, deploy strategy).
