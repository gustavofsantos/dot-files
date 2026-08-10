#!/usr/bin/env bats

# Tests for members.sh, alongside it.
#
# Run: bats agents/skills/project/scripts/members_test.bats
#
# Isolation strategy:
#   HOME → fresh tmpdir, so ~/engineering is built per-test and the real vault
#          is never touched.

SCRIPT="$BATS_TEST_DIRNAME/members.sh"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  unset ENGINEERING_HOME
  SLUG="accounting-divergences"
  ISSUES="$HOME/engineering/issues"
  mkdir -p "$ISSUES/backlog" "$ISSUES/done"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# seed_issue <relative-path> <project-slug-or-empty>
seed_issue() {
  local path="$ISSUES/$1" project="${2:-}"
  {
    echo '---'
    echo 'paths: []'
    [ -n "$project" ] && echo "project: $project"
    echo 'created: 2026-08-04'
    echo '---'
    echo
    echo '## Objective'
    echo 'Correct the ledger.'
  } > "$path"
}

# ── Membership ─────────────────────────────────────────────────────────────────

@test "an issue that names the project is a member of it" {
  seed_issue "2026-08-04-correct-the-ledger.md" "$SLUG"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$ISSUES/2026-08-04-correct-the-ledger.md" ]
}

@test "membership spans active, backlog and done, in that order" {
  seed_issue "2026-08-04-correct-the-ledger.md"      "$SLUG"
  seed_issue "backlog/2026-07-22-map-the-feeds.md"   "$SLUG"
  seed_issue "done/2026-06-30-name-the-tables.md"    "$SLUG"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "$ISSUES/2026-08-04-correct-the-ledger.md" ]
  [ "${lines[1]}" = "$ISSUES/backlog/2026-07-22-map-the-feeds.md" ]
  [ "${lines[2]}" = "$ISSUES/done/2026-06-30-name-the-tables.md" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "an issue that names another project is left out" {
  seed_issue "2026-08-04-correct-the-ledger.md" "$SLUG"
  seed_issue "2026-08-05-retire-the-cron.md"    "legacy-systems"

  run "$SCRIPT" "$SLUG"
  [ "$output" = "$ISSUES/2026-08-04-correct-the-ledger.md" ]
}

@test "an issue that names no project is left out" {
  seed_issue "2026-08-05-retire-the-cron.md"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# ── Precision ──────────────────────────────────────────────────────────────────

@test "a slug that is only the start of another is not a match" {
  seed_issue "2026-08-04-correct-the-ledger.md" "$SLUG"

  run "$SCRIPT" "accounting"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "the project is read from the frontmatter, not from the prose" {
  local f="$ISSUES/2026-08-05-retire-the-cron.md"
  {
    echo '---'
    echo 'created: 2026-08-05'
    echo '---'
    echo
    echo '## Context'
    echo "project: $SLUG"
  } > "$f"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# ── Guards ─────────────────────────────────────────────────────────────────────

@test "a project with no issues prints nothing and still succeeds" {
  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "a vault with no issues folder prints nothing and still succeeds" {
  rm -rf "$ISSUES"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "a missing slug is refused" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "the script runs on its own, the way SKILL.md invokes it" {
  seed_issue "2026-08-04-correct-the-ledger.md" "$SLUG"

  run "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$ISSUES/2026-08-04-correct-the-ledger.md" ]
}

# ── The vault location is configuration, not a constant ────────────────────────

@test "membership is read from the vault the machine declares, not a hardcoded home" {
  export ENGINEERING_HOME="$TEST_HOME/notes"
  mkdir -p "$TEST_HOME/notes/issues"
  ISSUES="$TEST_HOME/notes/issues"
  seed_issue "2026-08-04-correct-the-ledger.md" "$SLUG"

  run bash "$SCRIPT" "$SLUG"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_HOME/notes/issues/2026-08-04-correct-the-ledger.md" ]
}
