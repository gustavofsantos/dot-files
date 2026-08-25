#!/usr/bin/env bats

PLUGIN="$BATS_TEST_DIRNAME/../config/nvim/after/plugin/review.lua"

setup() {
  TEST_ROOT=$(mktemp -d)
  CAPTURE="$TEST_ROOT/review-args"
  REVIEW_STUB="$TEST_ROOT/review"
  export CAPTURE

  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@" >"$CAPTURE"' \
    'printf "rv1\n"' >"$REVIEW_STUB"
  chmod +x "$REVIEW_STUB"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "Neovim submits an optional review without changing review-comment entry" {
  run env REVIEW_CMD="$REVIEW_STUB" NVIM_LOG_FILE="$TEST_ROOT/nvim.log" nvim --headless -u NONE \
    -c "source $PLUGIN" \
    -c "if exists(':ReviewAdd') != 2 | cquit 11 | endif" \
    -c "ReviewSubmit request-changes" \
    -c "lua vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Overall summary.' })" \
    -c "lua vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-s>', true, false, true), 'x', false)" \
    -c "lua vim.wait(1000, function() return vim.fn.filereadable('$CAPTURE') == 1 end)" \
    -c "qa!"
  [ "$status" -eq 0 ]
  [ "$(<"$CAPTURE")" = "$(printf '%s\n' \
    submit \
    --decision \
    request-changes \
    --summary \
    "Overall summary." \
    --format \
    ids)" ]
}
