---
name: tdd
description: >
  Implements issue scenarios test-first, one at a time, using the red-green-refactor
  cycle. Use when an issue has ## Scenarios and implementation is about to begin.
  Triggers on "implement", "vamos implementar", "start coding", "começar a implementar",
  "let's build this", or when moving from planning to execution on a tracked issue.
metadata:
  allowed-tools: Read Write Edit Bash(rg:*) Bash(fd:*) Bash(git:*)
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "verify-task --branch || exit 2"
---

# TDD

Drives `type: implementation` issues only — an `investigation` issue is answered by Finn, not tested into existence.

Locate the active issue (same resolution the `issue` skill uses):

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_CFG="${_ROOT}/.skills/config"
if [ -f "$_CFG" ]; then
  ISSUES_DIR=$(grep '^issues=' "$_CFG" | cut -d= -f2 | xargs)
  [[ -n "$ISSUES_DIR" && "$ISSUES_DIR" != /* ]] && ISSUES_DIR="${_ROOT}/${ISSUES_DIR}"
fi
ISSUES_DIR="${ISSUES_DIR:-$HOME/engineering/issues}"
```

Each `## Tasks` entry names the scenarios (`S1, S2 — label`) it covers; `## Scenarios` holds their Given/When/Then. A `design-constraints` block in `## Context` is binding; `## Facts` (`FACT-NNN`) are established ground.

## Cycle (per scenario, in order)

- **RED** — one failing test expressing the Given/When/Then exactly. No more than the scenario says.
- **GREEN** — minimum code to pass; hardcoding is valid. No untested behavior.
- **REFACTOR** — improve structure, tests green after every change; if one breaks, undo and go smaller.

Mark the task `[x]` when its scenarios are green (the Stop hook runs `verify-task --branch` and blocks if anything is red), then move on.

When all tasks are checked, hand the branch to Victor before merge, plus `deslop`/`readable` for language cleanup. Archiving the issue is the human's call.

## Discipline

When test friction appears (hard to instantiate, many mocks, setup > assertion), stop and redesign per `.claude/rules/tests.md`.
