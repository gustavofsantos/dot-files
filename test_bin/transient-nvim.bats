#!/usr/bin/env bats

# config/nvim/lua/transient runs its own headless Lua suites; this wires them into bats.

TESTS="$BATS_TEST_DIRNAME/../config/nvim/tests/transient"

run_suite() {
  run env NVIM_LOG_FILE="$BATS_TEST_TMPDIR/nvim.log" timeout 60 nvim --headless -u NONE -l "$TESTS/$1_test.lua"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "transient engine: stack, exit order, loop vs close, unmapped, wrong-node errors" {
  run_suite engine
}

@test "transient modes: triggers per mode, ctx.mode, visual selection, operator-pending" {
  run_suite modes
}

@test "transient layout: pure column fitting, truncation, highlight groups" {
  run_suite layout
}

@test "transient strip: window opens, updates in place, closes on every exit path" {
  run_suite strip
}

@test "cursorized defines every Transient group readably" {
  run_suite colors
}
