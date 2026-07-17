---
name: spike
description: >
  Resolve one unknown with the cheapest throwaway experiment, then leave a durable
  finding in ~/engineering/spikes/. The experiment is disposable; the finding is the artifact.
  Trigger on "spike <unknown>", "/spike", "capture this finding", or when another skill
  hands off an unresolved question. NOT for casual mentions of "research"/"investigation".
---
# spike

A spike answers **one** unknown with throwaway work and keeps only the answer.
You are the investigator, not the scribe: run the experiment, then leave the receipt.

## Loop
1. **Sharpen the unknown** — one question, phrased so it can be answered *wrong*. Fuzzy → sharpen before touching code.
2. **Cheapest experiment** — read source, run a probe, write disposable code. Ignore quality, edges, error handling. This code does not survive.
3. **Leave the receipt** — `scripts/new.sh "<slug>" [issue-id]` returns the path with stamped frontmatter. Fill Question / Answer / Evidence. Link the throwaway commit; don't paste it.
4. **Discard the scaffold** — the answer lives in the file; the experiment doesn't.

## Dedup
`rg -il '<term>' ~/engineering/spikes/` first. Same unknown → update, don't fork.

## The artifact
```markdown
---
status: resolved   # resolved | inconclusive | deferred
created: <stamped>
---
## Question
The one unknown. Answerable, falsifiable.

## Answer
One sentence — what you now know that you didn't.

## Evidence
What convinced you. Link files, commits, probe output. Prose, not a log.

## Context
Why it mattered. 2–3 sentences. Last, because it ages fastest.
```
