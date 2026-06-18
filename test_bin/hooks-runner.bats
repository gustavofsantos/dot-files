#!/usr/bin/env bats

# Tests for bin/hooks-runner
#
# Isolation strategy:
#   AGENT_HOOKS_CONFIG       → synthetic tmpdir YAML (no ~/.agent-hooks.yml fallback)
#   AGENT_HOOKS_CONFIG_LOCAL → points to a nonexistent path unless under local-overlay test
#   AGENT_HOOKS_CACHE_DIR    → isolated tmpdir so cache doesn't bleed between tests
#   MARKER                   → tmpdir where stub commands write sentinel files
#
# Dispatch correctness is asserted via marker files, not exit code —
# the runner always exits 0 (neutral) and discards hook stdout.
# Each stub command is "touch $MARKER/<name>".

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-runner"
BIN_DIR="$BATS_TEST_DIRNAME/../bin"

setup() {
  TEST_HOME=$(mktemp -d)
  MARKER=$(mktemp -d)
  export TEST_HOME MARKER
  export AGENT_HOOKS_CONFIG="$TEST_HOME/agent-hooks.yml"
  export AGENT_HOOKS_CONFIG_LOCAL="$TEST_HOME/agent-hooks-nonexistent.yml"
  export AGENT_HOOKS_CACHE_DIR="$TEST_HOME/cache"
  export AGENT_HOOKS_LOG_DIR="$TEST_HOME/logs"
  # Add the repo's own bin/ to PATH so integration tests can invoke real hooks.
  export PATH="$BIN_DIR:$PATH"
}

teardown() {
  rm -rf "$TEST_HOME" "$MARKER"
}

# Write a minimal base registry.
write_base() {
  cat > "$AGENT_HOOKS_CONFIG" "$@"
}

# Default stop payload — minimal JSON to keep stdin non-empty.
stop_json() { echo '{"stop_hook_active":true}'; }

# ── Dispatch one hook ──────────────────────────────────────────────────────────

@test "dispatches a single matching hook and writes its marker" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  stop_json | "$SCRIPT" claude Stop

  [ -f "$MARKER/notify" ]
}

@test "dispatch exits 0 for a matched hook" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  run "$SCRIPT" claude Stop <<< "$(stop_json)"
  [ "$status" -eq 0 ]
}

# ── Dispatch multiple hooks ────────────────────────────────────────────────────

@test "dispatches all matching hooks when multiple are registered for the same event" {
  write_base <<YAML
hooks:
  - name: first
    on: [turn_end]
    command: "touch \$MARKER/first"
  - name: second
    on: [turn_end]
    command: "touch \$MARKER/second"
YAML

  stop_json | "$SCRIPT" claude Stop

  [ -f "$MARKER/first" ]
  [ -f "$MARKER/second" ]
}

@test "only dispatches hooks whose on list includes the canonical event" {
  write_base <<YAML
hooks:
  - name: turn-end-hook
    on: [turn_end]
    command: "touch \$MARKER/turn_end"
  - name: session-end-hook
    on: [session_end]
    command: "touch \$MARKER/session_end"
YAML

  stop_json | "$SCRIPT" claude Stop

  [ -f "$MARKER/turn_end" ]
  [ ! -f "$MARKER/session_end" ]
}

# ── No-match event ─────────────────────────────────────────────────────────────

@test "writes no marker when event has no matching hooks" {
  write_base <<YAML
hooks:
  - name: session-only
    on: [session_start]
    command: "touch \$MARKER/session_only"
YAML

  # Dispatch turn_end — nothing in the registry matches it.
  stop_json | "$SCRIPT" claude Stop

  [ ! -f "$MARKER/session_only" ]
}

@test "exits 0 when no hooks match the event" {
  write_base <<YAML
hooks:
  - name: session-only
    on: [session_start]
    command: "touch \$MARKER/session_only"
YAML

  run "$SCRIPT" claude Stop <<< "$(stop_json)"
  [ "$status" -eq 0 ]
}

# ── Remaining Claude event mappings ───────────────────────────────────────────

@test "SessionStart dispatches hooks registered for session_start" {
  write_base <<YAML
hooks:
  - name: session-track
    on: [session_start, prompt_submit]
    command: "touch \$MARKER/session_track"
YAML

  echo '{"session_id":"s1"}' | "$SCRIPT" claude SessionStart

  [ -f "$MARKER/session_track" ]
}

@test "UserPromptSubmit dispatches hooks registered for prompt_submit" {
  write_base <<YAML
hooks:
  - name: session-track
    on: [session_start, prompt_submit]
    command: "touch \$MARKER/session_track"
YAML

  echo '{"session_id":"s1","prompt":"hello"}' | "$SCRIPT" claude UserPromptSubmit

  [ -f "$MARKER/session_track" ]
}

@test "SessionEnd dispatches hooks registered for session_end" {
  write_base <<YAML
hooks:
  - name: session-end
    on: [session_end]
    command: "touch \$MARKER/session_end"
YAML

  echo '{"session_id":"s1"}' | "$SCRIPT" claude SessionEnd

  [ -f "$MARKER/session_end" ]
}

@test "Notification dispatches hooks registered for notification" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end, notification]
    command: "touch \$MARKER/notify"
YAML

  echo '{"message":"done"}' | "$SCRIPT" claude Notification

  [ -f "$MARKER/notify" ]
}

@test "SessionStart does not fire turn_end hooks" {
  write_base <<YAML
hooks:
  - name: session-track
    on: [session_start]
    command: "touch \$MARKER/session_track"
  - name: snapshot
    on: [turn_end]
    command: "touch \$MARKER/snapshot"
YAML

  echo '{"session_id":"s1"}' | "$SCRIPT" claude SessionStart

  [ -f "$MARKER/session_track" ]
  [ ! -f "$MARKER/snapshot" ]
}

# ── Local override ─────────────────────────────────────────────────────────────

@test "local entry with same name replaces base entry and runs local command" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/base"
YAML

  cat > "$AGENT_HOOKS_CONFIG_LOCAL" <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/local"
YAML
  export AGENT_HOOKS_CONFIG_LOCAL

  stop_json | "$SCRIPT" claude Stop

  [ -f "$MARKER/local" ]
  [ ! -f "$MARKER/base" ]
}

@test "local entry with a new name adds that hook alongside base hooks" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/base"
YAML

  cat > "$AGENT_HOOKS_CONFIG_LOCAL" <<YAML
hooks:
  - name: extra
    on: [turn_end]
    command: "touch \$MARKER/extra"
YAML
  export AGENT_HOOKS_CONFIG_LOCAL

  stop_json | "$SCRIPT" claude Stop

  [ -f "$MARKER/base" ]
  [ -f "$MARKER/extra" ]
}

# ── Local enabled: false disable ───────────────────────────────────────────────

@test "local enabled false disables the base hook — no marker written" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  cat > "$AGENT_HOOKS_CONFIG_LOCAL" <<YAML
hooks:
  - name: notify
    enabled: false
YAML
  export AGENT_HOOKS_CONFIG_LOCAL

  stop_json | "$SCRIPT" claude Stop

  [ ! -f "$MARKER/notify" ]
}

@test "enabled false does not affect other hooks registered for the same event" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
  - name: snapshot
    on: [turn_end]
    command: "touch \$MARKER/snapshot"
YAML

  cat > "$AGENT_HOOKS_CONFIG_LOCAL" <<YAML
hooks:
  - name: notify
    enabled: false
YAML
  export AGENT_HOOKS_CONFIG_LOCAL

  stop_json | "$SCRIPT" claude Stop

  [ ! -f "$MARKER/notify" ]
  [ -f "$MARKER/snapshot" ]
}

# ── Missing registry graceful skip ────────────────────────────────────────────

@test "exits 0 gracefully when registry file is missing" {
  export AGENT_HOOKS_CONFIG="$TEST_HOME/nonexistent.yml"

  run "$SCRIPT" claude Stop <<< "$(stop_json)"
  [ "$status" -eq 0 ]
}

@test "writes no markers when registry file is missing" {
  export AGENT_HOOKS_CONFIG="$TEST_HOME/nonexistent.yml"

  stop_json | "$SCRIPT" claude Stop
  # Marker dir should be empty — nothing ran.
  [ -z "$(ls -A "$MARKER")" ]
}

# ── Cursor event mappings ──────────────────────────────────────────────────────

@test "cursor stop maps to turn_end and dispatches hooks registered for turn_end" {
  write_base <<YAML
hooks:
  - name: snapshot
    on: [turn_end]
    command: "touch \$MARKER/snapshot"
YAML

  echo '{"conversation_id":"c1"}' | "$SCRIPT" cursor stop

  [ -f "$MARKER/snapshot" ]
}

@test "cursor sessionStart maps to session_start and dispatches session_start hooks" {
  write_base <<YAML
hooks:
  - name: cursor-track
    on: [session_start]
    command: "touch \$MARKER/cursor_track"
YAML

  echo '{"conversation_id":"c1","workspace_roots":["/home/user/proj"]}' \
    | "$SCRIPT" cursor sessionStart

  [ -f "$MARKER/cursor_track" ]
}

@test "cursor beforeSubmitPrompt maps to prompt_submit and dispatches prompt_submit hooks" {
  write_base <<YAML
hooks:
  - name: cursor-track
    on: [prompt_submit]
    command: "touch \$MARKER/cursor_track"
YAML

  echo '{"conversation_id":"c1","workspace_roots":["/home/user/proj"]}' \
    | "$SCRIPT" cursor beforeSubmitPrompt

  [ -f "$MARKER/cursor_track" ]
}

@test "cursor sessionEnd maps to session_end and dispatches session_end hooks" {
  write_base <<YAML
hooks:
  - name: cursor-end
    on: [session_end]
    command: "touch \$MARKER/cursor_end"
YAML

  echo '{"conversation_id":"c1"}' | "$SCRIPT" cursor sessionEnd

  [ -f "$MARKER/cursor_end" ]
}

@test "cursor harness filter excludes claude-only hooks" {
  write_base <<YAML
hooks:
  - name: claude-only
    on: [turn_end]
    command: "touch \$MARKER/claude_only"
    harness: [claude]
  - name: both
    on: [turn_end]
    command: "touch \$MARKER/both"
YAML

  echo '{"conversation_id":"c1"}' | "$SCRIPT" cursor stop

  [ ! -f "$MARKER/claude_only" ]
  [ -f "$MARKER/both" ]
}

# ── CanonicalEvent envelope ────────────────────────────────────────────────────
# These tests capture the envelope on stdin via a stub that writes it to a file
# and assert the normalised fields are present.  This is the primary guard that
# a malformed envelope doesn't silently reach real hooks.

@test "envelope sent to hooks has harness and event fields set" {
  write_base <<YAML
hooks:
  - name: capture
    on: [turn_end]
    command: "cat > \$MARKER/payload"
YAML

  echo '{"stop_hook_active":true,"session_id":"s1","cwd":"/repo"}' \
    | "$SCRIPT" claude Stop

  [ -f "$MARKER/payload" ]
  jq -e '.harness == "claude"' "$MARKER/payload" >/dev/null
  jq -e '.event == "turn_end"' "$MARKER/payload" >/dev/null
  jq -e '.raw_event == "Stop"' "$MARKER/payload" >/dev/null
}

@test "Claude envelope normalises session_id and cwd from raw payload" {
  write_base <<YAML
hooks:
  - name: capture
    on: [turn_end]
    command: "cat > \$MARKER/payload"
YAML

  echo '{"session_id":"abc123","cwd":"/home/user/project","stop_hook_active":true}' \
    | "$SCRIPT" claude Stop

  jq -e '.session_id == "abc123"' "$MARKER/payload" >/dev/null
  jq -e '.cwd == "/home/user/project"' "$MARKER/payload" >/dev/null
}

@test "Cursor envelope maps conversation_id to session_id and workspace_roots[0] to cwd" {
  write_base <<YAML
hooks:
  - name: capture
    on: [turn_end]
    command: "cat > \$MARKER/payload"
YAML

  echo '{"conversation_id":"cursor-sess-42","workspace_roots":["/home/user/cursorproj"]}' \
    | "$SCRIPT" cursor stop

  [ -f "$MARKER/payload" ]
  jq -e '.harness == "cursor"' "$MARKER/payload" >/dev/null
  jq -e '.event == "turn_end"' "$MARKER/payload" >/dev/null
  jq -e '.session_id == "cursor-sess-42"' "$MARKER/payload" >/dev/null
  jq -e '.cwd == "/home/user/cursorproj"' "$MARKER/payload" >/dev/null
}

@test "envelope always carries raw field with original payload" {
  write_base <<YAML
hooks:
  - name: capture
    on: [session_start]
    command: "cat > \$MARKER/payload"
YAML

  echo '{"conversation_id":"c99","workspace_roots":["/proj"],"extra_field":"kept"}' \
    | "$SCRIPT" cursor sessionStart

  jq -e '.raw.conversation_id == "c99"' "$MARKER/payload" >/dev/null
  jq -e '.raw.extra_field == "kept"' "$MARKER/payload" >/dev/null
}

# ── Integration: envelope → real hooks ────────────────────────────────────────
# Guard the envelope→real-hook seam for both harnesses.  These tests exercise
# the actual hook scripts (not stubs) to confirm they consume the normalised
# fields correctly after the stdin contract changed from raw payload → envelope.

@test "integration: cursor sessionStart through hooks-runner writes agent:cursor state file" {
  write_base <<YAML
hooks:
  - name: cursor-session-track
    on: [session_start, prompt_submit]
    command: cursor-hook-session-track
    harness: [cursor]
YAML
  SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$SESSIONS_DIR"
  export CLAUDE_SESSIONS_DIR="$SESSIONS_DIR"

  echo '{"conversation_id":"integration-cursor-1","workspace_roots":["/home/user/cursorproj"]}' \
    | "$SCRIPT" cursor sessionStart

  [ -f "$SESSIONS_DIR/integration-cursor-1.json" ]
  jq -e '.agent == "cursor"' "$SESSIONS_DIR/integration-cursor-1.json" >/dev/null
  jq -e '.session_id == "integration-cursor-1"' "$SESSIONS_DIR/integration-cursor-1.json" >/dev/null
  jq -e '.dir == "/home/user/cursorproj"' "$SESSIONS_DIR/integration-cursor-1.json" >/dev/null
  jq -e '.status == "running"' "$SESSIONS_DIR/integration-cursor-1.json" >/dev/null
}

@test "integration: claude SessionStart through hooks-runner writes claude state file" {
  write_base <<YAML
hooks:
  - name: session-track
    on: [session_start, prompt_submit]
    command: claude-hook-session-track
    harness: [claude]
YAML
  SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$SESSIONS_DIR"
  export CLAUDE_SESSIONS_DIR="$SESSIONS_DIR"
  export CLAUDE_SESSION_ID="integration-claude-1"

  echo '{"session_id":"integration-claude-1","cwd":"/home/user/claudeproj"}' \
    | "$SCRIPT" claude SessionStart

  [ -f "$SESSIONS_DIR/integration-claude-1.json" ]
  jq -e '.session_id == "integration-claude-1"' "$SESSIONS_DIR/integration-claude-1.json" >/dev/null
  jq -e '.dir == "/home/user/claudeproj"' "$SESSIONS_DIR/integration-claude-1.json" >/dev/null
  jq -e '.status == "running"' "$SESSIONS_DIR/integration-claude-1.json" >/dev/null

  unset CLAUDE_SESSION_ID
}

@test "integration: cursor and claude hooks do not cross-fire via harness filter" {
  write_base <<YAML
hooks:
  - name: session-track
    on: [session_start]
    command: claude-hook-session-track
    harness: [claude]
  - name: cursor-session-track
    on: [session_start]
    command: cursor-hook-session-track
    harness: [cursor]
YAML
  SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$SESSIONS_DIR"
  export CLAUDE_SESSIONS_DIR="$SESSIONS_DIR"
  unset CLAUDE_SESSION_ID 2>/dev/null || true

  echo '{"conversation_id":"cursor-only-sess","workspace_roots":["/proj"]}' \
    | "$SCRIPT" cursor sessionStart

  # Cursor session file should exist with agent:"cursor"
  [ -f "$SESSIONS_DIR/cursor-only-sess.json" ]
  jq -e '.agent == "cursor"' "$SESSIONS_DIR/cursor-only-sess.json" >/dev/null
  # Claude hook should not have fired — no claude session file
  [ ! -f "$SESSIONS_DIR/.json" ]
}

# ── Dispatch logging ──────────────────────────────────────────────────────────
# Verify that matched-hook dispatches produce a results.json-shaped trace file.

@test "dispatch logging: trace file is written under AGENT_HOOKS_LOG_DIR when hooks match" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  echo '{"session_id":"log-sess-1","cwd":"/repo","stop_hook_active":true}' \
    | "$SCRIPT" claude Stop

  # At least one trace file should exist under the session subdir.
  [ -n "$(find "$AGENT_HOOKS_LOG_DIR/log-sess-1" -name '*-claude-turn_end.json' 2>/dev/null)" ]
}

@test "dispatch logging: trace file has correct top-level fields" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  echo '{"session_id":"log-sess-2","cwd":"/repo"}' \
    | "$SCRIPT" claude Stop

  TRACE=$(find "$AGENT_HOOKS_LOG_DIR/log-sess-2" -name '*-claude-turn_end.json' | head -1)
  [ -n "$TRACE" ]
  jq -e '.harness == "claude"'   "$TRACE" >/dev/null
  jq -e '.event == "turn_end"'   "$TRACE" >/dev/null
  jq -e '.raw_event == "Stop"'   "$TRACE" >/dev/null
  jq -e '.started_at != null'    "$TRACE" >/dev/null
  jq -e '.finished_at != null'   "$TRACE" >/dev/null
}

@test "dispatch logging: trace lists matched hook with name, status, exit_code, duration_ms, output_tail" {
  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "true"
YAML

  echo '{"session_id":"log-sess-3","cwd":"/repo"}' \
    | "$SCRIPT" claude Stop

  TRACE=$(find "$AGENT_HOOKS_LOG_DIR/log-sess-3" -name '*-claude-turn_end.json' | head -1)
  [ -n "$TRACE" ]
  jq -e '.hooks | length == 1'             "$TRACE" >/dev/null
  jq -e '.hooks[0].name == "notify"'       "$TRACE" >/dev/null
  jq -e '.hooks[0].status == "pass"'       "$TRACE" >/dev/null
  jq -e '.hooks[0].exit_code == 0'         "$TRACE" >/dev/null
  jq -e '.hooks[0].duration_ms != null'    "$TRACE" >/dev/null
  jq -e '.hooks[0].output_tail != null'    "$TRACE" >/dev/null
}

@test "dispatch logging: summary reflects total, passed, failed counts" {
  write_base <<YAML
hooks:
  - name: ok-hook
    on: [turn_end]
    command: "true"
  - name: fail-hook
    on: [turn_end]
    command: "false"
YAML

  echo '{"session_id":"log-sess-4","cwd":"/repo"}' \
    | "$SCRIPT" claude Stop

  TRACE=$(find "$AGENT_HOOKS_LOG_DIR/log-sess-4" -name '*-claude-turn_end.json' | head -1)
  [ -n "$TRACE" ]
  jq -e '.summary.total == 2'    "$TRACE" >/dev/null
  jq -e '.summary.passed == 1'   "$TRACE" >/dev/null
  jq -e '.summary.failed == 1'   "$TRACE" >/dev/null
  jq -e '.summary.status == "fail"' "$TRACE" >/dev/null
}

@test "dispatch logging: all-pass summary has status pass" {
  write_base <<YAML
hooks:
  - name: hook-a
    on: [turn_end]
    command: "true"
  - name: hook-b
    on: [turn_end]
    command: "true"
YAML

  echo '{"session_id":"log-sess-5","cwd":"/repo"}' \
    | "$SCRIPT" claude Stop

  TRACE=$(find "$AGENT_HOOKS_LOG_DIR/log-sess-5" -name '*-claude-turn_end.json' | head -1)
  [ -n "$TRACE" ]
  jq -e '.summary.status == "pass"' "$TRACE" >/dev/null
  jq -e '.summary.passed == 2'      "$TRACE" >/dev/null
  jq -e '.summary.failed == 0'      "$TRACE" >/dev/null
}

@test "dispatch logging: no trace written when no hooks match" {
  write_base <<YAML
hooks:
  - name: session-only
    on: [session_start]
    command: "touch \$MARKER/session_only"
YAML

  echo '{"session_id":"log-sess-no-match"}' | "$SCRIPT" claude Stop

  # Log dir should not have any trace for this session.
  [ ! -d "$AGENT_HOOKS_LOG_DIR/log-sess-no-match" ]
}

@test "dispatch logging: failed hook stderr is re-emitted and exit code captured" {
  write_base <<YAML
hooks:
  - name: bad-hook
    on: [turn_end]
    command: "echo 'hook error message' >&2; exit 42"
YAML

  run "$SCRIPT" claude Stop <<< '{"session_id":"log-sess-6"}'

  # Runner still exits 0 — neutral.
  [ "$status" -eq 0 ]
  # Stderr from the failing hook is re-emitted to the runner's stderr.
  [[ "$output" == *"hook error message"* ]]

  TRACE=$(find "$AGENT_HOOKS_LOG_DIR/log-sess-6" -name '*-claude-turn_end.json' | head -1)
  [ -n "$TRACE" ]
  jq -e '.hooks[0].exit_code == 42'    "$TRACE" >/dev/null
  jq -e '.hooks[0].status == "fail"'   "$TRACE" >/dev/null
}

@test "dispatch logging: runner exits 0 even when log dir cannot be created" {
  export AGENT_HOOKS_LOG_DIR="/dev/null/no-such-dir"

  write_base <<YAML
hooks:
  - name: notify
    on: [turn_end]
    command: "touch \$MARKER/notify"
YAML

  run "$SCRIPT" claude Stop <<< '{"session_id":"s1","stop_hook_active":true}'

  # Hook still ran despite log failure.
  [ "$status" -eq 0 ]
  [ -f "$MARKER/notify" ]
}
