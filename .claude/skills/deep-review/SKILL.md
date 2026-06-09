---
name: deep-review
description: >
  Two-phase code review: Phase 1 scope and safety (test confidence, scope discipline, risk
  signal), Phase 2 architectural depth on the core changed logic. Works on a branch diff,
  a single file, or a usage pattern.
metadata:
  effort: high
  argument-hint: "[target]"
  allowed-tools: Read Bash(rg:*) Bash(fd:*) Bash(git:*) Bash(cat:*)
---

# Deep Review — dispatch shim

Identify the target from `$ARGUMENTS` or conversation: branch range, file path, or pattern. Ask one short question only if genuinely ambiguous.

Dispatch:
```
Agent(
  subagent_type: "victor",
  description: "Deep review of <target>",
  prompt: "Run the two-phase deep review on: **<target>**.
           References in the `deep-review` skill's `references/` dir — locate with
           `fd simple-design-rules.md ~/.claude`.
           [Pass any user focus verbatim.]
           Return only the structured report."
)
```

Surface the report verbatim. Act on the chain pointer:
- **Green / Yellow** → ready to ship; human archives the issue
- **Red, fixable in scope** → `design-constraints` in `refactor` mode → `tdd`
- **Red, structural** → propose a fresh issue via `vault`
