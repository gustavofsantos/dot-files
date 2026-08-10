#!/usr/bin/env bats

# Tests for bin/hooks-change-point-gate
#
# PreToolUse gate: blocks an edit to an existing, untested file until it's
# characterized. --check mode is a manual debug CLI, harness-independent
# (no stdin payload); hook mode now requires --harness claude explicitly.

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-change-point-gate"

setup() {
  REPO=$(mktemp -d)
  git -C "$REPO" init -q
  mkdir -p "$REPO/.claude" "$REPO/src" "$REPO/tests"
  cat > "$REPO/.claude/legacy.json" <<'EOF'
{"gate":"on","testPathPattern":"(^|/)tests/","runTests":"pytest"}
EOF
  echo "def foo(): pass" > "$REPO/src/foo.py"
  git -C "$REPO" add -A
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q -m init
}

teardown() {
  rm -rf "$REPO"
}

payload() {
  local file="$1"
  jq -n --arg cwd "$REPO" --arg file "$file" '{cwd: $cwd, tool_input: {file_path: $file}}'
}

@test "--harness is required in hook mode" {
  run bash "$SCRIPT" <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness cursor <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -ne 0 ]
}

@test "--check mode needs no --harness" {
  run bash "$SCRIPT" --check "$REPO/src/foo.py"
  [ "$status" -eq 0 ]
}

@test "--version needs no --harness" {
  run bash "$SCRIPT" --version
  [ "$status" -eq 0 ]
}

@test "an untested file with no test evidence is denied" {
  run bash "$SCRIPT" --harness claude <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
}

@test "a file with a co-changed or naming test is allowed" {
  echo "def test_foo(): pass" > "$REPO/tests/test_foo.py"
  git -C "$REPO" add -A
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q -m "add test"

  run bash "$SCRIPT" --harness claude <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision": "allow"'* ]]
}

@test "editing a test file itself is allowed (no gate output at all)" {
  run bash "$SCRIPT" --harness claude <<< "$(payload "$REPO/tests/test_foo.py")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a repo with no .claude/legacy.json defers silently (no output)" {
  rm "$REPO/.claude/legacy.json"
  run bash "$SCRIPT" --harness claude <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "gate:off in config defers silently" {
  cat > "$REPO/.claude/legacy.json" <<'EOF'
{"gate":"off","testPathPattern":"(^|/)tests/","runTests":"pytest"}
EOF
  run bash "$SCRIPT" --harness claude <<< "$(payload "$REPO/src/foo.py")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
