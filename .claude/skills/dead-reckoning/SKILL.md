---
name: dead-reckoning
description: >
  Dispatches a subagent to trace existing code behavior and return a structured
  report with behavioral claims and high-signal files. Use for code investigation
  before making a decision; not for greenfield design.
metadata:
  effort: high
  argument-hint: "[question] [entry-point]"
  arguments: [question, entry_point]
  allowed-tools: Read Bash(rg:*) Bash(fd:*)
---

# Dead Reckoning — dispatch shim

Dispatches investigation to **Finn** (`agents/finn.md`), keeping the file reads and rg searches out of the main session.

```
Agent(
  subagent_type: "finn",
  description: "Investigate: <central question>",
  prompt: "Central question: <from $ARGUMENTS or inferred>.
           Entry points: <files, functions, or symbols if provided>.
           Context: <relevant facts / issue objective / prior knowledge — verbatim>.
           Return the structured report."
)
```

## After the report arrives

1. Surface the report to the human, then read every file in its `## High-signal files`.
2. **Fact candidates** — surface each for approval; record approved ones via the `vault` skill (in `~/engineering/facts/`), linked to the active issue. Never promote unconfirmed claims.
3. **Ignored scope** — re-dispatch with a narrower entry point if the human wants those branches.
4. **Next step** — this is the engine for `type: investigation` issues. Durable findings become facts (step 2); revealed work hands off to `vault` (shape an issue) or `design`/`design-constraints` for design questions.
