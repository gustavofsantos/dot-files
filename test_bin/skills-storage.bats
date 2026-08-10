#!/usr/bin/env bats

# A skill is code, never a store. This test guards the boundary.
#
# Run: bats test_bin/skills-storage.bats

SKILLS="$BATS_TEST_DIRNAME/../agents/skills"

# Every path a skill is allowed to own. Anything else is stored data.
allowed_paths() {
  find "$SKILLS" -mindepth 2 -type f \
    ! -name 'SKILL.md' \
    ! -path '*/references/*' \
    ! -path '*/scripts/*' \
    ! -path '*/assets/*'
}

# ── The promise ────────────────────────────────────────────────────────────────

@test "a skill directory holds instructions, never the information the skill produced" {
  run allowed_paths
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the guard sees a skill that stored its own output" {
  planted="$SKILLS/spike/answers.md"
  : > "$planted"

  run allowed_paths
  rm -f "$planted"

  [ "$output" = "$planted" ]
}

@test "no skill tells the agent to write inside the skill tree" {
  # A prohibition ("never write inside this skill directory") is the wanted wording,
  # so the pattern skips anything a negation introduces.
  run grep -rnPi '(?<!never )(?<!not )write[^.]{0,30}(skill-dir|skill directory)|<skill-dir>/[a-z-]+\.md' "$SKILLS"
  [ "$status" -ne 0 ]
}
