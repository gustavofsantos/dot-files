#!/usr/bin/env bats

# Tests for bin/cursor-hooks-sync
#
# The generator derives ~/.cursor/hooks.json from the unified ~/.agent-hooks.yml
# registry, wiring each Cursor event to `hooks-runner cursor <event>`. It must be
# idempotent, prune stale generated entries, and never touch hand-made config.

SCRIPT="$BATS_TEST_DIRNAME/../bin/cursor-hooks-sync"

setup() {
  T=$(mktemp -d)
  export T
  SRC="$T/agent-hooks.yml"
  LOCAL="$T/agent-hooks.local.yml"
  DEST="$T/hooks.json"
  NONE="$T/nonexistent.yml"
}

teardown() {
  rm -rf "$T"
}

gen() {
  "$SCRIPT" --source "$SRC" --local "${1:-$NONE}" --dest "$DEST" >/dev/null
}

# ── Canonical → Cursor event mapping ──────────────────────────────────────────

@test "tool_pre wires both beforeShellExecution and beforeMCPExecution" {
  cat > "$SRC" <<YAML
hooks:
  - name: gate
    on: [tool_pre]
    command: some-hook
    harness: [claude, cursor]
    decision: true
YAML
  gen

  jq -e '.hooks.beforeShellExecution[0].command == "hooks-runner cursor beforeShellExecution"' "$DEST" >/dev/null
  jq -e '.hooks.beforeMCPExecution[0].command == "hooks-runner cursor beforeMCPExecution"' "$DEST" >/dev/null
}

@test "turn_end wires stop, session_start wires sessionStart, prompt_submit wires beforeSubmitPrompt" {
  cat > "$SRC" <<YAML
hooks:
  - name: a
    on: [turn_end]
    command: h
  - name: b
    on: [session_start]
    command: h
  - name: c
    on: [prompt_submit]
    command: h
YAML
  gen

  jq -e '.hooks.stop[0].command == "hooks-runner cursor stop"' "$DEST" >/dev/null
  jq -e '.hooks.sessionStart[0].command == "hooks-runner cursor sessionStart"' "$DEST" >/dev/null
  jq -e '.hooks.beforeSubmitPrompt[0].command == "hooks-runner cursor beforeSubmitPrompt"' "$DEST" >/dev/null
}

@test "notification has no Cursor equivalent and wires nothing" {
  cat > "$SRC" <<YAML
hooks:
  - name: notify
    on: [notification]
    command: h
YAML
  gen

  jq -e '.hooks == {}' "$DEST" >/dev/null
}

@test "version defaults to 1" {
  cat > "$SRC" <<YAML
hooks:
  - name: a
    on: [turn_end]
    command: h
YAML
  gen
  jq -e '.version == 1' "$DEST" >/dev/null
}

# ── Harness filter ────────────────────────────────────────────────────────────

@test "claude-only hooks are excluded from Cursor wiring" {
  cat > "$SRC" <<YAML
hooks:
  - name: claude-only
    on: [turn_end]
    command: h
    harness: [claude]
YAML
  gen
  jq -e '.hooks == {}' "$DEST" >/dev/null
}

@test "hooks with no harness filter apply to Cursor" {
  cat > "$SRC" <<YAML
hooks:
  - name: both
    on: [turn_end]
    command: h
YAML
  gen
  jq -e '.hooks.stop | length == 1' "$DEST" >/dev/null
}

# ── enabled: false and local overlay ─────────────────────────────────────────

@test "enabled false hooks are excluded" {
  cat > "$SRC" <<YAML
hooks:
  - name: off
    on: [turn_end]
    command: h
    enabled: false
YAML
  gen
  jq -e '.hooks == {}' "$DEST" >/dev/null
}

@test "local overlay can disable a base hook so its event is no longer wired" {
  cat > "$SRC" <<YAML
hooks:
  - name: shell-gate
    on: [tool_pre]
    command: h
    harness: [cursor]
YAML
  cat > "$LOCAL" <<YAML
hooks:
  - name: shell-gate
    enabled: false
YAML
  gen "$LOCAL"
  jq -e '.hooks == {}' "$DEST" >/dev/null
}

@test "local overlay can add a Cursor event not present in base" {
  cat > "$SRC" <<YAML
hooks:
  - name: base
    on: [turn_end]
    command: h
YAML
  cat > "$LOCAL" <<YAML
hooks:
  - name: extra
    on: [prompt_submit]
    command: h
YAML
  gen "$LOCAL"
  jq -e '.hooks.stop | length == 1' "$DEST" >/dev/null
  jq -e '.hooks.beforeSubmitPrompt | length == 1' "$DEST" >/dev/null
}

# ── Idempotency ───────────────────────────────────────────────────────────────

@test "re-running produces an identical file" {
  cat > "$SRC" <<YAML
hooks:
  - name: a
    on: [turn_end, tool_pre]
    command: h
YAML
  gen
  cp "$DEST" "$T/first.json"
  gen
  diff "$T/first.json" "$DEST"
}

# ── Hand-made preservation and pruning ───────────────────────────────────────

@test "hand-made entries and event keys survive generation" {
  cat > "$DEST" <<'JSON'
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [{ "command": "handmade-audit.sh" }],
    "afterFileEdit": [{ "command": "handmade-format.sh" }]
  }
}
JSON
  cat > "$SRC" <<YAML
hooks:
  - name: gate
    on: [tool_pre]
    command: h
    harness: [cursor]
YAML
  gen

  # Hand-made shell entry kept, our sentinel appended alongside it.
  jq -e '.hooks.beforeShellExecution | map(.command) | index("handmade-audit.sh") != null' "$DEST" >/dev/null
  jq -e '.hooks.beforeShellExecution | map(.command) | index("hooks-runner cursor beforeShellExecution") != null' "$DEST" >/dev/null
  # Hand-made event key with no generated counterpart untouched.
  jq -e '.hooks.afterFileEdit[0].command == "handmade-format.sh"' "$DEST" >/dev/null
}

@test "stale generated entries are pruned while hand-made entries remain" {
  cat > "$DEST" <<'JSON'
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      { "command": "handmade-audit.sh" },
      { "command": "hooks-runner cursor beforeShellExecution" }
    ]
  }
}
JSON
  # New registry no longer has any tool_pre hook — the sentinel must be pruned.
  cat > "$SRC" <<YAML
hooks:
  - name: track
    on: [session_start]
    command: h
    harness: [cursor]
YAML
  gen

  jq -e '.hooks.beforeShellExecution | length == 1' "$DEST" >/dev/null
  jq -e '.hooks.beforeShellExecution[0].command == "handmade-audit.sh"' "$DEST" >/dev/null
  jq -e '.hooks.sessionStart[0].command == "hooks-runner cursor sessionStart"' "$DEST" >/dev/null
}

@test "an event key that becomes only-stale is dropped entirely" {
  cat > "$DEST" <<'JSON'
{
  "version": 1,
  "hooks": {
    "stop": [{ "command": "hooks-runner cursor stop" }]
  }
}
JSON
  cat > "$SRC" <<YAML
hooks:
  - name: track
    on: [session_start]
    command: h
    harness: [cursor]
YAML
  gen
  jq -e '.hooks | has("stop") | not' "$DEST" >/dev/null
}

# ── Robustness ────────────────────────────────────────────────────────────────

@test "missing source is a non-zero error" {
  run "$SCRIPT" --source "$NONE" --local "$NONE" --dest "$DEST"
  [ "$status" -ne 0 ]
}

@test "corrupt existing hooks.json is replaced, not crashed on" {
  echo 'not json {{{' > "$DEST"
  cat > "$SRC" <<YAML
hooks:
  - name: a
    on: [turn_end]
    command: h
YAML
  gen
  jq -e '.hooks.stop[0].command == "hooks-runner cursor stop"' "$DEST" >/dev/null
}
