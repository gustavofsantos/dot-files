#!/usr/bin/env bats

# Tests for bin/git-add-worktree, git-checkout-worktree and git-remove-worktree.

BIN="$BATS_TEST_DIRNAME/../bin"

setup() {
  FAKE_HOME=$(cd "$(mktemp -d)" && pwd -P)
  export HOME="$FAKE_HOME"
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  export PATH="$BIN:$PATH"
  unset WORKTREES_HOME
  REPO="$HOME/Projects/app"
  git init -q -b main "$REPO"
  git -C "$REPO" commit -q --allow-empty -m init
  cd "$REPO"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

@test "creates a new branch from HEAD under ~/.worktrees/<project>/" {
  run git-add-worktree feat/login

  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "$HOME/.worktrees/app/feat-login" ]
  [ "$(git -C "$HOME/.worktrees/app/feat-login" branch --show-current)" = "feat/login" ]
}

@test "creates the branch from the given base" {
  git branch develop
  git -C "$REPO" commit -q --allow-empty -m "only on main"

  run git-add-worktree feat develop

  [ "$status" -eq 0 ]
  [ "$(git rev-parse feat)" = "$(git rev-parse develop)" ]
}

@test "checks out an existing local branch" {
  git branch existing

  run git-add-worktree existing

  [ "$status" -eq 0 ]
  [ "$(git -C "$HOME/.worktrees/app/existing" branch --show-current)" = "existing" ]
}

@test "tracks origin/<branch> when only the remote has it" {
  git clone -q "$REPO" "$HOME/Projects/clone"
  git branch remote-only
  cd "$HOME/Projects/clone"
  git fetch -q origin

  run git-add-worktree remote-only

  [ "$status" -eq 0 ]
  [ "$(git rev-parse --abbrev-ref remote-only@{upstream})" = "origin/remote-only" ]
  [ -d "$HOME/.worktrees/clone/remote-only" ]
}

@test "prints the existing worktree when the branch is already checked out" {
  git-add-worktree feat >/dev/null 2>&1

  run git-add-worktree feat

  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.worktrees/app/feat" ]
}

@test "works from inside another worktree, naming the main tree's project" {
  git-add-worktree one >/dev/null 2>&1
  cd "$HOME/.worktrees/app/one"

  run git-add-worktree two

  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "$HOME/.worktrees/app/two" ]
}

@test "honours WORKTREES_HOME and symlinks untracked agent config" {
  export WORKTREES_HOME="$HOME/wt"
  mkdir "$REPO/.claude"
  touch "$REPO/CLAUDE.local.md"

  run git-add-worktree feat

  [ "$status" -eq 0 ]
  [ -L "$HOME/wt/app/feat/.claude" ]
  [ -L "$HOME/wt/app/feat/CLAUDE.local.md" ]
}

@test "rejects missing or extra arguments" {
  run git-add-worktree
  [ "$status" -eq 1 ]
  run git-add-worktree a b c
  [ "$status" -eq 1 ]
}

@test "git-checkout-worktree delegates to git-add-worktree" {
  run git-checkout-worktree feat

  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "$HOME/.worktrees/app/feat" ]
}

@test "git-remove-worktree removes the worktree by branch, keeps the branch" {
  mkdir "$REPO/.claude"
  git-add-worktree feat >/dev/null 2>&1

  run git-remove-worktree feat

  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.worktrees/app" ]
  git show-ref --verify --quiet refs/heads/feat
}

@test "git-remove-worktree refuses the main tree and unknown branches" {
  run git-remove-worktree main
  [ "$status" -eq 1 ]
  run git-remove-worktree nope
  [ "$status" -eq 1 ]
}
