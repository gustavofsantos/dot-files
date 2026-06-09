---
name: vault-scout
description: >
  Dispatches a cheap subagent to recall what the ~/engineering/ vault already knows
  about a topic and map the open unknowns. Use during investigation or planning to
  gather stored context for a scope without the main agent searching the vault.
  Triggers on "what does the vault know about", "scout the vault for", "find related
  notes on", "map what we know about", or before planning work touching a known domain.
metadata:
  effort: low
  argument-hint: "[topic]"
  arguments: [topic]
  allowed-tools: Read Bash(kb-search:*) Bash(kb-peek:*)
---

# Vault Scout — dispatch shim

Dispatches knowledge recall to the **`vault-scout` subagent** (`agents/vault-scout.md`, runs on a cheap model), keeping the vault search and note reads out of the main session. Complements `dead-reckoning`: that one investigates code behavior, this one recalls stored knowledge.

```
Agent(
  subagent_type: "vault-scout",
  description: "Scout vault: <topic>",
  prompt: "Topic/scope: <from $ARGUMENTS or the current investigation>.
           Context: <what the planning session is trying to figure out — verbatim>.
           Return the structured recall report."
)
```

## After the report arrives

1. Surface the report, then read any artifact in its `## Highest-signal artifacts to read in full` worth loading.
2. **Known** items become established ground for the plan — cite the notes/issues rather than re-deriving them.
3. **Unknown** items are the planning targets: feed open questions into the issue's `## Open questions` (via `vault`), and route a genuine code-behavior unknown to `dead-reckoning`.
4. Concepts the scout found named but unwritten are candidates for new `vault` notes once confirmed.
