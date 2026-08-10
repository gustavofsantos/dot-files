#!/usr/bin/env bats

# Tests for bin/facts-churn.
#
# Run: bats test_bin/facts-churn.bats

SCRIPT="$BATS_TEST_DIRNAME/../bin/facts-churn"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  unset ENGINEERING_HOME
  unset ENGINEERING_DIR
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ── The vault location is configuration, not a constant ────────────────────────

seed_vault() {
  local root="$1"
  mkdir -p "$root/facts" "$root/.metadata"
  echo '{}' > "$root/.metadata/sources.local.json"
  printf -- '---\ntitle: ledger grain\n---\n' > "$root/facts/FACT-001-ledger-grain.md"
}

@test "facts are read from the vault the machine declares" {
  export ENGINEERING_HOME="$TEST_HOME/notes"
  seed_vault "$ENGINEERING_HOME"

  run "$SCRIPT" --fact 001 --quiet
  [[ "$output" == *"FACT-001-ledger-grain"* ]]
}

@test "the vault has one name, so the retired name no longer redirects the read" {
  export ENGINEERING_DIR="$TEST_HOME/retired"
  seed_vault "$ENGINEERING_DIR"

  run "$SCRIPT" --fact 001 --quiet
  [[ "$output" != *"FACT-001-ledger-grain"* ]]
}

@test "a machine that declares no vault still gets the default one" {
  seed_vault "$HOME/engineering"

  run "$SCRIPT" --fact 001 --quiet
  [[ "$output" == *"FACT-001-ledger-grain"* ]]
}
