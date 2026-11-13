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
all=false; for a in "$@"; do [ "$a" = --repos-from ] && all=true; done
[ "$all" = true ] && cat > /dev/null
case "$2" in
  branches) printf '%s\n' main feature/login ;;
  list)
    if $all; then printf 'app\tmain\t/src/app\nbilling\ttopic\t/wt/billing/topic\n'
    else printf 'main\t/repo\nfeature/login\t/wt/repo/feature-login\n'; fi ;;
  add) echo "chatter"; echo "/wt/repo/${3//\//-}" ;;
esac
STUB
  # fzf prints $FZF_OUT (with \n escapes) and exits with $FZF_RC (default 0).
  # The Nth call prints $FZF_OUT<N> and exits $FZF_RC<N> (the first call also
  # reads the unsuffixed names), and records its arguments and input.
  cat > "$FAKE/stubs/fzf" <<'STUB'
#!/usr/bin/env bash
n=$(( $(cat "$CALLS.fzf" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$CALLS.fzf"
echo "fzf#$n $*" >> "$CALLS"
sed "s/^/fzf#$n< /" >> "$CALLS"
out="FZF_OUT$n"; rc="FZF_RC$n"
[ "$n" = 1 ] && { out=FZF_OUT; rc=FZF_RC; }
printf '%b' "${!out-}"
exit "${!rc:-0}"
STUB
  # Real repos for --all, which reads refs with git itself: app has main;
  # billing has main and topic, and origin has topic (also local), old
  # (remote only) and HEAD. A worktree of billing is listed too, as
  # project-dirs does.
  for r in app billing; do
    git init -q -b main "$FAKE/src/$r"
    git -C "$FAKE/src/$r" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  done
  git -C "$FAKE/src/billing" branch topic
  for ref in topic old HEAD; do
    git -C "$FAKE/src/billing" update-ref "refs/remotes/origin/$ref" main
  done
  git -C "$FAKE/src/billing" worktree add -q "$FAKE/wt/billing/topic" topic
  cat > "$FAKE/stubs/project-dirs" <<STUB
#!/usr/bin/env bash
printf '%s\\n' "$FAKE/src/app" "$FAKE/src/billing" "$FAKE/wt/billing/topic" "$FAKE/not-a-repo"
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
  FZF_OUT="bil top\nbilling\ttopic\t$FAKE/src/billing\n" run tmux-worktree --all

  [ "$status" -eq 0 ]
  ! grep -q "worktree branches" "$CALLS"
  grep -q "worktree add topic --repo $FAKE/src/billing" "$CALLS"
  grep -qx "sessionizer /wt/repo/topic" "$CALLS"
}

@test "--all --existing enters the path of the chosen worktree" {
  FZF_OUT='billing\ttopic\t/wt/billing/topic\n' run tmux-worktree --all --existing

  [ "$status" -eq 0 ]
  grep -q "worktree list --repos-from - --format tsv" "$CALLS"
  ! grep -q "worktree add" "$CALLS"
  grep -qx "sessionizer /wt/billing/topic" "$CALLS"
}

@test "an unknown option is a usage error" {
  run tmux-worktree --bogus

  [ "$status" -eq 2 ]
  [[ "$output" == *usage* ]]
}


@test "--all with text that matches nothing starts the branch in the repo the other words pick" {
  FZF_OUT='bil feat/x\n' FZF_RC=1 FZF_OUT2="billing\t$FAKE/src/billing\n" run tmux-worktree --all

  [ "$status" -eq 0 ]
  grep -q "^fzf#2 .*--prompt=new branch feat/x in → .*--select-1 .*--query bil$" "$CALLS"
  grep -qxF "fzf#2< app	$FAKE/src/app" "$CALLS"
  grep -qxF "fzf#2< billing	$FAKE/src/billing" "$CALLS"
  grep -q "worktree add feat/x --repo $FAKE/src/billing" "$CALLS"
  grep -qx "sessionizer /wt/repo/feat-x" "$CALLS"
}

@test "--all with one unmatched word asks for the repo with an empty filter" {
  FZF_OUT='feat/x\n' FZF_RC=1 FZF_OUT2="app\t$FAKE/src/app\n" run tmux-worktree --all

  [ "$status" -eq 0 ]
  grep -q "^fzf#2 .*--query $" "$CALLS"
  grep -q "worktree add feat/x --repo $FAKE/src/app" "$CALLS"
}

@test "--all with alt-enter (query only, status 0) starts a new branch even if text matched" {
  FZF_OUT='billing topic2\n' FZF_OUT2="billing\t$FAKE/src/billing\n" run tmux-worktree --all

  [ "$status" -eq 0 ]
  grep -q "worktree add topic2 --repo $FAKE/src/billing" "$CALLS"
}

@test "--all does nothing when the repo picker is cancelled" {
  FZF_OUT='feat/x\n' FZF_RC=1 FZF_RC2=130 run tmux-worktree --all

  [ "$status" -eq 0 ]
  ! grep -q "worktree add" "$CALLS"
  ! grep -q sessionizer "$CALLS"
}

@test "--all does nothing on Esc or an empty query" {
  FZF_RC=130 run tmux-worktree --all
  [ "$status" -eq 0 ]
  FZF_OUT='\n' FZF_RC=1 run tmux-worktree --all
  [ "$status" -eq 0 ]
  ! grep -q "worktree add" "$CALLS"
}

@test "--all lists local and origin-only branches of each repo once, without HEAD" {
  FZF_RC=130 run tmux-worktree --all

  [ "$status" -eq 0 ]
  diff <(grep "^fzf#1< " "$CALLS") - <<LIST
fzf#1< app	main	$FAKE/src/app
fzf#1< billing	main	$FAKE/src/billing
fzf#1< billing	topic	$FAKE/src/billing
fzf#1< billing	old	$FAKE/src/billing
LIST
}
