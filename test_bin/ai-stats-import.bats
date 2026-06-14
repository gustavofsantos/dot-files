#!/usr/bin/env bats

# Tests for bin/ai-stats-import
#
# Encodes the value of the (throwaway) verifier script as durable assertions:
# the tailored token store must count each assistant message's usage EXACTLY
# ONCE per model. The data hazard being guarded against — discovered in the
# real corpus — is that one assistant message is split across many transcript
# lines that each REPEAT the same `usage`. Summing every line triple-counts;
# the old hook logger's last-usage-only approach undercounts. Neither is here.
#
# Isolation strategy:
#   HOME                 → fresh tmpdir
#   CLAUDE_PROJECTS_DIR  → tmpdir holding synthetic transcripts (importer input)
#   AGENT_SESSIONS_DIR   → tmpdir holding the stats store (importer output)
#
# Fixtures are crafted so the correct per-model totals are known by construction.

SCRIPT="$BATS_TEST_DIRNAME/../bin/ai-stats-import"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export CLAUDE_PROJECTS_DIR="$TEST_HOME/projects"
  export AGENT_SESSIONS_DIR="$TEST_HOME/agent-sessions"
  PROJ="$CLAUDE_PROJECTS_DIR/proj"
  mkdir -p "$PROJ"
  STORE="$AGENT_SESSIONS_DIR/stats"
}

teardown() {
  rm -rf "$TEST_HOME"
}

record() { echo "$STORE/$1.json"; }
sget()   { jq -r "$2" "$(record "$1")" 2>/dev/null; }

# One assistant message line. Args: session, msg_id, model, in out cr cw [sidechain]
asst_line() {
  local sid="$2" model="$3" in="$4" out="$5" cr="$6" cw="$7" side="${8:-false}"
  printf '{"type":"assistant","timestamp":"2026-06-14T10:00:00Z","cwd":"/work/proj","requestId":"req_%s","isSidechain":%s,"message":{"id":"%s","model":"%s","usage":{"input_tokens":%s,"output_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":%s}}}\n' \
    "$sid" "$side" "$sid" "$model" "$in" "$out" "$cr" "$cw"
}

# ── The core guarantee: usage counted once per message, not once per line ──────

@test "a message split across repeated lines counts its usage exactly once" {
  # Given: msg_A appears on THREE lines, each repeating output=100
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
  } > "$PROJ/sessA.jsonl"

  # When
  python3 "$SCRIPT" --quiet

  # Then: output is 100 (deduped), NOT 300 (naive per-line sum)
  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "100" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].messages')" = "1" ]
}

@test "every token category is deduped, not just output" {
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
  } > "$PROJ/sessA.jsonl"

  python3 "$SCRIPT" --quiet

  [ "$(sget sessA '.models["claude-sonnet-4-6"].input')" = "10" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].cache_read')" = "1000" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].cache_write')" = "5" ]
}

@test "distinct messages on the same model are summed" {
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_B claude-sonnet-4-6 7  50  200  3
  } > "$PROJ/sessA.jsonl"

  python3 "$SCRIPT" --quiet

  [ "$(sget sessA '.models["claude-sonnet-4-6"].input')" = "17" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "150" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].messages')" = "2" ]
}

@test "tokens are split per model within one session" {
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_D claude-opus-4-8   1  2   3    4
  } > "$PROJ/sessA.jsonl"

  python3 "$SCRIPT" --quiet

  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "100" ]
  [ "$(sget sessA '.models["claude-opus-4-8"].output')" = "2" ]
}

# ── Exclusions that keep the count honest ─────────────────────────────────────

@test "sidechain (subagent) usage is excluded from the main session" {
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    asst_line A msg_S claude-sonnet-4-6 0  9999 0  0 true
  } > "$PROJ/sessA.jsonl"

  python3 "$SCRIPT" --quiet

  # 9999 from the sidechain line must not appear
  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "100" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].messages')" = "1" ]
}

@test "assistant lines without usage are ignored" {
  {
    asst_line A msg_A claude-sonnet-4-6 10 100 1000 5
    printf '{"type":"assistant","timestamp":"2026-06-14T10:00:00Z","message":{"id":"msg_C","model":"claude-sonnet-4-6"}}\n'
    printf '{"type":"user","timestamp":"2026-06-14T10:00:00Z","message":{"role":"user","content":"hi"}}\n'
  } > "$PROJ/sessA.jsonl"

  python3 "$SCRIPT" --quiet

  [ "$(sget sessA '.models["claude-sonnet-4-6"].messages')" = "1" ]
}

# ── Record shape & lifecycle ──────────────────────────────────────────────────

@test "a transcript with usage produces a store record named by session id" {
  asst_line A msg_A claude-sonnet-4-6 10 100 1000 5 > "$PROJ/sessA.jsonl"
  python3 "$SCRIPT" --quiet
  [ -f "$(record sessA)" ]
  [ "$(sget sessA '.session_id')" = "sessA" ]
  [ "$(sget sessA '.project')" = "proj" ]
  [ "$(sget sessA '.source')" = "claude-code" ]
}

@test "a transcript with no usage produces no store record" {
  printf '{"type":"user","timestamp":"2026-06-14T10:00:00Z","message":{"role":"user","content":"hi"}}\n' > "$PROJ/empty.jsonl"
  python3 "$SCRIPT" --quiet
  [ ! -f "$(record empty)" ]
}

@test "re-importing a grown transcript refreshes the stored counts (idempotent)" {
  # Given an imported session
  asst_line A msg_A claude-sonnet-4-6 10 100 1000 5 > "$PROJ/sessA.jsonl"
  python3 "$SCRIPT" --quiet
  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "100" ]

  # When the live transcript grows and we re-import
  asst_line A msg_B claude-sonnet-4-6 0 50 0 0 >> "$PROJ/sessA.jsonl"
  python3 "$SCRIPT" --quiet

  # Then the store reflects the new total, with no double-counting of msg_A
  [ "$(sget sessA '.models["claude-sonnet-4-6"].output')" = "150" ]
  [ "$(sget sessA '.models["claude-sonnet-4-6"].messages')" = "2" ]
}
