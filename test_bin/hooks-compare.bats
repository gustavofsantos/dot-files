#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-compare"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export HOOKS_COMPARE_DIR="$TEST_HOME/state"
  REPO="$TEST_HOME/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  printf 'before\n' >"$REPO/tracked.txt"
  git -C "$REPO" add tracked.txt
  git -C "$REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
  PAYLOAD=$(jq -nc --arg cwd "$REPO" '{session_id:"session-1",cwd:$cwd}')
  unset AGENT
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "unset AGENT is a silent pass-through" {
  run env -u AGENT "$SCRIPT" capture <<<"$PAYLOAD"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -e "$HOOKS_COMPARE_DIR" ]
}

@test "capture and release report tracked and untracked changes" {
  AGENT=claude "$SCRIPT" capture <<<"$PAYLOAD"
  printf 'after\n' >"$REPO/tracked.txt"
  printf 'new\n' >"$REPO/untracked.txt"

  run env AGENT=claude "$SCRIPT" release <<<"$PAYLOAD"

  [ "$status" -eq 0 ]
  jq -e '.systemMessage | contains("tracked.txt") and contains("untracked.txt")' <<<"$output"
}

@test "release is silent when the worktree has not changed" {
  AGENT=cursor "$SCRIPT" capture <<<"$PAYLOAD"

  run env AGENT=cursor "$SCRIPT" release <<<"$PAYLOAD"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cursor stop can release without a conversation id in its payload" {
  AGENT=cursor "$SCRIPT" capture <<<"$PAYLOAD"
  printf 'after\n' >"$REPO/tracked.txt"

  run env AGENT=cursor CURSOR_PROJECT_DIR="$REPO" "$SCRIPT" release <<<'{"status":"completed","loop_count":1}'

  [ "$status" -eq 0 ]
  jq -e '.additional_context | contains("tracked.txt")' <<<"$output"
}

@test "--files pipes one changed path per line to validation" {
  AGENT=cursor "$SCRIPT" capture <<<"$PAYLOAD"
  printf 'after\n' >"$REPO/tracked.txt"
  validator="$TEST_HOME/validator"
  cat >"$validator" <<'EOF'
#!/usr/bin/env bash
cat >"$HOME/validated-files"
printf 'lint failed\n' >&2
exit 7
EOF
  chmod +x "$validator"

  run env AGENT=cursor "$SCRIPT" release --files -- "$validator" <<<"$PAYLOAD"

  [ "$status" -eq 0 ]
  jq -e '.followup_message | contains("Validation failed (exit 7)") and contains("lint failed")' <<<"$output"
  [ "$(cat "$HOME/validated-files")" = tracked.txt ]
}

@test "--diff pipes a unified patch to validation" {
  AGENT=codex "$SCRIPT" capture <<<"$PAYLOAD"
  printf 'after\n' >"$REPO/tracked.txt"
  validator="$TEST_HOME/read-diff"
  cat >"$validator" <<'EOF'
#!/usr/bin/env bash
cat >"$HOME/validated-diff"
EOF
  chmod +x "$validator"

  run env AGENT=codex "$SCRIPT" release --diff -- "$validator" <<<"$PAYLOAD"

  [ "$status" -eq 0 ]
  grep -F -- '--- a/tracked.txt' "$HOME/validated-diff"
  grep -F -- '+++ b/tracked.txt' "$HOME/validated-diff"
}

@test "captures are isolated by session" {
  AGENT=codex "$SCRIPT" capture <<<"$PAYLOAD"
  printf 'after\n' >"$REPO/tracked.txt"
  other=$(jq -nc --arg cwd "$REPO" '{session_id:"session-2",cwd:$cwd}')

  run env AGENT=codex "$SCRIPT" release <<<"$other"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "setup prints definitions for every supported harness" {
  run "$SCRIPT" setup

  [ "$status" -eq 0 ]
  [[ "$output" == *"AGENT=claude hooks-compare capture"* ]]
  [[ "$output" == *"AGENT=cursor hooks-compare capture"* ]]
  [[ "$output" == *"AGENT=codex hooks-compare capture"* ]]
  [[ "$output" == *"hooks-compare release --files -- validate-files"* ]]
}
