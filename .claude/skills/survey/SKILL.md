---
name: survey
description: >
  Surveys an unfamiliar repository by dispatching a read-only subagent that discovers
  identity, configuration, and integration zones, returning a structured report with
  findings, fact candidates, and high-signal files.
metadata:
  effort: high
  argument-hint: "[focus]"
  arguments: [focus]
  allowed-tools: Read Bash(rg:*) Bash(fd:*)
---

# Survey — dispatch shim

Dispatches discovery to the **`survey` subagent** (`agents/survey.md`), which reads the repo across three zones (Identity, Config, Integration) and correlates with the KB. Two subagents can run concurrently on orthogonal focuses (e.g. config/infra vs. integration/entrypoints).

```
Agent(
  subagent_type: "survey",
  description: "Survey: <project name or focus>",
  prompt: "Repo root: <cwd or git root>.
           Focus: <$ARGUMENTS or 'general'>.
           Return the structured survey report."
)
```

## After the report arrives

1. Surface the report, then read every file in its `## High-signal files`.
2. **Fact candidates** — ask "promote these N findings as facts?"; record approved ones via the `vault` skill so later runs can load them.
3. **Contradictions** — surface `## Contradictions with knowledge base` explicitly; resolve before trusting the facts.
4. **Next step** — suggest the top `## Entry points for dead-reckoning` as the next `dead-reckoning` dispatch.
