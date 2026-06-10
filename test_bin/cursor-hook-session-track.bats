#!/usr/bin/env bats

# Tests for bin/cursor-hook-session-track
#
# Isolation strategy:
#   HOME              → fresh tmpdir
#   CLAUDE_SESSIONS_DIR → explicit tmpdir subdirectory (shared schema with Claude)
#   TMUX / TMUX_PANE  → unset (script writes pane field only when set)

SCRIPT="$BATS_TEST_DIRNAME/../bin/cursor-hook-session-track"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CLAUDE_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$CLAUDE_SESSIONS_DIR"
  unset TMUX TMUX_PANE CURSOR_PROJECT_DIR CLAUDE_PROJECT_DIR
  SESSION_ID="cursor-conv-xyz"
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$CLAUDE_SESSIONS_DIR/${SESSION_ID}.json"; }
jget()       { jq -r "$1" "$(state_file)" 2>/dev/null; }

# Minimal Cursor beforeSubmitPrompt / sessionStart payload
cursor_json() {
  printf '{"conversation_id":"%s","workspace_roots":["/work/cursor-repo"]}' "$SESSION_ID"
}

# ── Exit behaviour ─────────────────────────────────────────────────────────────

@test "exits 0 on valid Cursor payload" {
  run bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$status" -eq 0 ]
}

@test "exits 0 when conversation_id absent" {
  run bash "$SCRIPT" <<< '{"workspace_roots":["/work"]}'
  [ "$status" -eq 0 ]
}

# ── New session creation ───────────────────────────────────────────────────────

@test "creates session state file" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ -f "$(state_file)" ]
}

@test "new session has agent=cursor" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.agent')" = "cursor" ]
}

@test "new session has status=running" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.status')" = "running" ]
}

@test "new session records session_id from conversation_id" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.session_id')" = "$SESSION_ID" ]
}

@test "new session records dir from first workspace_roots entry" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.dir')" = "/work/cursor-repo" ]
}

@test "new session track_name is basename of workspace root" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.track_name')" = "cursor-repo" ]
}

@test "new session has started_at and last_activity set" {
  bash "$SCRIPT" <<< "$(cursor_json)"
  local sa la
  sa=$(jget '.started_at')
  la=$(jget '.last_activity')
  [ -n "$sa" ] && [ "$sa" != "null" ]
  [ -n "$la" ] && [ "$la" != "null" ]
}

# ── Existing session refresh ───────────────────────────────────────────────────

@test "updates status to running on existing session" {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,agent:"cursor",track_name:"x",task:"",dir:"/old",pane:"",
      status:"ended",started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.status')" = "running" ]
}

@test "updates last_activity on refresh" {
  jq -n --arg sid "$SESSION_ID" \
    '{session_id:$sid,agent:"cursor",track_name:"x",task:"",dir:"/old",pane:"",
      status:"ended",started_at:1,last_activity:1,notifications:0}' > "$(state_file)"
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.last_activity')" -gt 1 ]
}

@test "sets pane field when TMUX_PANE is exported" {
  export TMUX_PANE="%99"
  bash "$SCRIPT" <<< "$(cursor_json)"
  [ "$(jget '.pane')" = "%99" ]
}

@test "uses CURSOR_PROJECT_DIR as dir fallback when workspace_roots absent" {
  export CURSOR_PROJECT_DIR="/fallback/cursor"
  bash "$SCRIPT" <<< "{\"conversation_id\":\"${SESSION_ID}\"}"
  [ "$(jget '.dir')" = "/fallback/cursor" ]
}
