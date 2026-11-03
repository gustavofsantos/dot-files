#!/usr/bin/env bats

# Tests for bin/tmux-worktree. gitmaster, fzf and tmux-sessionizer are stubs
# that record how they were called, so the script's own logic is what runs.

BIN="$BATS_TEST_DIRNAME/../bin"

setup() {
  FAKE=$(cd "$(mktemp -d)" && pwd -P)
  export HOME="$FAKE/home"
  mkdir -p "$HOME" "$FAKE/stubs"
  export CALLS="$FAKE/calls"
  : > "$CALLS"
  unset WORKTREES_HOME

  cat > "$FAKE/stubs/gitmaster" <<'STUB'
#!/usr/bin/env bash
echo "gitmaster $* [WORKTREES_HOME=$WORKTREES_HOME]" >> "$CALLS"
all=false; for a in "$@"; do [ "$a" = --all ] && all=true; done
case "$2" in
  branches)
    if $all; then printf 'app\tmain\t/src/app\nbilling\ttopic\t/src/billing\n'
    else printf '%s\n' main feature/login; fi ;;
  list)
    if $all; then printf 'app\tmain\t/src/app\nbilling\ttopic\t/wt/billing/topic\n'
    else printf 'main\t/repo\nfeature/login\t/wt/repo/feature-login\n'; fi ;;
  add) echo "chatter"; echo "/wt/repo/${3//\//-}" ;;
esac
STUB
  # fzf prints $FZF_OUT (with \n escapes) and exits with $FZF_RC (default 0).
  cat > "$FAKE/stubs/fzf" <<'STUB'
#!/usr/bin/env bash
cat > /dev/null
printf '%b' "${FZF_OUT-}"
exit "${FZF_RC:-0}"
STUB
  cat > "$FAKE/stubs/tmux-sessionizer" <<'STUB'
#!/usr/bin/env bash
echo "sessionizer $*" >> "$CALLS"
STUB
  chmod +x "$FAKE"/stubs/*
  export PATH="$FAKE/stubs:$BIN:$PATH"
}

teardown() {
  rm -rf "$FAKE"
}

@test "a branch given as an argument is added and its worktree entered" {
  run tmux-worktree feature/login

  [ "$status" -eq 0 ]
  grep -qx "gitmaster worktree add feature/login \[WORKTREES_HOME=$HOME/.worktrees\]" "$CALLS"
  grep -qx "sessionizer /wt/repo/feature-login" "$CALLS"
}

@test "WORKTREES_HOME is kept when set" {
  WORKTREES_HOME=/custom run tmux-worktree x

  [ "$status" -eq 0 ]
  grep -q "WORKTREES_HOME=/custom\]" "$CALLS"
}

@test "the picker chooses among every branch and enters the highlighted one" {
  FZF_OUT='fea\nfeature/login\n' run tmux-worktree

  [ "$status" -eq 0 ]
  grep -qx "gitmaster worktree branches \[WORKTREES_HOME=$HOME/.worktrees\]" "$CALLS"
  grep -qx "sessionizer /wt/repo/feature-login" "$CALLS"
}

@test "a typed name that matches nothing starts a new branch" {
  FZF_OUT='brand-new\n' FZF_RC=1 run tmux-worktree

  [ "$status" -eq 0 ]
  grep -q "worktree add brand-new" "$CALLS"
  grep -qx "sessionizer /wt/repo/brand-new" "$CALLS"
}

@test "Esc in the picker does nothing" {
  FZF_OUT='typed\n' FZF_RC=130 run tmux-worktree

  [ "$status" -eq 0 ]
  ! grep -q "worktree add" "$CALLS"
  ! grep -q sessionizer "$CALLS"
}

@test "--existing enters the path of the chosen worktree and adds nothing" {
  FZF_OUT='feature/login\t/wt/repo/feature-login\n' run tmux-worktree --existing

  [ "$status" -eq 0 ]
  grep -q "worktree list --format tsv" "$CALLS"
  ! grep -q "worktree add" "$CALLS"
  grep -qx "sessionizer /wt/repo/feature-login" "$CALLS"
}

@test "fails clearly without gitmaster" {
  rm "$FAKE/stubs/gitmaster"

  PATH="$FAKE/stubs:$BIN:/usr/bin:/bin" run tmux-worktree x

  [ "$status" -eq 1 ]
  [[ "$output" == *"gitmaster is not on PATH"* ]]
}

@test "--all picks a branch of any project and adds it in that repo" {
  FZF_OUT='billing\ttopic\t/src/billing\n' run tmux-worktree --all

  [ "$status" -eq 0 ]
  grep -q "worktree branches --all" "$CALLS"
  grep -q "worktree add topic --repo /src/billing" "$CALLS"
  grep -qx "sessionizer /wt/repo/topic" "$CALLS"
}

@test "--all --existing enters the path of the chosen worktree" {
  FZF_OUT='billing\ttopic\t/wt/billing/topic\n' run tmux-worktree --all --existing

  [ "$status" -eq 0 ]
  grep -q "worktree list --all --format tsv" "$CALLS"
  ! grep -q "worktree add" "$CALLS"
  grep -qx "sessionizer /wt/billing/topic" "$CALLS"
}

@test "an unknown option is a usage error" {
  run tmux-worktree --bogus

  [ "$status" -eq 2 ]
  [[ "$output" == *usage* ]]
}
