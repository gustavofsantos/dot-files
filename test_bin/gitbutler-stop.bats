#!/usr/bin/env bats

# Tests for bin/hooks-gitbutler-stop
#
# Stop hook: blocks turn end with an uncommitted tree in GitButler-managed
# repos (.git/gitbutler/ present), at most once per turn.

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-gitbutler-stop"

setup() {
  REPO=$(mktemp -d)
  git -C "$REPO" init -q
  git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
}

teardown() {
  rm -rf "$REPO"
}

mark_gitbutler() { mkdir -p "$REPO/.git/gitbutler"; }
dirty_tree()     { echo hi > "$REPO/dirty.txt"; }

payload() {
  local stop_hook_active="${1:-false}"
  jq -n --arg cwd "$REPO" --argjson active "$stop_hook_active" \
    '{cwd: $cwd, stop_hook_active: $active}'
}

@test "--harness is required" {
  run bash "$SCRIPT" <<< "$(payload)"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness cursor <<< "$(payload)"
  [ "$status" -ne 0 ]
}

@test "already-continued-once (stop_hook_active) lets the turn end even with a dirty tree" {
  mark_gitbutler
  dirty_tree
  run bash "$SCRIPT" --harness claude <<< "$(payload true)"
  [ "$status" -eq 0 ]
}

@test "a non-GitButler repo with a dirty tree is allowed" {
  dirty_tree
  run bash "$SCRIPT" --harness claude <<< "$(payload)"
  [ "$status" -eq 0 ]
}

@test "a GitButler repo with a clean tree is allowed" {
  mark_gitbutler
  run bash "$SCRIPT" --harness claude <<< "$(payload)"
  [ "$status" -eq 0 ]
}

@test "a GitButler repo with a dirty tree is blocked" {
  mark_gitbutler
  dirty_tree
  run bash "$SCRIPT" --harness claude <<< "$(payload)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"gitbutler-provenance"* ]]
}
