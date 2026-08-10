#!/usr/bin/env bats

# Tests for bin/agents-sync
#
# Slice 1: generate .claude/agents/*.md from agents/agents/*.md — merging each
# source file's shared top-level frontmatter keys with its claude: overlay.
# Commands land in a later slice.
#
# Isolation strategy: --agents-source / --agents-dest point at tmpdirs, never
# the repo's own agents/agents or .claude/agents.
#
# Assertions use cmp against a byte-exact expected fixture — key order in the
# merged frontmatter (shared keys, then the claude: block's own keys) is the
# property under test.

SCRIPT="$BATS_TEST_DIRNAME/../bin/agents-sync"

setup() {
  SRC=$(mktemp -d)
  DEST=$(mktemp -d)
}

teardown() {
  rm -rf "$SRC" "$DEST"
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

  run "$SCRIPT" --agents-source "$SRC" --agents-dest "$DEST"
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

  run "$SCRIPT" --agents-source "$SRC" --agents-dest "$DEST"
  [ "$status" -eq 0 ]

  [ -f "$DEST/plain-agent.md" ]
  cmp "$DEST/plain-agent.md" "$DEST/expected-plain-agent.md"
}

@test "a source file with no frontmatter block is skipped, and other files still sync" {
  printf 'No frontmatter here.\n' > "$SRC/no-frontmatter.md"
  write_plain_agent_source

  run "$SCRIPT" --agents-source "$SRC" --agents-dest "$DEST"
  [ "$status" -eq 0 ]

  [ ! -f "$DEST/no-frontmatter.md" ]
  [ -f "$DEST/plain-agent.md" ]
}
