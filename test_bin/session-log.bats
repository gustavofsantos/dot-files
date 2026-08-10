#!/usr/bin/env bats

# Tests for bin/hooks-session-log
#
# Isolation strategy:
#   HOME               -> fresh tmpdir
#   AGENT_SESSIONS_DIR -> explicit tmpdir subdirectory
#
# --harness selects the payload shape read from stdin; --event selects which
# of turn_end / subagent_start / subagent_stop runs. Claude's turn_end reads
# a real transcript file; Cursor's turn_end has no transcript and falls back
# to `git diff` against the given workspace root.

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-session-log"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export AGENT_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$AGENT_SESSIONS_DIR"
}

teardown() {
  rm -rf "$TEST_HOME"
}

log_file() { echo "$AGENT_SESSIONS_DIR/${1}.jsonl"; }

write_transcript() {
  local path="$1"
  cat > "$path" <<'EOF'
{"type":"user","uuid":"u1","message":{"role":"user","content":"hello"}}
{"type":"assistant","uuid":"a1","message":{"model":"claude-x","usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":0,"cache_creation_input_tokens":0},"content":[{"type":"text","text":"hi there"},{"type":"tool_use","name":"Write","input":{"file_path":"/tmp/foo.txt"}}]}}
EOF
}

@test "--harness and --event are required" {
  run bash -c "echo '{}' | '$SCRIPT'"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash -c "echo '{}' | '$SCRIPT' --harness windsurf --event turn_end"
  [ "$status" -ne 0 ]
}

# ── claude turn_end ──────────────────────────────────────────────────────────

@test "claude turn_end: parses a fresh transcript into session_start, message, file_change, turn_end events" {
  TRANSCRIPT="$TEST_HOME/transcript.jsonl"
  write_transcript "$TRANSCRIPT"

  payload=$(jq -n --arg sid sess-a --arg tp "$TRANSCRIPT" '{session_id:$sid, transcript_path:$tp}')
  echo "$payload" | "$SCRIPT" --harness claude --event turn_end

  run cat "$(log_file sess-a)"
  types=$(jq -r '.type' "$(log_file sess-a)")
  [[ "$types" == *"session_start"* ]]
  [[ "$types" == *"message"* ]]
  [[ "$types" == *"file_change"* ]]
  [[ "$types" == *"turn_end"* ]]
  [[ "$types" == *"_cursor"* ]]
}

@test "claude turn_end: file_change event records the edited path" {
  TRANSCRIPT="$TEST_HOME/transcript.jsonl"
  write_transcript "$TRANSCRIPT"

  payload=$(jq -n --arg sid sess-a --arg tp "$TRANSCRIPT" '{session_id:$sid, transcript_path:$tp}')
  echo "$payload" | "$SCRIPT" --harness claude --event turn_end

  path=$(jq -sr '[.[] | select(.type=="file_change")][0].path' "$(log_file sess-a)")
  [ "$path" = "/tmp/foo.txt" ]
}

@test "claude turn_end: re-running with no new transcript entries does not duplicate events" {
  TRANSCRIPT="$TEST_HOME/transcript.jsonl"
  write_transcript "$TRANSCRIPT"
  payload=$(jq -n --arg sid sess-a --arg tp "$TRANSCRIPT" '{session_id:$sid, transcript_path:$tp}')

  echo "$payload" | "$SCRIPT" --harness claude --event turn_end
  first_count=$(wc -l < "$(log_file sess-a)")

  echo "$payload" | "$SCRIPT" --harness claude --event turn_end
  second_count=$(wc -l < "$(log_file sess-a)")

  [ "$first_count" -eq "$second_count" ]
}

@test "claude turn_end: a session appended to the transcript produces only the new turn's events" {
  TRANSCRIPT="$TEST_HOME/transcript.jsonl"
  write_transcript "$TRANSCRIPT"
  payload=$(jq -n --arg sid sess-a --arg tp "$TRANSCRIPT" '{session_id:$sid, transcript_path:$tp}')
  echo "$payload" | "$SCRIPT" --harness claude --event turn_end

  printf '{"type":"user","uuid":"u2","message":{"role":"user","content":"again"}}\n' >> "$TRANSCRIPT"
  printf '{"type":"assistant","uuid":"a2","message":{"model":"claude-x","content":[{"type":"text","text":"ok"}]}}\n' >> "$TRANSCRIPT"
  echo "$payload" | "$SCRIPT" --harness claude --event turn_end

  turns=$(jq -sr '[.[] | select(.type=="turn_end")] | length' "$(log_file sess-a)")
  [ "$turns" = "2" ]
}

@test "claude turn_end: missing transcript_path is a no-op" {
  payload=$(jq -n --arg sid sess-a '{session_id:$sid}')
  echo "$payload" | "$SCRIPT" --harness claude --event turn_end
  [ ! -f "$(log_file sess-a)" ]
}

# ── cursor turn_end ──────────────────────────────────────────────────────────

@test "cursor turn_end: derives a file_change event from git diff against the workspace root" {
  REPO="$TEST_HOME/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  echo hi > "$REPO/changed.txt"
  git -C "$REPO" add changed.txt

  payload=$(jq -n --arg sid conv-a --arg root "$REPO" '{conversation_id:$sid, workspace_roots:[$root]}')
  echo "$payload" | "$SCRIPT" --harness cursor --event turn_end

  path=$(jq -sr '[.[] | select(.type=="file_change")][0].path' "$(log_file conv-a)")
  [ "$path" = "changed.txt" ]
}

@test "cursor turn_end: missing conversation_id is a no-op" {
  payload=$(jq -n --arg root "$TEST_HOME" '{workspace_roots:[$root]}')
  echo "$payload" | "$SCRIPT" --harness cursor --event turn_end
  run bash -c "ls '$AGENT_SESSIONS_DIR' 2>/dev/null | wc -l"
  [ "$(echo "$output" | tr -d ' ')" = "0" ]
}

# ── subagent events (claude only) ───────────────────────────────────────────

@test "claude subagent_start: creates a subagent log seeded with session_start" {
  payload=$(jq -n --arg sid sess-a --arg aid agent-1 --arg atype explore \
    '{session_id:$sid, agent_id:$aid, agent_type:$atype}')
  echo "$payload" | "$SCRIPT" --harness claude --event subagent_start

  sub_log="$AGENT_SESSIONS_DIR/sess-a/agent-1.jsonl"
  [ -f "$sub_log" ]
  [ "$(jq -r '.type' "$sub_log")" = "session_start" ]
  [ "$(jq -r '.agent_type' "$sub_log")" = "explore" ]
}

@test "claude subagent_stop: appends the subagent transcript to its own log" {
  TRANSCRIPT="$TEST_HOME/sub-transcript.jsonl"
  write_transcript "$TRANSCRIPT"

  payload=$(jq -n --arg sid sess-a --arg aid agent-1 --arg tp "$TRANSCRIPT" \
    '{session_id:$sid, agent_id:$aid, agent_transcript_path:$tp}')
  echo "$payload" | "$SCRIPT" --harness claude --event subagent_stop

  sub_log="$AGENT_SESSIONS_DIR/sess-a/agent-1.jsonl"
  types=$(jq -r '.type' "$sub_log")
  [[ "$types" == *"turn_end"* ]]
}

@test "subagent_start has no cursor implementation and is rejected" {
  run bash -c "echo '{}' | '$SCRIPT' --harness cursor --event subagent_start"
  [ "$status" -ne 0 ]
}

@test "subagent_stop has no cursor implementation and is rejected" {
  run bash -c "echo '{}' | '$SCRIPT' --harness cursor --event subagent_stop"
  [ "$status" -ne 0 ]
}
