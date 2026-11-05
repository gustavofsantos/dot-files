#!/usr/bin/env bats

# Tests for config/nvim/shims/mmdc (mmdc-compatible flags → bin/pele).

SHIM="$BATS_TEST_DIRNAME/../config/nvim/shims/mmdc"

setup() {
  command -v bun >/dev/null || skip "bun not installed"
  WORK=$(mktemp -d)
  export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  printf 'flowchart LR\n A-->B\n' > "$WORK/d.mmd"
}

teardown() {
  rm -rf "$WORK"
}

@test "snacks' argument shape produces a png" {
  run "$SHIM" -i "$WORK/d.mmd" -o "$WORK/d.png" -b transparent -t dark -s 1
  [ "$status" -eq 0 ]
  [ "$(head -c 4 "$WORK/d.png" | tail -c 3)" = "PNG" ]
}

@test "the neutral theme maps to light" {
  run "$SHIM" -i "$WORK/d.mmd" -o "$WORK/n.png" -b transparent -t neutral -s 1
  [ "$status" -eq 0 ]
}

@test "an invalid diagram fails" {
  echo 'nonsense' > "$WORK/bad.mmd"
  run "$SHIM" -i "$WORK/bad.mmd" -o "$WORK/bad.png"
  [ "$status" -eq 1 ]
}

@test "unknown flags are rejected" {
  run "$SHIM" -i "$WORK/d.mmd" -o "$WORK/x.png" --puppeteerConfigFile x
  [ "$status" -eq 2 ]
}
