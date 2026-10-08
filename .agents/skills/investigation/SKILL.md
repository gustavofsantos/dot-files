---
name: investigation
description: >-
  Record a multi-step investigation or analysis as numbered, replayable steps, whatever
  the data source (datalake queries, logs, APIs, files). Use when answering a question
  needs more than one query or command, when you receive an investigation card, when the
  user says "investigate", "analyze", "find out why", or asks to trace or rewind an
  earlier investigation.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "inv-guard"
---

# Investigation log

`inv` wraps any command and records each run as a step: the command, snapshots of its
input files, its full output, row count, output hash and check status. The script
writes the log, you never do. Failed runs are recorded too.

## Every command of the investigation goes through `inv run`

```bash
inv run <slug> --why "<what this step should tell us>" \
  [--attach q.sql] [--expect-unique <cols>] [--expect-rows ">0"] \
  -- <command that prints a table with a header line>
```

- `<slug>` is `investigation` or `investigation/front`. If you received a card, use its
  slug for every step.
- `--attach` every input file the command reads (a `.sql`, a filter list). Files get
  overwritten between steps; the snapshot is the only record of what actually ran.
- `--expect-unique` declares the grain of the result. Use it whenever you join.
- `--parent N` branches from step N when the path since N was wrong.
- Write `{as_of}` where the SQL needs "now"; `inv` fills it with the pinned time.

The same query over many keys or dates is one `inv map`, not many `inv run`:

```bash
inv map <slug> --why "<what the rows tell us>" --template q.sql.tmpl --params keys.tsv \
  [--expect-unique <cols>] -- <command reading {sql}>
```

`keys.tsv` has a header; each `{column}` in the template is filled per row. The map
prints one merged table, every row tagged with its params. Rerunning it reruns only
the rows that did not finish ok.

| Exit | Meaning | What to do |
|------|---------|------------|
| 0 | Ran, checks passed | Continue. `check=empty` means zero rows: confirm that is expected. |
| 3 | A check failed, a map row failed, or the SQL uses now()/current_date | The output is wrong or incomplete. Do not use it for any conclusion. Fix and rerun. |
| 4 | Step budget spent or time is up | Stop running commands. Return what you have now. |
| 124 | The step timed out | Narrow the query or split it with `inv map`. |
| other | The command failed | Fix it and rerun. |

When you report a finding, cite its step ("step 7: 412 rows"), never a retelling.

Once a session has run `inv run`, `inv-guard` blocks data commands that run outside it
in that session. When blocked, rerun the same command wrapped as the message says.

## Reading the log

```bash
inv log <slug>             # every step: parent, exit, rows, check, why
inv trace <slug> <step>    # facts-only handoff: the ancestors of <step>
inv board <investigation>  # one line per front
```

`trace` is the rewind: its output, pasted into a fresh session, resumes from that step
without the previous conversation.

Steps live in `~/.investigations/<slug>`. They can hold production data: never commit
them.
