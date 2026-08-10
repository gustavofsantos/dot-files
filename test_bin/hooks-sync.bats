#!/usr/bin/env bats

# Tests for bin/hooks-sync
#
# Merges agents/hooks/claude.settings.json's "hooks" key into the real,
# hand-maintained .claude/settings.json (permissions/env untouched), and
# generates .cursor/hooks.json wholesale from agents/hooks/cursor.hooks.json.
#
# Isolation strategy: --claude-source / --claude-dest / --cursor-source /
# --cursor-dest all point at tmpdirs/tmpfiles, never the repo's own
# agents/hooks, .claude/settings.json, .cursor/hooks.json.

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-sync"

setup() {
  WORK=$(mktemp -d)
  CLAUDE_SOURCE="$WORK/claude.settings.json"
  CLAUDE_DEST="$WORK/claude/settings.json"
  CURSOR_SOURCE="$WORK/cursor.hooks.json"
  CURSOR_DEST="$WORK/cursor/hooks.json"
  mkdir -p "$(dirname "$CLAUDE_DEST")" "$(dirname "$CURSOR_DEST")"
}

teardown() {
  rm -rf "$WORK"
}

run_sync() {
  run "$SCRIPT" \
    --claude-source "$CLAUDE_SOURCE" --claude-dest "$CLAUDE_DEST" \
    --cursor-source "$CURSOR_SOURCE" --cursor-dest "$CURSOR_DEST" "$@"
}

write_claude_source() {
  cat > "$CLAUDE_SOURCE" <<'EOF'
{
  "hooks": {
    "Stop": [
      { "type": "command", "command": "notify --harness claude" }
    ]
  }
}
EOF
}

write_cursor_source() {
  cat > "$CURSOR_SOURCE" <<'EOF'
{
  "version": 1,
  "hooks": {
    "stop": [
      { "command": "engineering-autocommit --harness cursor" }
    ]
  }
}
EOF
}

@test "claude: merges the hooks key into an existing settings.json without touching other keys" {
  cat > "$CLAUDE_DEST" <<'EOF'
{
  "permissions": { "allow": ["Read"] },
  "hooks": { "Stop": [{ "type": "command", "command": "stale-hook" }] }
}
EOF
  write_claude_source
  write_cursor_source

  run_sync
  [ "$status" -eq 0 ]

  [ "$(jq -r '.permissions.allow[0]' "$CLAUDE_DEST")" = "Read" ]
  [ "$(jq -r '.hooks.Stop[0].command' "$CLAUDE_DEST")" = "notify --harness claude" ]
}

@test "claude: adds a hooks key to a settings.json that has none yet" {
  echo '{"permissions": {"allow": ["Read"]}}' > "$CLAUDE_DEST"
  write_claude_source
  write_cursor_source

  run_sync
  [ "$status" -eq 0 ]

  [ "$(jq -r '.hooks.Stop[0].command' "$CLAUDE_DEST")" = "notify --harness claude" ]
}

@test "cursor: generates hooks.json wholesale matching the source" {
  echo '{}' > "$CLAUDE_DEST"
  write_claude_source
  write_cursor_source

  run_sync
  [ "$status" -eq 0 ]

  [ "$(jq -r '.version' "$CURSOR_DEST")" = "1" ]
  [ "$(jq -r '.hooks.stop[0].command' "$CURSOR_DEST")" = "engineering-autocommit --harness cursor" ]
}

@test "re-running with unchanged sources is idempotent" {
  echo '{"permissions": {"allow": ["Read"]}}' > "$CLAUDE_DEST"
  write_claude_source
  write_cursor_source

  run_sync
  first_claude=$(cat "$CLAUDE_DEST")
  first_cursor=$(cat "$CURSOR_DEST")

  run_sync
  [ "$(cat "$CLAUDE_DEST")" = "$first_claude" ]
  [ "$(cat "$CURSOR_DEST")" = "$first_cursor" ]
}

@test "--dry-run reports actions without writing either destination" {
  echo '{"permissions": {"allow": ["Read"]}}' > "$CLAUDE_DEST"
  write_claude_source
  write_cursor_source
  before_claude=$(cat "$CLAUDE_DEST")

  run_sync --dry-run
  [ "$status" -eq 0 ]

  [ "$(cat "$CLAUDE_DEST")" = "$before_claude" ]
  [ ! -s "$CURSOR_DEST" ]
}
