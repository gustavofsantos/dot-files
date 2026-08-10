#!/usr/bin/env bats

# Tests for bin/agents-sync
#
# Slice 1: generate .claude/agents/*.md from agents/agents/*.md — merging each
# source file's shared top-level frontmatter keys with its claude: overlay.
# Slice 2: generate .claude/commands/*.md from agents/commands/*.md too.
#
# Isolation strategy: --agents-source / --agents-dest / --commands-source /
# --commands-dest point at tmpdirs, never the repo's own agents/agents,
# agents/commands, .claude/agents, .claude/commands. Every invocation passes
# all four flags explicitly, even in agents-only tests — rules-sync's tests
# once fell back to real repo defaults when a later slice made a second sync
# unconditional and a flag was left unpassed.
#
# Assertions use cmp against a byte-exact expected fixture — key order in the
# merged frontmatter (shared keys, then the claude: block's own keys) is the
# property under test.

SCRIPT="$BATS_TEST_DIRNAME/../bin/agents-sync"

setup() {
  SRC=$(mktemp -d)
  DEST=$(mktemp -d)
  CMD_SRC=$(mktemp -d)
  CMD_DEST=$(mktemp -d)
}

teardown() {
  rm -rf "$SRC" "$DEST" "$CMD_SRC" "$CMD_DEST"
}

run_sync() {
  run "$SCRIPT" --agents-source "$SRC" --agents-dest "$DEST" \
    --commands-source "$CMD_SRC" --commands-dest "$CMD_DEST" "$@"
}

write_plain_agent_source() {
  cat > "$SRC/plain-agent.md" <<'EOF'
---
name: plain-agent
description: No harness overlay needed.
---
Body text.
EOF
}

@test "a subagent's shared keys and claude block are merged into the generated file's own frontmatter, in order" {
  cat > "$SRC/clojure-advisor.md" <<'EOF'
---
name: clojure-advisor
description: A second pair of eyes on Clojure code.
claude:
  tools: Read, Grep, Glob
  model: inherit
---

# ROLE

Body text.
EOF

  cat > "$DEST/expected-clojure-advisor.md" <<'EOF'
---
name: clojure-advisor
description: A second pair of eyes on Clojure code.
tools: Read, Grep, Glob
model: inherit
---

# ROLE

Body text.
EOF

  run_sync
  [ "$status" -eq 0 ]

  [ -f "$DEST/clojure-advisor.md" ]
  cmp "$DEST/clojure-advisor.md" "$DEST/expected-clojure-advisor.md"
}

@test "a source file with no claude block is generated with just the shared keys" {
  write_plain_agent_source

  cat > "$DEST/expected-plain-agent.md" <<'EOF'
---
name: plain-agent
description: No harness overlay needed.
---
Body text.
EOF

  run_sync
  [ "$status" -eq 0 ]

  [ -f "$DEST/plain-agent.md" ]
  cmp "$DEST/plain-agent.md" "$DEST/expected-plain-agent.md"
}

@test "a source file with no frontmatter block is skipped, and other files still sync" {
  printf 'No frontmatter here.\n' > "$SRC/no-frontmatter.md"
  write_plain_agent_source

  run_sync
  [ "$status" -eq 0 ]

  [ ! -f "$DEST/no-frontmatter.md" ]
  [ -f "$DEST/plain-agent.md" ]
}

@test "a command's shared description and claude block are merged into the generated file's own frontmatter" {
  cat > "$CMD_SRC/legacy-gate.md" <<'EOF'
---
description: Derive and verify .claude/legacy.json.
claude:
  argument-hint: "[optional: path hint]"
  allowed-tools: Bash, Read, Write
---

# Task

Body text.
EOF

  cat > "$CMD_DEST/expected-legacy-gate.md" <<'EOF'
---
description: Derive and verify .claude/legacy.json.
argument-hint: "[optional: path hint]"
allowed-tools: Bash, Read, Write
---

# Task

Body text.
EOF

  run_sync
  [ "$status" -eq 0 ]

  [ -f "$CMD_DEST/legacy-gate.md" ]
  cmp "$CMD_DEST/legacy-gate.md" "$CMD_DEST/expected-legacy-gate.md"
}
