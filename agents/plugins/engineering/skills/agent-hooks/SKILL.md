---
name: agent-hooks
description: Manage agent hooks in the central registry (~/.agent-hooks.yml). Use when adding, removing, or disabling hooks; listing what's registered; reading dispatch logs to debug a hook that isn't firing; or verifying the harness is wired correctly. Trigger on "add a hook", "register a hook", "why isn't my hook firing", "list agent hooks", "disable a hook", or any mention of ~/.agent-hooks.yml.
disable-model-invocation: true
---

# Agent Hooks

All agent hooks are centralised in `~/.agent-hooks.yml` and dispatched by
`hooks-runner`, which retains adapters for both Claude Code and Cursor. The
harness config that wires `hooks-runner` once per event is *static* — for Claude
it's `~/.claude/settings.json`, installed by `./setup.sh`. The dotfiles no longer
ship a `~/.cursor/hooks.json`; Cursor loads Claude's config, so wire its hooks
yourself if you want Cursor dispatch. Either way you add, remove, or tune hooks by
editing the registry alone.

## Registry format

```yaml
# ~/.agent-hooks.yml — committed baseline, shared across machines
hooks:
  - name: my-hook          # unique key for overlay by ~/.agent-hooks.local.yml
    on: [turn_end]         # canonical events (see table below)
    command: my-hook-script  # runs via bash -c; PATH includes ~/.bin
    harness: [claude]      # optional; default = all harnesses
    enabled: true          # optional; false = skip (overrideable locally)
```

### Canonical events

| Canonical name  | Claude event       | Cursor event          |
|-----------------|--------------------|-----------------------|
| `session_start` | SessionStart       | sessionStart          |
| `prompt_submit` | UserPromptSubmit   | beforeSubmitPrompt    |
| `turn_end`      | Stop               | stop                  |
| `session_end`   | SessionEnd         | sessionEnd            |
| `notification`  | Notification       | — (none)              |

### CanonicalEvent envelope

Every hook receives this JSON on stdin — the same shape regardless of harness:

```json
{
  "harness":         "claude",
  "event":           "turn_end",
  "raw_event":       "Stop",
  "session_id":      "...",
  "cwd":             "/path/to/cwd",
  "transcript_path": "/path/to/transcript",
  "model":           "claude-sonnet-4-6",
  "prompt":          null,
  "tool":            null,
  "raw":             { "...original harness payload..." }
}
```

`transcript_path` and `model` are Claude-only (null for Cursor).  
`prompt` is populated only on `prompt_submit` events.  
`raw` is always present as an escape hatch.

## Operations

### List registered hooks

```bash
yq '.hooks[] | [.name, (.on | join(",")), .command] | join("  ")' ~/.agent-hooks.yml
```

### Add a hook

1. Read the current registry:
   ```bash
   cat ~/.agent-hooks.yml
   ```

2. Edit `~/.agent-hooks.yml` with the Write or Edit tool — **do not use `yq -i`**
   (its behaviour varies across flavors). Add the new entry under `hooks:`.

3. Smoke-test the command manually:
   ```bash
   echo '{"harness":"claude","event":"turn_end","raw_event":"Stop","session_id":"test","cwd":"/tmp","transcript_path":null,"model":null,"prompt":null,"tool":null,"raw":{}}' \
     | my-hook-script
   ```

4. Verify the dispatcher picks it up:
   ```bash
   echo '{"session_id":"test","cwd":"/tmp"}' | hooks-runner claude Stop
   # Then check the dispatch log (see Debugging section)
   ```

### Disable a hook on this machine only

Add an entry to `~/.agent-hooks.local.yml` with the same `name` and
`enabled: false`:

```yaml
# ~/.agent-hooks.local.yml — gitignored, machine-local
hooks:
  - name: checks-snapshot
    enabled: false
```

Local entries overlay the baseline by `name`: same name = replace wholesale;
new name = add; `enabled: false` = disable without deleting the baseline.

### Remove a hook permanently

Edit `~/.agent-hooks.yml` and delete the entry. If the hook also exists in
`~/.agent-hooks.local.yml`, remove it there too. The cache will auto-invalidate
on the next dispatcher call.

### Check harness wiring

Claude Code (should be static — `hooks-runner` once per event):

```bash
jq '.hooks' ~/.claude/settings.json
```

Expected: each event key (`SessionStart`, `UserPromptSubmit`, `Stop`,
`SessionEnd`, `Notification`) maps to `hooks-runner claude <EventName>`.

Cursor (same principle, but **not shipped by the dotfiles** — wire it yourself if
you run Cursor):

```bash
cat ~/.cursor/hooks.json
```

Expected (if you've wired it): `sessionStart`, `beforeSubmitPrompt`, `stop`,
`sessionEnd` each map to `~/.bin/hooks-runner cursor <eventName>`. The
`hooks-runner cursor` adapter still exists; only the install of this config was
removed.

If Claude wiring is missing, re-run `./setup.sh` in the dot-files repo. Do not
hand-edit these files to add hook entries — add to the registry instead.

## Debugging a hook that isn't firing

### 1. Check the dispatch log

```bash
# Find the session log dir (most recent session)
ls -lt ~/.local/share/agent-hooks/logs/ | head -5

# Inside a session dir, each file is one dispatcher invocation:
#   <timestamp>-<harness>-<canonical_event>.json
ls ~/.local/share/agent-hooks/logs/<session-id>/
cat ~/.local/share/agent-hooks/logs/<session-id>/<timestamp>-claude-turn_end.json
```

Log shape:

```json
{
  "harness": "claude",
  "event": "turn_end",
  "raw_event": "Stop",
  "started_at": 1781200000,
  "finished_at": 1781200001,
  "hooks": [
    {
      "name": "my-hook",
      "command": "my-hook-script",
      "status": "pass",
      "exit_code": 0,
      "duration_ms": 42,
      "output_tail": "..."
    }
  ],
  "summary": { "total": 1, "passed": 1, "failed": 0, "status": "pass" }
}
```

- No log file for the event → the dispatcher ran zero matching hooks (check
  `on`, `harness` filter, `enabled` field).
- `status: "fail"` for a hook → `output_tail` has the last 20 lines of stderr.

### 2. Run the dispatcher interactively

```bash
# Simulate a turn_end from Claude
echo '{"session_id":"debug","cwd":"/tmp","stop_hook_active":true}' \
  | AGENT_HOOKS_LOG_DIR=/tmp/hooks-debug hooks-runner claude Stop

# Inspect the trace
cat /tmp/hooks-debug/debug/*-claude-turn_end.json 2>/dev/null || echo "no trace (zero matches)"
```

### 3. Check registry merge

```bash
# What does the merged registry actually look like?
yq -o=json '.hooks // []' ~/.agent-hooks.yml
yq -o=json '.hooks // []' ~/.agent-hooks.local.yml 2>/dev/null || echo '[]'
```

### 4. Verify dependencies

```bash
command -v ruby      # required by hooks-runner (stdlib yaml/json only)
command -v hooks-runner   # must be on PATH
```

### 5. Run the tests

```bash
cd ~/dot-files && bats test_bin/hooks-runner.bats
```

All tests should pass. A failing test points to a regression in the dispatcher
itself.

## Local-only hooks

Private hooks (tied to software not in the public dotfiles) go into
`~/.agent-hooks.local.yml`. Same YAML shape, never committed. Example:

```yaml
# ~/.agent-hooks.local.yml
hooks:
  - name: work-session-sync
    on: [turn_end]
    command: /opt/work/bin/sync-ai-session
    harness: [claude, cursor]
```

`create-local-files.sh` seeds this file empty on a new machine.

## Cache

The dispatcher caches the merged registry JSON keyed by mtime+size of both
files. The cache lives under:
```
~/.cache/agent-hooks/
```

It invalidates automatically when either registry file changes. You never need
to clear it manually — but if something seems stale, delete the cache dir:
```bash
rm -rf ~/.cache/agent-hooks
```
