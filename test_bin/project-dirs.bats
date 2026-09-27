#!/usr/bin/env bats

# Tests for bin/project-dirs, the project list shared by tmux-sessionizer and Doom.

SCRIPT="$BATS_TEST_DIRNAME/../bin/project-dirs"

setup() {
  FAKE_HOME=$(mktemp -d)
  export HOME="$FAKE_HOME"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

@test "lists fixed dirs that exist and skips missing ones" {
  mkdir -p "$HOME/.config/nvim" "$HOME/.config/doom"

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/.config/nvim"* ]]
  [[ "$output" == *"$HOME/.config/doom"* ]]
  [[ "$output" != *"$HOME/.config/ghostty"* ]]
}

@test "lists direct children of each parent, not grandchildren or files" {
  mkdir -p "$HOME/Projects/rvw" \
           "$HOME/Workplace/api/src" \
           "$HOME/Workplace/seubarriga-worktrees/feat.x" \
           "$HOME/Workplace/backend-services/applications/billing"
  touch "$HOME/Workplace/notes.txt"

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/Projects/rvw"* ]]
  [[ "$output" == *"$HOME/Workplace/api"* ]]
  [[ "$output" == *"$HOME/Workplace/seubarriga-worktrees/feat.x"* ]]
  [[ "$output" == *"$HOME/Workplace/backend-services/applications/billing"* ]]
  [[ "$output" != *"$HOME/Workplace/api/src"* ]]
  [[ "$output" != *"notes.txt"* ]]
}

@test "succeeds with no project dirs at all" {
  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
