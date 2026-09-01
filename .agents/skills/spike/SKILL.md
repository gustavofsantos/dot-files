---
name: spike
description: >
  Resolve one genuine unknown that needs time-boxed independent exploration, then leave a
  durable finding in ~/engineering/spikes/. The experiment is disposable.
  Trigger on "spike <unknown>", "/spike", "capture this finding", or when another skill
  hands off an unresolved question. NOT for casual mentions of "research"/"investigation".
---
# spike

A spike answers **one** unknown with throwaway work and keeps only the answer.
You are the investigator, not the scribe: run the experiment, then leave the receipt.

If one runtime claim can be settled inside the caller's task, use `hypothesize` and return
the verdict there. Use a spike when the exploration or answer needs its own durable life.

## Loop
1. **Sharpen the unknown** — one question, phrased so it can be answered *wrong*. Fuzzy → sharpen before touching code.
2. **Cheapest experiment** — read source, run a probe, write disposable code. Ignore quality, edges, error handling. This code does not survive.
3. **Leave the receipt** — `scripts/new.sh "<slug>"` returns the path with stamped frontmatter. Fill Question / Answer / Evidence. Link the throwaway commit. Do not paste it. The issue links the spike, never the reverse.
4. **Discard the scaffold** — the answer lives in the file. The experiment does not.

## Dedup
`rg -il '<term>' "${ENGINEERING_HOME:-$HOME/engineering}/spikes/"` first. Same unknown → update, do not fork.

## Boundary
`spikes/` holds the answer. Raw material that convinced you — query output, dumps,
transcripts — belongs in the vault's `artifacts/`, linked from `## Evidence`.

A reproduction shows that a mechanism can produce the tested result. It does not prove that
the mechanism caused a past incident without historical evidence that connects them.

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
