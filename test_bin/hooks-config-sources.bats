#!/usr/bin/env bats

# Tests for each plugin's hooks/hooks.json and hooks/cursor.hooks.json
#
# Static validation: both are well-formed for their harness's shape, and every
# hook command they wire references a script that actually exists in bin/
# (hook scripts live there, prefixed hooks-*) — cheap insurance against a
# typo'd script name silently breaking a hook. Hooks live inside each plugin
# now (agents/plugins/<name>/hooks/), not in a separate compiled source, so
# this iterates every plugin that ships one rather than a single fixed path.

PLUGINS_DIR="$BATS_TEST_DIRNAME/../agents/plugins"
BIN_DIR="$BATS_TEST_DIRNAME/../bin"

claude_hooks_files() {
  find "$PLUGINS_DIR" -mindepth 3 -maxdepth 3 -path '*/hooks/hooks.json'
}

cursor_hooks_files() {
  find "$PLUGINS_DIR" -mindepth 3 -maxdepth 3 -path '*/hooks/cursor.hooks.json'
}

claude_commands() {
  jq -r '.hooks[] | .. | objects | select(has("command")) | .command' "$1"
}

cursor_commands() {
  jq -r '.hooks[][] | .command' "$1"
}

@test "at least one plugin ships Claude hooks" {
  [ -n "$(claude_hooks_files)" ]
}

@test "at least one plugin ships Cursor hooks" {
  [ -n "$(cursor_hooks_files)" ]
}

@test "every plugin's hooks/hooks.json is valid JSON with only a hooks top-level key" {
  while IFS= read -r cfg; do
    run jq -e . "$cfg"
    [ "$status" -eq 0 ]
    keys=$(jq -r 'keys | join(",")' "$cfg")
    [ "$keys" = "hooks" ]
  done < <(claude_hooks_files)
}

@test "every plugin's hooks/cursor.hooks.json is valid JSON with version and hooks top-level keys" {
  while IFS= read -r cfg; do
    run jq -e . "$cfg"
    [ "$status" -eq 0 ]
    keys=$(jq -r 'keys | sort | join(",")' "$cfg")
    [ "$keys" = "hooks,version" ]
  done < <(cursor_hooks_files)
}

@test "every hooks/hooks.json command references an executable script in bin/" {
  while IFS= read -r cfg; do
    while IFS= read -r cmd; do
      script="${cmd%% *}"
      [ "$script" = "tap-hook" ] && script="${cmd#tap-hook }"
      script="${script%% *}"
      [ -x "$BIN_DIR/$script" ] || {
        echo "missing or non-executable: $script (from command: $cmd, in $cfg)"
        return 1
      }
    done < <(claude_commands "$cfg")
  done < <(claude_hooks_files)
}

@test "every hooks/cursor.hooks.json command references an executable script in bin/" {
  while IFS= read -r cfg; do
    while IFS= read -r cmd; do
      script="${cmd%% *}"
      [ -x "$BIN_DIR/$script" ] || {
        echo "missing or non-executable: $script (from command: $cmd, in $cfg)"
        return 1
      }
    done < <(cursor_commands "$cfg")
  done < <(cursor_hooks_files)
}

@test "every hooks/hooks.json command passes --harness claude" {
  while IFS= read -r cfg; do
    while IFS= read -r cmd; do
      [[ "$cmd" == *"--harness claude"* ]] || {
        echo "missing --harness claude: $cmd (in $cfg)"
        return 1
      }
    done < <(claude_commands "$cfg")
  done < <(claude_hooks_files)
}

@test "every hooks/cursor.hooks.json command passes --harness cursor" {
  while IFS= read -r cfg; do
    while IFS= read -r cmd; do
      [[ "$cmd" == *"--harness cursor"* ]] || {
        echo "missing --harness cursor: $cmd (in $cfg)"
        return 1
      }
    done < <(cursor_commands "$cfg")
  done < <(cursor_hooks_files)
}
