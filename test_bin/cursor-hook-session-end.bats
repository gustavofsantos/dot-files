#!/usr/bin/env bats

# Tests for bin/cursor-hook-session-end
#
# Isolation strategy:
#   HOME              → fresh tmpdir
#   CLAUDE_SESSIONS_DIR → explicit tmpdir subdirectory
#   TMUX / TMUX_PANE  → unset

SCRIPT="$BATS_TEST_DIRNAME/../bin/cursor-hook-session-end"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CLAUDE_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$CLAUDE_SESSIONS_DIR"
  unset TMUX TMUX_PANE
  SESSION_ID="cursor-end-session"
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$CLAUDE_SESSIONS_DIR/${SESSION_ID}.json"; }
jget()       { jq -r "$1" "$(state_file)" 2>/dev/null; }

seed_state() {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,agent:"cursor",track_name:"t",task:"",dir:"/d",pane:"%5",
      status:"running",started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
}

end_json() {
  printf '{"conversation_id":"%s"}' "$SESSION_ID"
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

@test "exits 0 when conversation_id absent" {
  run bash "$SCRIPT" <<< '{}'
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
  [ "$(jget '.last_activity')" -gt 1 ]
}

@test "does not delete the session file" {
  seed_state
  bash "$SCRIPT" <<< "$(end_json)"
  [ -f "$(state_file)" ]
}

# ── No-op guard ───────────────────────────────────────────────────────────────

@test "does not create state file when none exists" {
  bash "$SCRIPT" <<< "$(end_json)"
  [ ! -f "$(state_file)" ]
}
