#!/usr/bin/env bats

# Tests for bin/hooks-vale-lint
#
# PostToolUse hook: after a file edit on a *.md file, run vale and
# feed warning+error severity issues back to the agent. Claude reads them
# back via stderr (exit 2); Cursor's postToolUse reads a
# {"additional_context": ...} JSON object; Codex's PostToolUse reads a
# hookSpecificOutput.additionalContext response.
# Suggestion-level alerts (Vocab, PassiveVoice, ...) are dropped — see
# config/vale/README.md's "Dogfood results" for which STE checks are
# error-level versus suggestion-level.
#
# Isolation: each test gets its own tmpdir with a copy of config/vale's
# .vale.ini + styles, so the hook lints against the real STE style set
# without depending on ~/.config/vale being symlinked on this machine.

SCRIPT="$BATS_TEST_DIRNAME/../bin/hooks-vale-lint"

setup() {
  TEST_DIR=$(mktemp -d)
  cp "$BATS_TEST_DIRNAME/../config/vale/.vale.ini" "$TEST_DIR/.vale.ini"
  cp -r "$BATS_TEST_DIRNAME/../config/vale/styles" "$TEST_DIR/styles"
}

teardown() {
  rm -rf "$TEST_DIR"
}

payload() {
  local file="$1"
  jq -n --arg cwd "$TEST_DIR" --arg file "$file" \
    '{cwd: $cwd, tool_name: "Edit", tool_input: {file_path: $file}}'
}

codex_payload() {
  local patch="$1"
  jq -n --arg cwd "$TEST_DIR" --arg patch "$patch" \
    '{cwd: $cwd, hook_event_name: "PostToolUse", tool_name: "apply_patch", tool_input: {command: $patch}}'
}

@test "--harness is required" {
  run bash "$SCRIPT" <<< "$(payload "$TEST_DIR/x.md")"
  [ "$status" -ne 0 ]
}

@test "an unrecognized --harness value is rejected" {
  run bash "$SCRIPT" --harness vscode <<< "$(payload "$TEST_DIR/x.md")"
  [ "$status" -ne 0 ]
}

@test "codex: extracts the changed markdown path from apply_patch and returns hook feedback" {
  cat > "$TEST_DIR/bad.md" <<'EOF'
# Test

An extremely long sentence that goes on and on and on and on and on and on and on and on to trip the sentence length rule for sure.
EOF
  patch=$'*** Begin Patch\n*** Update File: bad.md\n@@\n-An old sentence.\n+An extremely long sentence.\n*** End Patch'
  run bash "$SCRIPT" --harness codex <<< "$(codex_payload "$patch")"
  [ "$status" -eq 0 ]
  jq -e '
    (.decision == "block") and
    (.reason | contains("SentenceLength")) and
    (.hookSpecificOutput.hookEventName == "PostToolUse") and
    (.hookSpecificOutput.additionalContext | contains("bad.md"))
  ' <<< "$output" >/dev/null
}

@test "exits 2 and reports the check name for an error-level violation" {
  cat > "$TEST_DIR/bad.md" <<'EOF'
# Test

An extremely long sentence that goes on and on and on and on and on and on and on and on to trip the sentence length rule for sure.
EOF
  run bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/bad.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"SentenceLength"* ]]
}

@test "cursor: exits 0 and prints additional_context for an error-level violation" {
  cat > "$TEST_DIR/bad.md" <<'EOF'
# Test

An extremely long sentence that goes on and on and on and on and on and on and on and on to trip the sentence length rule for sure.
EOF
  run bash "$SCRIPT" --harness cursor <<< "$(payload "$TEST_DIR/bad.md")"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SentenceLength"* ]]
  jq -e '.additional_context | contains("SentenceLength")' <<< "$output" >/dev/null
}

@test "exits 0 for a clean markdown file" {
  cat > "$TEST_DIR/good.md" <<'EOF'
# Test

Short and clean.
EOF
  run bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/good.md")"
  [ "$status" -eq 0 ]
}

@test "cursor: exits 0 with no output for a clean markdown file" {
  cat > "$TEST_DIR/good.md" <<'EOF'
# Test

Short and clean.
EOF
  run bash "$SCRIPT" --harness cursor <<< "$(payload "$TEST_DIR/good.md")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "codex: exits 0 with no output for a clean markdown patch" {
  cat > "$TEST_DIR/good.md" <<'EOF'
# Test

Short and clean.
EOF
  patch=$'*** Begin Patch\n*** Update File: good.md\n@@\n-Old.\n+Short and clean.\n*** End Patch'
  run bash "$SCRIPT" --harness codex <<< "$(codex_payload "$patch")"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 (non-blocking) for a file with only suggestion-level issues" {
  # Keep the prose short and plain. The Readability rules score the whole
  # document at warning level, so a long word in a small file raises the score
  # above the limit and the fixture stops being suggestion-only.
  cat > "$TEST_DIR/suggest.md" <<'EOF'
# Test

The fix is acceptable. The test is green. The tool runs fast. We ship it now.
EOF
  # Guard the fixture: a clean file would also exit 0, which would make this a
  # copy of the test above.
  severities=$(cd "$TEST_DIR" && vale --output=JSON suggest.md | jq -r '[.[][].Severity] | unique | join(",")')
  [ "$severities" = "suggestion" ]

  run bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/suggest.md")"
  [ "$status" -eq 0 ]
}

@test "exits 0 for a non-markdown file" {
  cat > "$TEST_DIR/notes.txt" <<'EOF'
An extremely long sentence that goes on and on and on and on and on and on and on and on to trip the sentence length rule for sure.
EOF
  run bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/notes.txt")"
  [ "$status" -eq 0 ]
}

@test "exits 0 when the edited file no longer exists" {
  run bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/gone.md")"
  [ "$status" -eq 0 ]
}

@test "exits 0 when vale is not on PATH" {
  cat > "$TEST_DIR/bad.md" <<'EOF'
# Test

An extremely long sentence that goes on and on and on and on and on and on and on and on to trip the sentence length rule for sure.
EOF
  run env PATH="/usr/bin:/bin" bash "$SCRIPT" --harness claude <<< "$(payload "$TEST_DIR/bad.md")"
  [ "$status" -eq 0 ]
}
