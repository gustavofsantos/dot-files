---
name: checks
description: Read and act on repository checks that run automatically after each agent turn. Use when verifying your changes didn't break anything, when the user asks "did checks pass", before declaring work done, or when you see a .checks.yml in the repo. Explains where results live and how to interpret them.
disable-model-invocation: true
---

# Checks

Every repo with a `.checks.yml` runs a set of **named checks** automatically
after each of your turns. You don't trigger them — the `Stop` hook hashes your
tracked changes and runs the checks asynchronously. Your job is to **read the
result and fix what failed** before telling the user you're done.

## The loop

```
your turn ends ─▶ Stop hook hashes changed tracked files
              ─▶ checks-runner runs each check ─▶ results.json
   next turn ─▶ you read results.json, fix failures, repeat
```

Because checks run async, results for the turn that *just* ended may still be
`pending` for a second or two. The result you read at the start of a turn
reflects the changes from your **previous** turn.

## Reading results

Prefer the helper — it resolves the current session automatically:

```bash
checks-status            # human summary (✓/✗ per named check), exit 1 if any fail
checks-status --json     # raw results.json for parsing
checks-status --oneline  # e.g. "✗ 2/3"
```

Raw storage, if you need it directly:

```
~/.checks/<session>/latest            → the current hash
~/.checks/<session>/<hash>/results.json
~/.checks/<session>/<hash>/snapshot.json   (repo, branch, files, pane)
```

`<session>` is `$CLAUDE_SESSION_ID`.

## Interpreting `results.json`

```json
{
  "summary": { "total": 3, "passed": 2, "failed": 1, "status": "fail" },
  "checks": [
    { "name": "unit", "command": "npm test", "status": "fail",
      "exit_code": 1, "duration_ms": 1840, "output_tail": "...last 20 lines..." }
  ]
}
```

- `summary.status`: `pass` | `fail` | `running` | `empty` | `pending`.
- A check `status` is `pass` (exit 0) or `fail` (non-zero). `output_tail` holds
  the last 20 lines of output — read it to find *why* it failed, then run the
  failing `command` yourself to reproduce and fix.
- `empty` means the repo has no checks configured; `pending`/`running` means
  the runner hasn't finished — re-read in a moment.

## What to do

1. When changes are non-trivial or the user asks, run `checks-status`.
2. If anything failed, open the failing check's `command` from `.checks.yml`,
   reproduce it, fix the root cause, and let the next turn's run confirm green.
3. Don't claim the work is done while checks are red — say what failed.

## Configuring checks (`~/.checks.yml`)

One global registry, `~/.checks.yml`, enrolls the repositories that run checks
and defines them. A repo only runs checks if it's listed here — unregistered
repos are skipped entirely. Repos are matched by `path` (the main working
tree), so every worktree of a registered repo is covered automatically.

```yaml
repositories:
  - path: ~/dot-files
    checks:
      - name: settings-json
        command: jq -e . .claude/settings.json >/dev/null
  - path: ~/Workplace/backend-services
    checks:
      - name: typecheck
        command: npm run typecheck
      - name: unit
        command: npm test
```

Each check is a `name` + a `command` (same shape as Claude Code hooks), run
with the repo as cwd. Keep them fast — they run after every turn. Machine-
specific or secret checks go in `~/.checks.local.yml` (same shape); it overlays
the matching repo's checks by name.
