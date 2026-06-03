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

Dispatches the investigation to the **`dead-reckoning` subagent**
(see `agents/dead-reckoning.md`). The subagent traverses the codebase,
correlates with the knowledge base, and returns a structured report with
behavioral claims and high-signal files. Running it in a subagent keeps
the file reads and rg searches out of the main session context.

## Dispatch

Build the prompt from `$ARGUMENTS` and any context the human gave:

```
Agent(
  subagent_type: "dead-reckoning",
  description: "Investigate: <central question>",
  prompt: "Central question: <question from $ARGUMENTS or inferred from context>.
           Entry points: <specific files, functions, or symbols if provided>.
           Context: <any relevant facts, issue objective, or prior knowledge from
           this session — pass through verbatim>.
           Return the structured report."
)
```

## After the report arrives

1. **Surface the report** to the human.

2. **Read high-signal files.** The report's `## High-signal files` section lists
   files worth loading in full. Read each one:
   ```
   Read(path)  — for each file in the list
   ```

3. **Fact candidates.** If the report has a `## Fact candidates` section, surface
   each candidate to the human. For any the human approves, invoke the `fact` skill
   to record it (sourced, in `~/engineering/facts/`) and link it to the active issue.
   Never promote unconfirmed claims.

4. **Scope pointer.** If the report's `## Ignored scope` contains branches the
   human wants to investigate next, this skill can be dispatched again with a
   narrower entry point.

5. **Next step.** This skill is the engine for `type: investigation` issues — its
   answers close the issue's scenario-questions, and its durable findings become
   facts (step 3). If the investigation reveals work to do, hand off to the `issue`
   skill to shape an implementation issue, or to `design`/`design-constraints` if
   the finding is primarily a design question.
