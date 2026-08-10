#!/usr/bin/env bats

# Tests for agents/hooks/claude.settings.json and agents/hooks/cursor.hooks.json
#
# Static validation: both are well-formed for their harness's shape, and every
# hook command they wire references a script that actually exists in
# agents/hooks/ — cheap insurance against a typo'd script name silently
# breaking a hook.

HOOKS_DIR="$BATS_TEST_DIRNAME/../agents/hooks"
CLAUDE_CFG="$HOOKS_DIR/claude.settings.json"
CURSOR_CFG="$HOOKS_DIR/cursor.hooks.json"

claude_commands() {
  jq -r '.hooks[] | .. | objects | select(has("command")) | .command' "$CLAUDE_CFG"
}

cursor_commands() {
  jq -r '.hooks[][] | .command' "$CURSOR_CFG"
}

@test "claude.settings.json is valid JSON" {
  run jq -e . "$CLAUDE_CFG"
  [ "$status" -eq 0 ]
}

@test "claude.settings.json has only a hooks top-level key" {
  keys=$(jq -r 'keys | join(",")' "$CLAUDE_CFG")
  [ "$keys" = "hooks" ]
}

@test "cursor.hooks.json is valid JSON" {
  run jq -e . "$CURSOR_CFG"
  [ "$status" -eq 0 ]
}

@test "cursor.hooks.json has version and hooks top-level keys" {
  keys=$(jq -r 'keys | sort | join(",")' "$CURSOR_CFG")
  [ "$keys" = "hooks,version" ]
}

@test "every claude.settings.json command references a script in agents/hooks/" {
  while IFS= read -r cmd; do
    script="${cmd%% *}"
    [ "$script" = "tap-hook" ] && script="${cmd#tap-hook }"
    script="${script%% *}"
    [ -x "$HOOKS_DIR/$script" ] || {
      echo "missing or non-executable: $script (from command: $cmd)"
      return 1
    }
  done < <(claude_commands)
}

@test "every cursor.hooks.json command references a script in agents/hooks/" {
  while IFS= read -r cmd; do
    script="${cmd%% *}"
    [ -x "$HOOKS_DIR/$script" ] || {
      echo "missing or non-executable: $script (from command: $cmd)"
      return 1
    }
  done < <(cursor_commands)
}

@test "every claude.settings.json command passes --harness claude" {
  while IFS= read -r cmd; do
    [[ "$cmd" == *"--harness claude"* ]] || {
      echo "missing --harness claude: $cmd"
      return 1
    }
  done < <(claude_commands)
}

@test "every cursor.hooks.json command passes --harness cursor" {
  while IFS= read -r cmd; do
    [[ "$cmd" == *"--harness cursor"* ]] || {
      echo "missing --harness cursor: $cmd"
      return 1
    }
  done < <(cursor_commands)
}
