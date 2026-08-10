#!/usr/bin/env bats

# Tests for agents/hooks/gitbutler-git
#
# PreToolUse(Bash) hook: denies raw git write commands in GitButler-managed
# repos (a repo with .git/gitbutler/). Read-only git and non-GitButler repos
# pass untouched.

SCRIPT="$BATS_TEST_DIRNAME/../agents/hooks/gitbutler-git"

setup() {
  REPO=$(mktemp -d)
  git -C "$REPO" init -q
}

teardown() {
  rm -rf "$REPO"
}

mark_gitbutler() { mkdir -p "$REPO/.git/gitbutler"; }

payload() {
  local cmd="$1"
  jq -n --arg cwd "$REPO" --arg cmd "$cmd" '{cwd: $cwd, tool_input: {command: $cmd}}'
}

@test "--harness is required" {
  run bash "$SCRIPT" <<< "$(payload "git commit -m x")"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness cursor <<< "$(payload "git commit -m x")"
  [ "$status" -ne 0 ]
}

@test "a write command in a non-GitButler repo is allowed" {
  run bash "$SCRIPT" --harness claude <<< "$(payload "git commit -m x")"
  [ "$status" -eq 0 ]
}

@test "a raw git commit in a GitButler repo is denied" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload "git commit -m x")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"GitButler management"* ]]
}

@test "a raw git push in a GitButler repo is denied" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload "git push origin main")"
  [ "$status" -eq 2 ]
}

@test "read-only git status in a GitButler repo is allowed" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload "git status")"
  [ "$status" -eq 0 ]
}

@test "read-only git log in a GitButler repo is allowed" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload "git log --oneline")"
  [ "$status" -eq 0 ]
}

@test "mutations via the but CLI (not raw git) are allowed" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload "but commit branch-1 -m x")"
  [ "$status" -eq 0 ]
}

@test "a non-Bash-command payload is allowed" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< '{"cwd":"'"$REPO"'"}'
  [ "$status" -eq 0 ]
}
