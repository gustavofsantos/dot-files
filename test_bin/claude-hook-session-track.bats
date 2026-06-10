#!/usr/bin/env bats

# Tests for bin/claude-hook-session-track
#
# Isolation strategy:
#   HOME              → fresh tmpdir (no real ~/.claude-sessions fallback)
#   CLAUDE_SESSIONS_DIR → explicit tmpdir subdirectory
#   TMUX / TMUX_PANE  → unset so no real tmux window is renamed
#   CLAUDE_TRACK_NAME → unset unless under test

SCRIPT="$BATS_TEST_DIRNAME/../bin/claude-hook-session-track"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CLAUDE_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$CLAUDE_SESSIONS_DIR"
  unset TMUX TMUX_PANE CLAUDE_TRACK_NAME CLAUDE_TRACK_TASK CLAUDE_PROJECT_DIR CLAUDE_TRACK_DIR
  SESSION_ID="test-session-abc"
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$CLAUDE_SESSIONS_DIR/${SESSION_ID}.json"; }
jget()       { jq -r "$1" "$(state_file)" 2>/dev/null; }

# Minimal valid SessionStart payload (docs field: session_id + cwd)
session_json() {
  printf '{"session_id":"%s","cwd":"/work/myrepo","hook_event_name":"SessionStart"}' "$SESSION_ID"
}

# ── Exit behaviour ─────────────────────────────────────────────────────────────

@test "exits 0 on valid SessionStart input" {
  run bash "$SCRIPT" <<< "$(session_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 when session_id is absent and env var unset" {
  unset CLAUDE_SESSION_ID
  run bash "$SCRIPT" <<< '{"cwd":"/work"}'
  [ "$status" -eq 0 ]
}

# ── New session creation (from stdin session_id) ───────────────────────────────

@test "creates session state file for new session" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ -f "$(state_file)" ]
}

@test "new session has status=running" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.status')" = "running" ]
}

@test "new session records session_id" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.session_id')" = "$SESSION_ID" ]
}

@test "new session records dir from stdin cwd" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.dir')" = "/work/myrepo" ]
}

@test "new session track_name defaults to basename of cwd" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.track_name')" = "myrepo" ]
}

@test "new session track_name uses CLAUDE_TRACK_NAME env var when set" {
  export CLAUDE_TRACK_NAME="my-feature"
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.track_name')" = "my-feature" ]
}

@test "new session task uses CLAUDE_TRACK_TASK env var when set" {
  export CLAUDE_TRACK_TASK="refactor auth"
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.task')" = "refactor auth" ]
}

@test "new session has started_at and last_activity set" {
  bash "$SCRIPT" <<< "$(session_json)"
  local sa la
  sa=$(jget '.started_at')
  la=$(jget '.last_activity')
  [ -n "$sa" ] && [ "$sa" != "null" ]
  [ -n "$la" ] && [ "$la" != "null" ]
}

@test "new session has notifications=0" {
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.notifications')" = "0" ]
}

# ── Session creation from env var ─────────────────────────────────────────────

@test "reads session_id from CLAUDE_SESSION_ID env var when stdin has none" {
  export CLAUDE_SESSION_ID="$SESSION_ID"
  bash "$SCRIPT" <<< '{"cwd":"/work/myrepo"}'
  [ -f "$(state_file)" ]
}

@test "reads dir from CLAUDE_TRACK_DIR env var when stdin cwd is absent" {
  export CLAUDE_SESSION_ID="$SESSION_ID"
  export CLAUDE_TRACK_DIR="/env/project"
  bash "$SCRIPT" <<< '{}'
  [ "$(jget '.dir')" = "/env/project" ]
}

# ── Existing session refresh ───────────────────────────────────────────────────

@test "updates status to running on existing session" {
  # Seed with ended status
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,track_name:"x",task:"",dir:"/old",pane:"",status:"ended",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.status')" = "running" ]
}

@test "updates last_activity on existing session" {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,track_name:"x",task:"",dir:"/old",pane:"",status:"ended",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
  bash "$SCRIPT" <<< "$(session_json)"
  local la
  la=$(jget '.last_activity')
  [ "$la" -gt 1 ]
}

@test "preserves existing dir when stdin cwd is empty and dir already set" {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,track_name:"x",task:"",dir:"/existing",pane:"",status:"running",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
  bash "$SCRIPT" <<< '{"session_id":"'"$SESSION_ID"'","cwd":""}'
  [ "$(jget '.dir')" = "/existing" ]
}

@test "sets pane field when TMUX_PANE is exported" {
  export TMUX_PANE="%42"
  bash "$SCRIPT" <<< "$(session_json)"
  [ "$(jget '.pane')" = "%42" ]
}
