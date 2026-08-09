#!/usr/bin/env bats

# Tests for bin/rules-sync
#
# Slice 1: generate .claude/rules/*.md from agents/rules/*.md — path-scoped and
# always-apply cases. Cursor output lands in a later slice.
#
# Isolation strategy: --source / --claude-dest point at tmpdirs, never the
# repo's own agents/rules or .claude/rules.
#
# Assertions use cmp against a byte-exact expected fixture rather than bats'
# $output (which strips leading/trailing newlines) — byte fidelity of the
# body, including its leading blank line or lack of one, is the property
# under test.

SCRIPT="$BATS_TEST_DIRNAME/../bin/rules-sync"

setup() {
  SRC=$(mktemp -d)
  DEST=$(mktemp -d)
}

teardown() {
  rm -rf "$SRC" "$DEST"
}

@test "a path-scoped rule's claude block is promoted to the generated file's own frontmatter" {
  cat > "$SRC/sql-comments.md" <<'EOF'
---
claude:
  paths:
    - "**/*.sql"
cursor:
  globs: "**/*.sql"
---
Always add COMMENT clauses to tables and columns.
EOF

  cat > "$DEST/expected-sql-comments.md" <<'EOF'
---
paths:
  - "**/*.sql"
---
Always add COMMENT clauses to tables and columns.
EOF

  run "$SCRIPT" --source "$SRC" --claude-dest "$DEST"
  [ "$status" -eq 0 ]

  [ -f "$DEST/sql-comments.md" ]
  cmp "$DEST/sql-comments.md" "$DEST/expected-sql-comments.md"
}

@test "an always-apply rule with an empty claude block is generated with no frontmatter" {
  cat > "$SRC/way-of-work.md" <<'EOF'
---
claude: {}
cursor:
  alwaysApply: true
---

Follow the acceptance loop.
EOF

  cat > "$DEST/expected-way-of-work.md" <<'EOF'

Follow the acceptance loop.
EOF

  run "$SCRIPT" --source "$SRC" --claude-dest "$DEST"
  [ "$status" -eq 0 ]

  [ -f "$DEST/way-of-work.md" ]
  cmp "$DEST/way-of-work.md" "$DEST/expected-way-of-work.md"
}

@test "a source file with no frontmatter block is skipped, and other files still sync" {
  printf 'No frontmatter here, just prose.\n' > "$SRC/no-frontmatter.md"
  cat > "$SRC/sql-comments.md" <<'EOF'
---
claude:
  paths:
    - "**/*.sql"
cursor:
  globs: "**/*.sql"
---
Always add COMMENT clauses to tables and columns.
EOF

  run "$SCRIPT" --source "$SRC" --claude-dest "$DEST"
  [ "$status" -eq 0 ]

  [ ! -f "$DEST/no-frontmatter.md" ]
  [ -f "$DEST/sql-comments.md" ]
}
