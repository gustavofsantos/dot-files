#!/usr/bin/env bats

# Tests for scripts/install-agents.sh
#
# Runs the real script against a from-scratch fixture repo (not the real
# dotfiles checkout) so a test run never symlinks from the actual repo.
# The script itself just symlinks agents/plugins/<name>/ into both harnesses'
# plugin directories and merges .claude/settings.json into the global one --
# every skill, agent, hook, and theme reaches Claude Code and Cursor purely
# by being inside the symlinked plugin directory, so there's nothing else
# for this script to compile.
#
# Isolation strategy:
#   DOTFILES_DIR -> a constructed fixture repo (tmpdir)
#   HOME         -> a separate fresh tmpdir

SCRIPT_REL="scripts/install-agents.sh"
REAL_REPO="$BATS_TEST_DIRNAME/.."

setup() {
  FIXTURE=$(mktemp -d)
  FAKE_HOME=$(mktemp -d)
  export HOME="$FAKE_HOME"
  export DOTFILES_DIR="$FIXTURE"

  mkdir -p "$FIXTURE/scripts"
  cp "$REAL_REPO/$SCRIPT_REL" "$FIXTURE/scripts/install-agents.sh"
  chmod +x "$FIXTURE/scripts/"*

  mkdir -p "$FIXTURE/agents/plugins/demo-plugin/.claude-plugin" \
    "$FIXTURE/agents/plugins/demo-plugin/skills/demo-skill" \
    "$FIXTURE/agents/plugins/demo-plugin/hooks" \
    "$FIXTURE/agents/plugins/demo-plugin/commands" \
    "$FIXTURE/.claude"

  cat > "$FIXTURE/agents/plugins/demo-plugin/.claude-plugin/plugin.json" <<'EOF'
{ "name": "demo-plugin", "description": "A demo plugin." }
EOF
  cat > "$FIXTURE/agents/plugins/demo-plugin/skills/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: A demo skill.
---
Demo skill body.
EOF
  cat > "$FIXTURE/agents/plugins/demo-plugin/hooks/hooks.json" <<'EOF'
{ "hooks": { "Stop": [ { "type": "command", "command": "demo-hook --harness claude" } ] } }
EOF
  cat > "$FIXTURE/agents/plugins/demo-plugin/commands/demo-command.md" <<'EOF'
---
description: A demo command.
---
Demo command body.
EOF

  echo '{"permissions": {"allow": ["Read"]}}' > "$FIXTURE/.claude/settings.json"
}

teardown() {
  rm -rf "$FIXTURE" "$FAKE_HOME"
}

@test "installs a plugin into both Claude Code and Cursor" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -L "$HOME/.claude/skills/demo-plugin" ]
  [ -f "$HOME/.claude/skills/demo-plugin/skills/demo-skill/SKILL.md" ]
  [ -f "$HOME/.claude/skills/demo-plugin/hooks/hooks.json" ]
  [ -L "$HOME/.cursor/plugins/local/demo-plugin" ]
  [ -f "$HOME/.cursor/plugins/local/demo-plugin/skills/demo-skill/SKILL.md" ]
}

@test "a plugin's slash commands reach both harnesses" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -f "$HOME/.claude/skills/demo-plugin/commands/demo-command.md" ]
  [ -f "$HOME/.cursor/plugins/local/demo-plugin/commands/demo-command.md" ]
}

@test "prunes a dangling plugin symlink when the source plugin is removed" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  [ -L "$HOME/.claude/skills/demo-plugin" ]
  [ -L "$HOME/.cursor/plugins/local/demo-plugin" ]

  rm -rf "$FIXTURE/agents/plugins/demo-plugin"
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ ! -e "$HOME/.claude/skills/demo-plugin" ]
  [ ! -e "$HOME/.cursor/plugins/local/demo-plugin" ]
}

@test "merges dotfiles settings into a fresh ~/.claude/settings.json" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ "$(jq -r '.permissions.allow[0]' "$HOME/.claude/settings.json")" = "Read" ]
}

@test "merges permissions into an existing ~/.claude/settings.json, unioning allow lists" {
  mkdir -p "$HOME/.claude"
  echo '{"permissions": {"allow": ["Bash(ls *)"]}}' > "$HOME/.claude/settings.json"

  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  allow=$(jq -c '.permissions.allow | sort' "$HOME/.claude/settings.json")
  [ "$allow" = '["Bash(ls *)","Read"]' ]
}

@test "leaves an existing hooks key in the global settings.json untouched" {
  mkdir -p "$HOME/.claude"
  echo '{"permissions": {"allow": ["Read"]}, "hooks": {"Stop": [{"type": "command", "command": "machine-local-hook"}]}}' \
    > "$HOME/.claude/settings.json"

  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ "$(jq -r '.hooks.Stop[0].command' "$HOME/.claude/settings.json")" = "machine-local-hook" ]
}

@test "a concurrent reader never observes a truncated settings.json while install-agents.sh re-runs" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  (
    for i in $(seq 1 60); do
      bash "$FIXTURE/scripts/install-agents.sh" >/dev/null 2>&1
    done
  ) &
  writer=$!

  invalid=0
  while kill -0 "$writer" 2>/dev/null; do
    [ -s "$HOME/.claude/settings.json" ] || invalid=$((invalid + 1))
  done
  wait "$writer"

  [ "$invalid" -eq 0 ]
}

@test "is idempotent: running twice produces the same installed plugin content" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  first=$(cat "$HOME/.claude/skills/demo-plugin/skills/demo-skill/SKILL.md")

  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  second=$(cat "$HOME/.claude/skills/demo-plugin/skills/demo-skill/SKILL.md")

  [ "$first" = "$second" ]
}
