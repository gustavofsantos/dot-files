#!/usr/bin/env bats

# Tests for agents/hooks/notify
#
# Replaces claude-hook-notify.bats, fixing a pre-existing bug: the old test
# isolated state via CLAUDE_SESSIONS_DIR, but the script reads
# AGENT_SESSIONS_DIR — most assertions were silently running against the
# real $HOME/.agent-sessions and failing. This file uses the variable the
# script actually reads.
#
# Isolation strategy:
#   HOME               → fresh tmpdir
#   AGENT_SESSIONS_DIR → explicit tmpdir subdirectory
#   TMUX / TMUX_PANE   → unset so tmux rename-window is never attempted on
#                        the real tmux session

SCRIPT="$BATS_TEST_DIRNAME/../agents/hooks/notify"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export AGENT_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$AGENT_SESSIONS_DIR"
  unset TMUX TMUX_PANE CLAUDE_TRACK_NAME CLAUDE_TRACK_TASK CLAUDE_TRACK_DIR
  SESSION_ID="test-notify-session"
  export CLAUDE_SESSION_ID="$SESSION_ID"
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$AGENT_SESSIONS_DIR/${SESSION_ID}.json"; }
jget()       { jq -r "$1" "$(state_file)" 2>/dev/null; }

seed_state() {
  local status="${1:-running}"
  jq -n --arg sid "$SESSION_ID" --arg s "$status" \
    '{session_id:$sid,track_name:"t",task:"",dir:"/d",pane:"",status:$s,
      started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
}

stop_json()         { echo '{"stop_hook_active":true,"last_assistant_message":"done"}'; }
notification_json() { echo '{"message":"Claude needs your attention","notification_type":"idle_prompt"}'; }
unknown_json()      { echo '{"some_other_field":"value"}'; }

@test "--harness is required" {
  run bash "$SCRIPT" <<< "$(stop_json)"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness cursor <<< "$(stop_json)"
  [ "$status" -ne 0 ]
}

# ── Exit behaviour ─────────────────────────────────────────────────────────────

@test "exits 0 for Stop hook payload" {
  seed_state
  run bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 for Notification hook payload" {
  seed_state
  run bash "$SCRIPT" --harness claude <<< "$(notification_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 for unrecognised payload without touching state" {
  seed_state
  run bash "$SCRIPT" --harness claude <<< "$(unknown_json)"
  [ "$status" -eq 0 ]
}

# ── Stop hook ─────────────────────────────────────────────────────────────────

@test "Stop hook sets status to waiting" {
  seed_state "running"
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.status')" = "waiting" ]
}

@test "Stop hook increments notifications counter" {
  seed_state
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.notifications')" = "1" ]
}

@test "Stop hook increments notifications cumulatively" {
  seed_state
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.notifications')" = "2" ]
}

@test "Stop hook updates last_activity" {
  seed_state
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.last_activity')" -gt 1 ]
}

# ── Notification hook ─────────────────────────────────────────────────────────

@test "Notification hook sets status to waiting" {
  seed_state "running"
  bash "$SCRIPT" --harness claude <<< "$(notification_json)"
  [ "$(jget '.status')" = "waiting" ]
}

@test "Notification hook increments notifications counter" {
  seed_state
  bash "$SCRIPT" --harness claude <<< "$(notification_json)"
  [ "$(jget '.notifications')" = "1" ]
}

@test "Notification hook updates last_activity" {
  seed_state
  bash "$SCRIPT" --harness claude <<< "$(notification_json)"
  [ "$(jget '.last_activity')" -gt 1 ]
}

# ── First-fire session creation ───────────────────────────────────────────────

@test "Stop hook creates session file when none exists" {
  export CLAUDE_TRACK_NAME="my-session"
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ -f "$(state_file)" ]
}

@test "first-fire session starts with notifications=1" {
  export CLAUDE_TRACK_NAME="my-session"
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.notifications')" = "1" ]
}

@test "first-fire session has status=waiting" {
  export CLAUDE_TRACK_NAME="my-session"
  bash "$SCRIPT" --harness claude <<< "$(stop_json)"
  [ "$(jget '.status')" = "waiting" ]
}

# ── No-op guard ───────────────────────────────────────────────────────────────

@test "unrecognised payload does not modify existing state" {
  seed_state "running"
  bash "$SCRIPT" --harness claude <<< "$(unknown_json)"
  [ "$(jget '.status')" = "running" ]
}

@test "no state file created for unrecognised payload" {
  unset CLAUDE_SESSION_ID
  run bash "$SCRIPT" --harness claude <<< "$(unknown_json)"
  [ "$status" -eq 0 ]
  [ ! -f "$(state_file)" ]
}
