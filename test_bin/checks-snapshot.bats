#!/usr/bin/env bats

# Tests for bin/hooks-checks-snapshot
#
# checks-config / checks-hash / checks-runner are stubbed on PATH so these
# tests exercise checks-snapshot's own logic (session/dir resolution per
# harness, snapshot file writing, idempotence) without depending on a real
# ~/.checks.yml registry or spawning a real checks run.
#
# Isolation strategy:
#   HOME       → fresh tmpdir
#   CHECKS_DIR → explicit tmpdir subdirectory
#   STUB_BIN   → prepended to PATH, holds the fake checks-config/-hash/-runner

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-checks-snapshot"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CHECKS_DIR="$TEST_HOME/checks"
  export AGENT_SESSIONS_DIR="$TEST_HOME/sessions"
  mkdir -p "$CHECKS_DIR" "$AGENT_SESSIONS_DIR"
  unset TMUX_PANE CLAUDE_SESSION_ID CLAUDE_TRACK_DIR CURSOR_SESSION_ID CURSOR_PROJECT_DIR

  REPO="$TEST_HOME/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

  STUB_BIN="$TEST_HOME/stubbin"
  mkdir -p "$STUB_BIN"
  cat > "$STUB_BIN/checks-config" <<'EOF'
#!/usr/bin/env bash
exit "${STUB_REGISTERED_EXIT:-0}"
EOF
  cat > "$STUB_BIN/checks-hash" <<'EOF'
#!/usr/bin/env bash
echo "${STUB_HASH:-hash1}"
EOF
  cat > "$STUB_BIN/checks-runner" <<'EOF'
#!/usr/bin/env bash
touch "${STUB_RUNNER_MARKER}" 2>/dev/null || true
EOF
  chmod +x "$STUB_BIN"/*
  export PATH="$STUB_BIN:$PATH"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "--harness is required" {
  run bash -c "echo '{}' | '$SCRIPT'"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash -c "echo '{}' | '$SCRIPT' --harness windsurf"
  [ "$status" -ne 0 ]
}

@test "claude: missing session_id is a no-op" {
  echo '{}' | bash "$SCRIPT" --harness claude
  [ -z "$(ls "$CHECKS_DIR")" ]
}

@test "claude: writes a snapshot keyed by session_id under CLAUDE_TRACK_DIR" {
  export CLAUDE_SESSION_ID="sess-a"
  export CLAUDE_TRACK_DIR="$REPO"
  echo '{}' | bash "$SCRIPT" --harness claude

  snap="$CHECKS_DIR/sess-a/hash1/snapshot.json"
  [ -f "$snap" ]
  [ "$(jq -r '.session' "$snap")" = "sess-a" ]
  [ "$(jq -r '.dir' "$snap")" = "$REPO" ]
  [ "$(cat "$CHECKS_DIR/sess-a/latest")" = "hash1" ]
}

@test "claude: an unchanged hash on the next turn is a no-op" {
  export CLAUDE_SESSION_ID="sess-a"
  export CLAUDE_TRACK_DIR="$REPO"
  echo '{}' | bash "$SCRIPT" --harness claude
  first_mtime=$(stat -c %Y "$CHECKS_DIR/sess-a/hash1/snapshot.json" 2>/dev/null || stat -f %m "$CHECKS_DIR/sess-a/hash1/snapshot.json")

  sleep 1
  echo '{}' | bash "$SCRIPT" --harness claude
  second_mtime=$(stat -c %Y "$CHECKS_DIR/sess-a/hash1/snapshot.json" 2>/dev/null || stat -f %m "$CHECKS_DIR/sess-a/hash1/snapshot.json")

  [ "$first_mtime" = "$second_mtime" ]
}

@test "claude: a repo not registered in ~/.checks.yml is a no-op" {
  export CLAUDE_SESSION_ID="sess-a"
  export CLAUDE_TRACK_DIR="$REPO"
  export STUB_REGISTERED_EXIT=1
  echo '{}' | bash "$SCRIPT" --harness claude
  [ -z "$(ls "$CHECKS_DIR")" ]
}

@test "cursor: resolves session_id from conversation_id and dir from workspace_roots" {
  payload=$(jq -n --arg root "$REPO" '{conversation_id:"conv-a", workspace_roots:[$root]}')
  echo "$payload" | bash "$SCRIPT" --harness cursor

  snap="$CHECKS_DIR/conv-a/hash1/snapshot.json"
  [ -f "$snap" ]
  [ "$(jq -r '.session' "$snap")" = "conv-a" ]
  [ "$(jq -r '.dir' "$snap")" = "$REPO" ]
}

@test "cursor: missing conversation_id is a no-op" {
  payload=$(jq -n --arg root "$REPO" '{workspace_roots:[$root]}')
  echo "$payload" | bash "$SCRIPT" --harness cursor
  [ -z "$(ls "$CHECKS_DIR")" ]
}
