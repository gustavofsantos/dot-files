---
name: tdd
description: >
  Implements issue scenarios test-first, one at a time, using the red-green-refactor
  cycle. Use when an issue has ## Scenarios and implementation is about to begin.
  Triggers on "implement", "vamos implementar", "start coding", "começar a implementar",
  "let's build this", or when moving from planning to execution on a tracked issue.
metadata:
  allowed-tools: Read Write Edit Bash(rg:*) Bash(fd:*) Bash(git:*)
---

# TDD

Read the active issue, then find the first task with unchecked scenarios and
implement them test-first, in order.

This skill drives `type: implementation` issues. An `investigation` issue is
answered with `dead-reckoning`, not tested into existence — skip it here.

**Locate the active issue** the same way the `issue` skill stores it:

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_CFG="${_ROOT}/.skills/config"
if [ -f "$_CFG" ]; then
  ISSUES_DIR=$(grep '^issues=' "$_CFG" | cut -d= -f2 | xargs)
  [[ -n "$ISSUES_DIR" && "$ISSUES_DIR" != /* ]] && ISSUES_DIR="${_ROOT}/${ISSUES_DIR}"
fi
ISSUES_DIR="${ISSUES_DIR:-$HOME/engineering/issues}"
```

Each `## Tasks` entry references the scenarios (`S1, S2 — label`) it covers; the
`## Scenarios` section holds the Given/When/Then those tasks implement. If the
issue's `## Context` carries a `design-constraints` block, treat it as binding, and
treat the facts in `## Facts` (`FACT-NNN`) as established ground.

## Cycle

For each scenario Sn:

**RED** — Write a failing test that directly expresses the Given/When/Then.
Given → setup. When → action. Then → assertion. No more than what the scenario says.

**GREEN** — Write the minimum code to pass. Hardcoding is valid if it makes the test
pass. Do not add untested behavior.

**REFACTOR** — Improve structure. Run tests after every change. If a test breaks, undo
and try smaller.

Run `verify-task`; record the returned hash on the task line — e.g. `[x] abc1234 verify:a3f9…`.
If `verify-task` exits FAIL, do not mark complete.

Move to the next task.

When every task is checked, hand the branch to `deep-review` before merge (and to
`deslop` / `readable` for language-specific cleanup). Archiving the issue is the
human's call, per the `issue` skill.

## Test friction is design signal

| Friction | Problem |
|---|---|
| Hard to instantiate the subject | Too many dependencies |
| Many mocks needed | High coupling |
| Setup longer than assertion | Wrong responsibility boundary |
| Can't assert without side effects | Logic mixed with I/O |

When friction appears, stop and redesign before continuing.

## Rules

- One failing test at a time.
- Never test private methods — they surface through public interface failures.
- No conditionals or loops in test code to reduce duplication.
