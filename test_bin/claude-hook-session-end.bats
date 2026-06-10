#!/usr/bin/env bats

# Tests for bin/claude-hook-session-end
#
# Isolation strategy:
#   HOME              → fresh tmpdir
#   CLAUDE_SESSIONS_DIR → explicit tmpdir subdirectory
#   TMUX / TMUX_PANE  → unset (script doesn't use them, but belt-and-suspenders)

SCRIPT="$BATS_TEST_DIRNAME/../bin/claude-hook-session-end"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CLAUDE_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$CLAUDE_SESSIONS_DIR"
  unset TMUX TMUX_PANE CLAUDE_SESSION_ID
  SESSION_ID="test-end-session"
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$CLAUDE_SESSIONS_DIR/${SESSION_ID}.json"; }
jget()       { jq -r "$1" "$(state_file)" 2>/dev/null; }

seed_state() {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,track_name:"t",task:"",dir:"/d",pane:"%7",status:"running",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
}

# Minimal SessionEnd payload (docs field: session_id)
end_json() {
  printf '{"session_id":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$SESSION_ID"
}

# ── Exit behaviour ─────────────────────────────────────────────────────────────

@test "exits 0 when session file exists" {
  seed_state
  run bash "$SCRIPT" <<< "$(end_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 when no session state file (no-op)" {
  run bash "$SCRIPT" <<< "$(end_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 when session_id is absent from both stdin and env" {
  unset CLAUDE_SESSION_ID
  run bash "$SCRIPT" <<< '{"hook_event_name":"SessionEnd"}'
  [ "$status" -eq 0 ]
}

# ── Status flip ────────────────────────────────────────────────────────────────

@test "sets status to ended" {
  seed_state
  bash "$SCRIPT" <<< "$(end_json)"
  [ "$(jget '.status')" = "ended" ]
}

@test "clears pane field on end" {
  seed_state
  bash "$SCRIPT" <<< "$(end_json)"
  [ "$(jget '.pane')" = "" ]
}

@test "updates last_activity on end" {
  seed_state
  bash "$SCRIPT" <<< "$(end_json)"
  local la
  la=$(jget '.last_activity')
  [ "$la" -gt 1 ]
}

@test "does not delete the session file" {
  seed_state
  bash "$SCRIPT" <<< "$(end_json)"
  [ -f "$(state_file)" ]
}

# ── Session id sources ─────────────────────────────────────────────────────────

@test "reads session_id from CLAUDE_SESSION_ID env var" {
  seed_state
  export CLAUDE_SESSION_ID="$SESSION_ID"
  bash "$SCRIPT" <<< '{"hook_event_name":"SessionEnd"}'
  [ "$(jget '.status')" = "ended" ]
}

@test "stdin session_id takes precedence (env var absent)" {
  seed_state
  unset CLAUDE_SESSION_ID
  bash "$SCRIPT" <<< "$(end_json)"
  [ "$(jget '.status')" = "ended" ]
}

# ── No-op guards ───────────────────────────────────────────────────────────────

@test "does not create state file when none exists" {
  bash "$SCRIPT" <<< "$(end_json)"
  [ ! -f "$(state_file)" ]
}
