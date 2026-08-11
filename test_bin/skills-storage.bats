#!/usr/bin/env bats

# A skill is code, never a store. This test guards the boundary.
#
# Run: bats test_bin/skills-storage.bats

# Skills live nested inside a plugin (agents/plugins/<plugin>/skills/<name>/),
# so a plugin's skills/ dir -- not the plugin dir itself -- is the boundary
# this test guards.
SKILLS_DIRS=("$BATS_TEST_DIRNAME"/../agents/plugins/*/skills)

# Every path a skill is allowed to own. Anything else is stored data.
allowed_paths() {
  find "${SKILLS_DIRS[@]}" -mindepth 2 -type f \
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
  planted="$BATS_TEST_DIRNAME/../agents/plugins/gustavofsantos/skills/spike/answers.md"
  : > "$planted"

  run allowed_paths
  rm -f "$planted"

  [ "$output" = "$planted" ]
}

@test "no skill tells the agent to write inside the skill tree" {
  # A prohibition ("never write inside this skill directory") is the wanted wording,
  # so the pattern skips anything a negation introduces.
  run grep -rnPi '(?<!never )(?<!not )write[^.]{0,30}(skill-dir|skill directory)|<skill-dir>/[a-z-]+\.md' "${SKILLS_DIRS[@]}"
  [ "$status" -ne 0 ]
}
