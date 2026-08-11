#!/usr/bin/env bats

# Tests for scripts/install-agents.sh
#
# Runs the real script against a from-scratch fixture repo (not the real
# dotfiles checkout) so a test run never compiles into or symlinks from the
# actual repo. agents-sync/hooks-sync are embedded in install-agents.sh
# itself and default their paths from the DOTFILES_DIR env var the script
# honors, so the fixture only needs to mirror agents/* and .claude/ under
# one root, pointed at via DOTFILES_DIR.
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

  mkdir -p "$FIXTURE/agents/agents" "$FIXTURE/agents/commands" \
    "$FIXTURE/agents/hooks" "$FIXTURE/agents/plugins/demo-plugin/.claude-plugin" \
    "$FIXTURE/agents/plugins/demo-plugin/skills/demo-skill" \
    "$FIXTURE/.claude/agents" "$FIXTURE/.claude/commands" \
    "$FIXTURE/.claude/themes" "$FIXTURE/.claude/workflows"

  cat > "$FIXTURE/agents/agents/demo-agent.md" <<'EOF'
---
name: demo-agent
description: A demo subagent.
claude:
  tools: Read
---
Demo agent body.
EOF

  cat > "$FIXTURE/agents/commands/demo-command.md" <<'EOF'
---
description: A demo command.
claude:
  allowed-tools: Read
---
Demo command body.
EOF

  cat > "$FIXTURE/agents/hooks/claude.settings.json" <<'EOF'
{ "hooks": { "Stop": [ { "type": "command", "command": "demo-hook --harness claude" } ] } }
EOF
  cat > "$FIXTURE/agents/hooks/cursor.hooks.json" <<'EOF'
{ "version": 1, "hooks": { "stop": [ { "command": "demo-hook --harness cursor" } ] } }
EOF

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

  echo '{"permissions": {"allow": ["Read"]}}' > "$FIXTURE/.claude/settings.json"
}

teardown() {
  rm -rf "$FIXTURE" "$FAKE_HOME"
}

@test "compiles and installs subagents and commands" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -L "$HOME/.claude/agents/demo-agent.md" ]
  grep -q "Demo agent body" "$HOME/.claude/agents/demo-agent.md"
  [ -L "$HOME/.claude/commands/demo-command.md" ]
  grep -q "Demo command body" "$HOME/.claude/commands/demo-command.md"
}

@test "installs a plugin into both Claude Code and Cursor" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -L "$HOME/.claude/skills/demo-plugin" ]
  [ -f "$HOME/.claude/skills/demo-plugin/skills/demo-skill/SKILL.md" ]
  [ -L "$HOME/.cursor/plugins/local/demo-plugin" ]
  [ -f "$HOME/.cursor/plugins/local/demo-plugin/skills/demo-skill/SKILL.md" ]
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

@test "installs Cursor hooks.json" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  [ -L "$HOME/.cursor/hooks.json" ]
  [ "$(jq -r '.hooks.stop[0].command' "$HOME/.cursor/hooks.json")" = "demo-hook --harness cursor" ]
}

@test "merges compiled hooks into ~/.claude/settings.json, keeping existing permissions" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  merged="$HOME/.claude/settings.json"
  [ -f "$merged" ]
  [ "$(jq -r '.permissions.allow[0]' "$merged")" = "Read" ]
  [ "$(jq -r '.hooks.Stop[0].command' "$merged")" = "demo-hook --harness claude" ]
}

@test "renaming a hook command replaces the old entry instead of duplicating it" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  [ "$(jq '.hooks.Stop | length' "$HOME/.claude/settings.json")" = "1" ]

  cat > "$FIXTURE/agents/hooks/claude.settings.json" <<'EOF'
{ "hooks": { "Stop": [ { "type": "command", "command": "renamed-hook --harness claude" } ] } }
EOF
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  merged="$HOME/.claude/settings.json"
  [ "$(jq '.hooks.Stop | length' "$merged")" = "1" ]
  [ "$(jq -r '.hooks.Stop[0].command' "$merged")" = "renamed-hook --harness claude" ]
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

@test "is idempotent: running twice produces the same installed agent content" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  first=$(cat "$HOME/.claude/agents/demo-agent.md")

  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  second=$(cat "$HOME/.claude/agents/demo-agent.md")

  [ "$first" = "$second" ]
}
