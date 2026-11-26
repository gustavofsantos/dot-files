#!/usr/bin/env bats

# Tests for bin/tmux-dim-panes against a real, throwaway tmux server.

BIN="$BATS_TEST_DIRNAME/../bin"

setup() {
  command -v tmux >/dev/null || skip "tmux not installed"
  FAKE=$(cd "$(mktemp -d)" && pwd -P)
  export TMUX_TMPDIR="$FAKE"
  unset TMUX
  # No desktop to ask: the theme is chosen by the options in each test.
  mkdir -p "$FAKE/stubs"
  printf '#!/bin/sh\nexit 1\n' > "$FAKE/stubs/gsettings"
  printf '#!/bin/sh\nexit 1\n' > "$FAKE/stubs/defaults"
  chmod +x "$FAKE/stubs/"*
  export PATH="$BIN:$FAKE/stubs:$PATH"
  tmux -f /dev/null new-session -d -s t
}

teardown() {
  tmux kill-server 2>/dev/null || true
  rm -rf "$FAKE"
}

style() { tmux show-options -gv "$1"; }

@test "blend moves fg toward bg by the percent" {
  run tmux-dim-panes blend '#ffffff' '#000000' 30
  [ "$status" -eq 0 ]
  [ "$output" = "#b3b3b3" ]
  run tmux-dim-panes blend '#d2cfc5' '#1a1918' 0
  [ "$output" = "#d2cfc5" ]
  run tmux-dim-panes blend '#d2cfc5' '#1a1918' 100
  [ "$output" = "#1a1918" ]
}

@test "blend rejects bad input" {
  run tmux-dim-panes blend 'red' '#000000' 30
  [ "$status" -eq 2 ]
  run tmux-dim-panes blend '#ffffff' '#000000' 130
  [ "$status" -eq 2 ]
}

@test "apply dims inactive panes 30% by default and keeps the active pane at the terminal color" {
  tmux set -g @dim-inactive-theme dark
  run tmux-dim-panes apply
  [ "$status" -eq 0 ]
  [ "$(style window-style)" = "fg=#9b9891" ]
  [ "$(style window-active-style)" = "fg=terminal" ]
}

@test "amount and colors are configurable" {
  tmux set -g @dim-inactive-theme light
  tmux set -g @dim-inactive-amount 50
  tmux set -g @dim-inactive-light-fg '#000000'
  tmux set -g @dim-inactive-light-bg '#ffffff'
  tmux-dim-panes apply
  [ "$(style window-style)" = "fg=#808080" ]
}

@test "auto theme falls back to dark with no client or desktop to ask" {
  tmux-dim-panes apply
  [ "$(style window-style)" = "fg=#9b9891" ]
}

@test "toggle turns dimming off and back on" {
  tmux set -g @dim-inactive-theme dark
  tmux-dim-panes apply
  tmux-dim-panes toggle
  [ "$(tmux show -gv @dim-inactive)" = off ]
  [ "$(style window-style)" = "default" ]
  [ "$(style window-active-style)" = "default" ]
  tmux-dim-panes toggle
  [ "$(style window-style)" = "fg=#9b9891" ]
}

@test "init installs re-apply hooks once, however often it runs" {
  tmux-dim-panes init
  tmux-dim-panes init
  run tmux show-hooks -g client-focus-in
  [ "$(printf '%s\n' "$output" | grep -c 'tmux-dim-panes apply')" -eq 1 ]
  run tmux show-hooks -g client-attached
  [[ "$output" == *"tmux-dim-panes apply"* ]]
}

@test "a bad theme is reported" {
  tmux set -g @dim-inactive-theme sepia
  run tmux-dim-panes apply
  [ "$status" -eq 2 ]
  [[ "$output" == *"auto, light or dark"* ]]
}
