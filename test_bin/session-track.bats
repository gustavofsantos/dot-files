#!/usr/bin/env bats

# Tests for agents/hooks/session-track
#
# Replaces claude-hook-session-track.bats + cursor-hook-session-track.bats.
# Those two used CLAUDE_SESSIONS_DIR to isolate state, but the script (both
# before and after this port) reads AGENT_SESSIONS_DIR — the old tests were
# silently writing/reading against $HOME/.agent-sessions instead of the
# tmpdir they thought they controlled, and most of them failed. This file
# uses the variable the script actually reads.
#
# Isolation strategy:
#   HOME               → fresh tmpdir
#   AGENT_SESSIONS_DIR → explicit tmpdir subdirectory
#   TMUX / TMUX_PANE   → unset unless under test

SCRIPT="$BATS_TEST_DIRNAME/../agents/hooks/session-track"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export AGENT_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$AGENT_SESSIONS_DIR"
  unset TMUX TMUX_PANE CLAUDE_TRACK_NAME CLAUDE_TRACK_TASK CLAUDE_PROJECT_DIR \
    CLAUDE_TRACK_DIR CLAUDE_SESSION_ID CURSOR_PROJECT_DIR
}

teardown() {
  rm -rf "$TEST_HOME"
}

state_file() { echo "$AGENT_SESSIONS_DIR/${1}.json"; }
jget()       { jq -r "$2" "$(state_file "$1")" 2>/dev/null; }

claude_json() {
  printf '{"session_id":"%s","cwd":"/work/myrepo","hook_event_name":"SessionStart"}' "$1"
}

cursor_json() {
  printf '{"conversation_id":"%s","workspace_roots":["/work/cursor-repo"]}' "$1"
}

@test "--harness is required" {
  run bash "$SCRIPT" <<< '{}'
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness windsurf <<< '{}'
  [ "$status" -ne 0 ]
}

# ── claude ───────────────────────────────────────────────────────────────────

@test "claude: exits 0 on valid SessionStart input" {
  run bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$status" -eq 0 ]
}

@test "claude: exits 0 when session_id is absent and env var unset" {
  run bash "$SCRIPT" --harness claude <<< '{"cwd":"/work"}'
  [ "$status" -eq 0 ]
}

@test "claude: creates session state with session_id, running status, dir, track_name" {
  bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$(jget sess-a '.session_id')" = "sess-a" ]
  [ "$(jget sess-a '.status')" = "running" ]
  [ "$(jget sess-a '.dir')" = "/work/myrepo" ]
  [ "$(jget sess-a '.track_name')" = "myrepo" ]
  [ "$(jget sess-a '.notifications')" = "0" ]
  [ "$(jget sess-a '.agent')" = "null" ]
}

@test "claude: track_name uses CLAUDE_TRACK_NAME env var when set" {
  export CLAUDE_TRACK_NAME="my-feature"
  bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$(jget sess-a '.track_name')" = "my-feature" ]
}

@test "claude: task uses CLAUDE_TRACK_TASK env var when set" {
  export CLAUDE_TRACK_TASK="refactor auth"
  bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$(jget sess-a '.task')" = "refactor auth" ]
}

@test "claude: reads session_id from CLAUDE_SESSION_ID env var when stdin has none" {
  export CLAUDE_SESSION_ID="sess-env"
  bash "$SCRIPT" --harness claude <<< '{"cwd":"/work/myrepo"}'
  [ -f "$(state_file sess-env)" ]
}

@test "claude: reads dir from CLAUDE_TRACK_DIR env var when stdin cwd is absent" {
  export CLAUDE_SESSION_ID="sess-env"
  export CLAUDE_TRACK_DIR="/env/project"
  bash "$SCRIPT" --harness claude <<< '{}'
  [ "$(jget sess-env '.dir')" = "/env/project" ]
}

@test "claude: refreshing an existing session sets status running and advances last_activity" {
  jq -n --arg sid sess-a \
    '{session_id:$sid,track_name:"x",task:"",dir:"/old",pane:"",status:"ended",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file sess-a)"
  bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$(jget sess-a '.status')" = "running" ]
  [ "$(jget sess-a '.last_activity')" -gt 1 ]
}

@test "claude: preserves existing dir when stdin cwd is empty and dir already set" {
  jq -n --arg sid sess-a \
    '{session_id:$sid,track_name:"x",task:"",dir:"/existing",pane:"",status:"running",
      started_at:1,last_activity:1,notifications:0}' > "$(state_file sess-a)"
  bash "$SCRIPT" --harness claude <<< '{"session_id":"sess-a","cwd":""}'
  [ "$(jget sess-a '.dir')" = "/existing" ]
}

@test "claude: sets pane field when TMUX_PANE is exported" {
  export TMUX_PANE="%42"
  bash "$SCRIPT" --harness claude <<< "$(claude_json sess-a)"
  [ "$(jget sess-a '.pane')" = "%42" ]
}

# ── cursor ───────────────────────────────────────────────────────────────────

@test "cursor: exits 0 on valid payload" {
  run bash "$SCRIPT" --harness cursor <<< "$(cursor_json conv-a)"
  [ "$status" -eq 0 ]
}

@test "cursor: exits 0 when conversation_id absent" {
  run bash "$SCRIPT" --harness cursor <<< '{"workspace_roots":["/work"]}'
  [ "$status" -eq 0 ]
}

@test "cursor: creates session state with agent=cursor, session_id from conversation_id, dir from workspace_roots" {
  bash "$SCRIPT" --harness cursor <<< "$(cursor_json conv-a)"
  [ "$(jget conv-a '.agent')" = "cursor" ]
  [ "$(jget conv-a '.status')" = "running" ]
  [ "$(jget conv-a '.session_id')" = "conv-a" ]
  [ "$(jget conv-a '.dir')" = "/work/cursor-repo" ]
  [ "$(jget conv-a '.track_name')" = "cursor-repo" ]
}

@test "cursor: refreshing an existing session sets status running and advances last_activity" {
  jq -n --arg sid conv-a \
    '{session_id:$sid,agent:"cursor",track_name:"x",task:"",dir:"/old",pane:"",
      status:"ended",started_at:1,last_activity:1,notifications:0}' > "$(state_file conv-a)"
  bash "$SCRIPT" --harness cursor <<< "$(cursor_json conv-a)"
  [ "$(jget conv-a '.status')" = "running" ]
  [ "$(jget conv-a '.last_activity')" -gt 1 ]
}

@test "cursor: sets pane field when TMUX_PANE is exported" {
  export TMUX_PANE="%99"
  bash "$SCRIPT" --harness cursor <<< "$(cursor_json conv-a)"
  [ "$(jget conv-a '.pane')" = "%99" ]
}

@test "cursor: uses CURSOR_PROJECT_DIR as dir fallback when workspace_roots absent" {
  export CURSOR_PROJECT_DIR="/fallback/cursor"
  bash "$SCRIPT" --harness cursor <<< '{"conversation_id":"conv-a"}'
  [ "$(jget conv-a '.dir')" = "/fallback/cursor" ]
}
