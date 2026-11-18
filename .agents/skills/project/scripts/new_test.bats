#!/usr/bin/env bats

# Tests for new.sh, alongside it.
#
# Run: bats agents/skills/project/scripts/new_test.bats
#
# Isolation strategy:
#   HOME → fresh tmpdir, so ~/engineering is built per-test and the real vault
#          is never touched.

SCRIPT="$BATS_TEST_DIRNAME/new.sh"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  unset ENGINEERING_HOME
  SLUG="accounting-divergences"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ── Storage ────────────────────────────────────────────────────────────────────

@test "a project is stored under its own slug" {
  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/projects/${SLUG}.md" ]
  [ -f "$output" ]
}

@test "a project keeps its name when the calendar moves on" {
  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [[ "$output" != *"$(date +%F)"* ]]
}

@test "the projects folder is created on first use" {
  [ ! -d "$HOME/engineering/projects" ]
  "$SCRIPT" "$SLUG"
  [ -d "$HOME/engineering/projects" ]
}

@test "closing a project cannot rename the brief to done" {
  f=$("$SCRIPT" "$SLUG")
  [ -d "$HOME/engineering/projects/done" ]

  mv "$f" "$HOME/engineering/projects/done"
  [ -f "$HOME/engineering/projects/done/${SLUG}.md" ]
}

# ── The brief ──────────────────────────────────────────────────────────────────

@test "a new brief carries every section an agent reads cold" {
  f=$("$SCRIPT" "$SLUG")
  grep -q '^## Objective$'          "$f"
  grep -q '^## Glossary$'           "$f"
  grep -q '^## Workflow context$'   "$f"
  grep -q '^## Data map$'           "$f"
  grep -q '^## Standing questions$' "$f"
  grep -q '^## Key artifacts$'      "$f"
}

@test "a brief keeps no list of its issues" {
  f=$("$SCRIPT" "$SLUG")
  ! grep -qiE '^## (Issues|Members|Tasks)' "$f"
}

@test "a new brief records the date it was opened" {
  f=$("$SCRIPT" "$SLUG")
  grep -q "^created: $(date +%F)$" "$f"
}

# ── Guards ─────────────────────────────────────────────────────────────────────

@test "re-opening a project keeps what was written in it" {
  first=$("$SCRIPT" "$SLUG")
  printf '\nA divergence is a mismatch between two ledgers.\n' >> "$first"

  second=$("$SCRIPT" "$SLUG")
  [ "$second" = "$first" ]
  grep -q "A divergence is a mismatch between two ledgers." "$first"
}

@test "a missing slug is refused rather than creating a nameless project" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
  [ ! -e "$HOME/engineering/projects/.md" ]
}

@test "the script runs on its own, the way SKILL.md invokes it" {
  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/projects/${SLUG}.md" ]
}

# ── The vault location is configuration, not a constant ────────────────────────

@test "a brief lands in the vault the machine declares, not a hardcoded home" {
  export ENGINEERING_HOME="$TEST_HOME/notes"

  run bash "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_HOME/notes/projects/${SLUG}.md" ]
  [ -f "$output" ]
}

@test "a machine that declares no vault still gets the default one" {
  run bash "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/engineering/projects/${SLUG}.md" ]
}
