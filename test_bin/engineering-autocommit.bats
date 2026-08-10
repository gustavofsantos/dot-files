#!/usr/bin/env bats

# Tests for agents/hooks/engineering-autocommit
#
# Harness-agnostic in behavior (always commits the same fixed vault path);
# --harness only changes which stdin field is read for the session id shown
# in the (cosmetic) commit message body.

SCRIPT="$BATS_TEST_DIRNAME/../agents/hooks/engineering-autocommit"

setup() {
  ENG_DIR=$(mktemp -d)
  export ENGINEERING_HOME="$ENG_DIR"
  git -C "$ENG_DIR" init -q
  git -C "$ENG_DIR" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
}

teardown() {
  rm -rf "$ENG_DIR"
}

@test "--harness is required" {
  run bash -c "echo '{}' | '$SCRIPT'"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash -c "echo '{}' | '$SCRIPT' --harness windsurf"
  [ "$status" -ne 0 ]
}

@test "a clean vault tree is a no-op (no new commit)" {
  before=$(git -C "$ENG_DIR" rev-parse HEAD)
  echo '{}' | bash "$SCRIPT" --harness claude
  after=$(git -C "$ENG_DIR" rev-parse HEAD)
  [ "$before" = "$after" ]
}

@test "a dirty vault tree is committed" {
  echo hi > "$ENG_DIR/note.md"
  echo '{}' | bash "$SCRIPT" --harness claude
  [ -z "$(git -C "$ENG_DIR" status --porcelain)" ]
}

@test "claude: commit message includes the session_id field" {
  echo hi > "$ENG_DIR/note.md"
  echo '{"session_id":"sess-abc"}' | bash "$SCRIPT" --harness claude
  git -C "$ENG_DIR" log -1 --format=%B | grep -q "session sess-abc"
}

@test "cursor: commit message includes the conversation_id field" {
  echo hi > "$ENG_DIR/note.md"
  echo '{"conversation_id":"conv-xyz"}' | bash "$SCRIPT" --harness cursor
  git -C "$ENG_DIR" log -1 --format=%B | grep -q "session conv-xyz"
}

@test "not yet a git repo is a no-op, not an error" {
  rm -rf "$ENG_DIR"
  mkdir -p "$ENG_DIR"
  run bash -c "echo '{}' | '$SCRIPT' --harness claude"
  [ "$status" -eq 0 ]
}

@test "a held lock causes the hook to bail without committing" {
  echo hi > "$ENG_DIR/note.md"
  mkdir -p "$ENG_DIR/.git/engineering-autocommit.lock"
  before=$(git -C "$ENG_DIR" rev-parse HEAD)
  run bash -c "echo '{}' | '$SCRIPT' --harness claude"
  after=$(git -C "$ENG_DIR" rev-parse HEAD)
  [ "$status" -eq 0 ]
  [ "$before" = "$after" ]
}
