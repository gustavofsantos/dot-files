---
name: spike
description: >
  Resolve one genuine unknown with time-boxed throwaway exploration and leave a durable finding
  in ~/engineering/spikes/. Use on "spike <unknown>", "/spike", "capture this finding", or a
  handoff from another skill. Not for casual mentions of "research" or "investigation".
---
# spike

A spike answers **one** unknown with throwaway work. It keeps only the answer. If one runtime
claim can be settled inside the current task, use the single-claim check in
`rules-of-investigation` instead.

1. **Dedup.** Run `rg -il '<term>' "${ENGINEERING_HOME:-$HOME/engineering}/spikes/"`. If the
   unknown already has a spike, update it.
2. **Sharpen.** Write one question that could be answered wrong.
3. **Experiment.** Use the cheapest probe. Quality doesn't matter, and the code won't survive.
4. **Receipt.** Run `scripts/new.sh "<slug>"`. It returns a path with stamped frontmatter.
   Fill in the sections below. Link the throwaway commit instead of pasting it. Put raw
   material (dumps, query output) in `artifacts/` and link it from Evidence. The issue links
   the spike, never the reverse.
5. **Discard** the scaffold.

```markdown
---
status: resolved   # resolved | inconclusive | deferred
created: <stamped>
---
## Question
## Answer
One sentence.
## Evidence
## Context
2–3 sentences on why it mattered.
```
