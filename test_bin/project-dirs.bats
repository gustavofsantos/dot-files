#!/usr/bin/env bats

# Tests for bin/project-dirs, the project list shared by tmux-sessionizer and Doom.

SCRIPT="$BATS_TEST_DIRNAME/../bin/project-dirs"

setup() {
  FAKE_HOME=$(cd "$(mktemp -d)" && pwd -P)
  export HOME="$FAKE_HOME"
  export GIT_CONFIG_GLOBAL=/dev/null
  unset PROJECTS_FILE
}

teardown() {
  rm -rf "$FAKE_HOME"
}

make_repo() {
  git init -q -b main "$1"
  git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

@test "lists the dirs in ~/.projects, skipping missing ones, comments and blanks" {
  mkdir -p "$HOME/dot-files" "$HOME/Projects/rvw"
  cat > "$HOME/.projects" <<EOF
# my projects
~/dot-files

$HOME/Projects/rvw   # trailing comment
~/missing
EOF

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/dot-files
$HOME/Projects/rvw" ]
}

@test "expands globs to the directories they match" {
  mkdir -p "$HOME/Workplace/api/src" "$HOME/Workplace/web"
  touch "$HOME/Workplace/notes.txt"
  echo '~/Workplace/*' > "$HOME/.projects"

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/Workplace/api"* ]]
  [[ "$output" == *"$HOME/Workplace/web"* ]]
  [[ "$output" != *"src"* ]]
  [[ "$output" != *"notes.txt"* ]]
}

@test "follows each git project with its linked worktrees" {
  make_repo "$HOME/Projects/app"
  git -C "$HOME/Projects/app" worktree add -q -b feat "$HOME/.worktrees/app/feat"
  mkdir -p "$HOME/other"
  printf '~/Projects/app\n~/other\n' > "$HOME/.projects"

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/Projects/app
$HOME/.worktrees/app/feat
$HOME/other" ]
}

@test "honours PROJECTS_FILE" {
  mkdir -p "$HOME/a"
  echo "$HOME/a" > "$HOME/list"
  export PROJECTS_FILE="$HOME/list"

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/a" ]
}

@test "succeeds with no ~/.projects at all" {
  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
