#!/usr/bin/env bats

# Tests for scripts/install-agents.sh
#
# Runs the real script against a from-scratch fixture repo (not the real
# dotfiles checkout) so a test run never compiles into or symlinks from the
# actual repo. rules-sync/agents-sync/hooks-sync each resolve their own
# default paths from their own file location, so the fixture must mirror the
# real directory shape (bin/, agents/*, .claude/) under one root, pointed at
# via the DOTFILES_DIR env var the script now honors.
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

  mkdir -p "$FIXTURE/bin" "$FIXTURE/scripts"
  cp "$REAL_REPO/bin/rules-sync" "$REAL_REPO/bin/agents-sync" "$REAL_REPO/bin/hooks-sync" "$FIXTURE/bin/"
  cp "$REAL_REPO/$SCRIPT_REL" "$FIXTURE/scripts/install-agents.sh"
  chmod +x "$FIXTURE/bin/"* "$FIXTURE/scripts/"*

  mkdir -p "$FIXTURE/agents/rules" "$FIXTURE/agents/agents" "$FIXTURE/agents/commands" \
    "$FIXTURE/agents/hooks" "$FIXTURE/agents/skills/demo-skill" \
    "$FIXTURE/.claude/agents" "$FIXTURE/.claude/commands" "$FIXTURE/.claude/rules" \
    "$FIXTURE/.claude/themes" "$FIXTURE/.claude/workflows"

  cat > "$FIXTURE/agents/rules/demo-rule.md" <<'EOF'
---
claude:
  paths:
    - "**/*.demo"
cursor:
  globs: "**/*.demo"
---
Demo rule body.
EOF

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

  cat > "$FIXTURE/agents/skills/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: A demo skill.
---
Demo skill body.
EOF

  echo '{"permissions": {"allow": ["Read"]}}' > "$FIXTURE/.claude/settings.json"
  echo 'harnesses: {}' > "$FIXTURE/.claude/harness-profiles.yml"
}

teardown() {
  rm -rf "$FIXTURE" "$FAKE_HOME"
}

@test "compiles and installs rules for both harnesses" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -L "$HOME/.claude/rules/demo-rule.md" ]
  grep -q "Demo rule body" "$HOME/.claude/rules/demo-rule.md"
  [ -L "$HOME/.cursor/rules/demo-rule.mdc" ]
  grep -q "Demo rule body" "$HOME/.cursor/rules/demo-rule.mdc"
}

@test "compiles and installs subagents and commands" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ -L "$HOME/.claude/agents/demo-agent.md" ]
  grep -q "Demo agent body" "$HOME/.claude/agents/demo-agent.md"
  [ -L "$HOME/.claude/commands/demo-command.md" ]
  grep -q "Demo command body" "$HOME/.claude/commands/demo-command.md"
}

@test "installs skills" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  [ -L "$HOME/.claude/skills/demo-skill" ]
  [ -f "$HOME/.claude/skills/demo-skill/SKILL.md" ]
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

@test "is idempotent: running twice produces the same installed rule content" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  first=$(cat "$HOME/.claude/rules/demo-rule.md")

  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  second=$(cat "$HOME/.claude/rules/demo-rule.md")

  [ "$first" = "$second" ]
}

@test "prunes a dangling rule symlink when the source rule is removed" {
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null
  [ -L "$HOME/.claude/rules/demo-rule.md" ]

  rm "$FIXTURE/agents/rules/demo-rule.md"
  bash "$FIXTURE/scripts/install-agents.sh" >/dev/null

  [ ! -e "$HOME/.claude/rules/demo-rule.md" ]
}
