#!/usr/bin/env bats

# Tests for .claude/skills/spike/scripts/new.sh
#
# Isolation strategy:
#   HOME → fresh tmpdir, so ~/engineering is built per-test and never touched
#          on the real machine.

SCRIPT="$BATS_TEST_DIRNAME/../.claude/skills/spike/scripts/new.sh"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  TODAY=$(date +%F)
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ── The promise ────────────────────────────────────────────────────────────────

@test "a spike is named by the date it was created, like every other vault file" {
  run bash "$SCRIPT" "fee-rounding-drift"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/spikes/${TODAY}-fee-rounding-drift.md" ]
  [ -f "$output" ]
}

@test "naming a spike never depends on what the issues folder contains" {
  mkdir -p "$HOME/engineering/issues" "$HOME/engineering/issues/done"
  : > "$HOME/engineering/issues/007-legacy-ledger.md"
  : > "$HOME/engineering/issues/done/042-settlement-retry.md"

  run bash "$SCRIPT" "fee-rounding-drift"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/spikes/${TODAY}-fee-rounding-drift.md" ]
}

@test "a spike carries no knowledge of the issue that prompted it" {
  run bash "$SCRIPT" "fee-rounding-drift" "2026-08-04-extract-ledger-projection"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/spikes/${TODAY}-fee-rounding-drift.md" ]
  ! grep -q "extract-ledger-projection" "$output"
}

# ── Guards ─────────────────────────────────────────────────────────────────────

@test "re-running for the same unknown returns the same file and keeps its content" {
  first=$(bash "$SCRIPT" "fee-rounding-drift")
  printf '\n## Answer\nRounding happens twice.\n' >> "$first"

  second=$(bash "$SCRIPT" "fee-rounding-drift")
  [ "$second" = "$first" ]
  grep -q "Rounding happens twice." "$first"
}

@test "a new spike is seeded with resolvable status and its creation date" {
  f=$(bash "$SCRIPT" "fee-rounding-drift")
  grep -q "^status: resolved$" "$f"
  grep -q "^created: ${TODAY}$" "$f"
}

@test "the spikes folder is created on first use" {
  [ ! -d "$HOME/engineering/spikes" ]
  bash "$SCRIPT" "fee-rounding-drift"
  [ -d "$HOME/engineering/spikes" ]
}

@test "a missing slug is refused rather than creating a nameless spike" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [ ! -e "$HOME/engineering/spikes/${TODAY}-.md" ]
}
