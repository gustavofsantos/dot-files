#!/usr/bin/env bats

# Tests for sessions.sh, alongside it.
#
# Run: bats .agents/skills/reflect/scripts/sessions_test.bats
#
# Isolation strategy:
#   REFLECT_CLAUDE_PROJECTS / REFLECT_CURSOR_PROJECTS → fixture transcript trees
#   REFLECT_STATE → a per-test state file, so the real analyzed set is never touched.

SCRIPT="$BATS_TEST_DIRNAME/sessions.sh"

setup() {
  T=$(mktemp -d)
  export REFLECT_CLAUDE_PROJECTS="$T/claude"
  export REFLECT_CURSOR_PROJECTS="$T/cursor"
  export REFLECT_STATE="$T/state/analyzed.tsv"
  mkdir -p "$T/claude/-home-me-app" "$T/cursor"
}

teardown() {
  rm -rf "$T"
}

claude_user() { printf '{"type":"user","cwd":"/nowhere/app","message":{"content":%s}}\n' "$(jq -Rn --arg t "$1" '$t')"; }
claude_said() { printf '{"type":"assistant","message":{"id":"m","content":[{"type":"text","text":%s}]}}\n' "$(jq -Rn --arg t "$1" '$t')"; }

# A two-turn Claude conversation in project dir $1 (default -home-me-app), session $2.
claude_session() {
  local dir="$T/claude/${1:--home-me-app}" id=${2:-s1}
  mkdir -p "$dir"
  {
    claude_user "run the tests"
    claude_said "Running npm test."
    claude_user "no, this repo uses make check"
    claude_said "Understood, make check."
  } > "$dir/$id.jsonl"
}

cursor_session() {
  local dir="$T/cursor/home-me-app"
  mkdir -p "$dir/agent-transcripts/$1"
  echo '[info] Getting tree structure for workspacePath=/nowhere/app' > "$dir/worker.log"
  {
    echo '{"role":"user","message":{"content":[{"type":"text","text":"<timestamp>Mon</timestamp>\n<user_query>\ninvoices close on reconciliation\n</user_query>"}]}}'
    echo '{"role":"assistant","message":{"content":[{"type":"text","text":"Noted."}]}}'
    echo '{"role":"user","message":{"content":[{"type":"text","text":"<user_query>and never before</user_query>"}]}}'
  } > "$dir/agent-transcripts/$1/$1.jsonl"
}

# ── Set logic ──────────────────────────────────────────────────────────────────

@test "with no state, every session on disk is pending" {
  claude_session
  cursor_session c1
  run bash "$SCRIPT" pending
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 2 ]
  [[ "$output" == *$'claude\ts1\t0\t4'* ]]
  [[ "$output" == *$'cursor\tc1\t0\t3'* ]]
}

@test "after a digest is committed, nothing is pending" {
  claude_session
  cursor_session c1
  bash "$SCRIPT" digest --out "$T/d"
  bash "$SCRIPT" commit "$T/d"
  run bash "$SCRIPT" pending
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a digest that is never committed leaves its sessions pending" {
  claude_session
  bash "$SCRIPT" digest --out "$T/d"
  run bash "$SCRIPT" pending
  [[ "$output" == *$'claude\ts1\t0\t4'* ]]
}

@test "a session that grew is pending from its first unread line" {
  claude_session
  bash "$SCRIPT" digest --out "$T/d"
  bash "$SCRIPT" commit "$T/d"
  claude_user "also skip the flaky suite" >> "$T/claude/-home-me-app/s1.jsonl"
  run bash "$SCRIPT" pending
  [[ "$output" == *$'claude\ts1\t4\t5'* ]]

  bash "$SCRIPT" digest --out "$T/d2"
  run cat "$T/d2/claude-s1.md"
  [[ "$output" == *"also skip the flaky suite"* ]]
  [[ "$output" != *"make check"* ]]
}

@test "a transcript shorter than recorded is read again whole" {
  claude_session
  mkdir -p "$T/state"
  printf 'claude\ts1\t99\n' > "$REFLECT_STATE"
  run bash "$SCRIPT" pending
  [[ "$output" == *$'claude\ts1\t0\t4'* ]]
}

@test "--limit digests a batch and leaves the rest pending" {
  claude_session -home-me-app a
  claude_session -home-me-app b
  claude_session -home-me-app c
  run bash "$SCRIPT" digest --limit 2 --out "$T/d"
  [[ "$output" == *"1 still pending"* ]]
  bash "$SCRIPT" commit "$T/d"
  run bash "$SCRIPT" pending
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}

@test "seed records every session on disk without digesting any" {
  claude_session
  cursor_session c1
  bash "$SCRIPT" seed
  run bash "$SCRIPT" pending
  [ -z "$output" ]
}

# ── What gets digested ─────────────────────────────────────────────────────────

@test "a digest keeps the conversation and names the repository" {
  claude_session
  bash "$SCRIPT" digest --out "$T/d"
  run cat "$T/d/claude-s1.md"
  [[ "$output" == *"- repo: /nowhere/app"* ]]
  [[ "$output" == *"**user:** no, this repo uses make check"* ]]
  [[ "$output" == *"**assistant:** Understood, make check."* ]]
}

@test "a cursor digest unwraps the user query and uses the workspace path" {
  cursor_session c1
  bash "$SCRIPT" digest --out "$T/d"
  run cat "$T/d/cursor-c1.md"
  [[ "$output" == *"- repo: /nowhere/app"* ]]
  [[ "$output" == *"**user:** invoices close on reconciliation"* ]]
  [[ "$output" != *"timestamp"* ]]
}

@test "a failed tool call is shown with the command that failed" {
  claude_session
  {
    echo '{"type":"assistant","message":{"id":"m2","content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"npm test"}}]}}'
    echo '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","is_error":true,"content":"npm: not found"}]}}'
    echo '{"type":"assistant","message":{"id":"m3","content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"ls"}}]}}'
    echo '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t2","is_error":false,"content":"SECRET-OUTPUT"}]}}'
  } >> "$T/claude/-home-me-app/s1.jsonl"
  bash "$SCRIPT" digest --out "$T/d"
  run cat "$T/d/claude-s1.md"
  [[ "$output" == *'**tool failed:** Bash `npm test` → npm: not found'* ]]
  [[ "$output" != *"SECRET-OUTPUT"* ]]
}

@test "sidechain, meta and thinking lines stay out of the digest" {
  claude_session
  {
    echo '{"type":"user","isSidechain":true,"message":{"content":"sidechain prompt"}}'
    echo '{"type":"user","isMeta":true,"message":{"content":"meta caveat"}}'
    echo '{"type":"assistant","message":{"id":"m4","content":[{"type":"thinking","thinking":"private musing"}]}}'
  } >> "$T/claude/-home-me-app/s1.jsonl"
  bash "$SCRIPT" digest --out "$T/d"
  run cat "$T/d/claude-s1.md"
  [[ "$output" != *"sidechain prompt"* ]]
  [[ "$output" != *"meta caveat"* ]]
  [[ "$output" != *"private musing"* ]]
}

@test "subagent transcripts are never listed" {
  claude_session
  mkdir -p "$T/claude/-home-me-app/s1/subagents"
  cp "$T/claude/-home-me-app/s1.jsonl" "$T/claude/-home-me-app/s1/subagents/agent-x.jsonl"
  run bash "$SCRIPT" pending
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}

@test "scratch, trivial and reflect sessions are recorded but not digested" {
  claude_session -tmp scratch
  claude_user "hi" > "$T/claude/-home-me-app/trivial.jsonl"
  claude_session -home-me-app reflecting
  claude_said "bash scripts/sessions.sh digest --limit 20" >> "$T/claude/-home-me-app/reflecting.jsonl"
  bash "$SCRIPT" digest --out "$T/d"
  run cut -f2,4 "$T/d/manifest.tsv"
  [[ "$output" == *$'scratch\tskipped:scratch'* ]]
  [[ "$output" == *$'trivial\tskipped:trivial'* ]]
  [[ "$output" == *$'reflecting\tskipped:reflect-run'* ]]
  [ ! -e "$T/d/claude-scratch.md" ]

  bash "$SCRIPT" commit "$T/d"
  run bash "$SCRIPT" pending
  [ -z "$output" ]
}

@test "a single-prompt session with substance is digested" {
  mkdir -p "$T/claude/-home-me-app"
  {
    claude_user "find out why settlement retries twice"
    claude_said "$(printf 'The retry lives in ledger/settle.clj: settle! re-enqueues on timeout, and the consumer also retries. %.0s' 1 2 3)"
  } > "$T/claude/-home-me-app/solo.jsonl"
  bash "$SCRIPT" digest --out "$T/d"
  run cat "$T/d/claude-solo.md"
  [[ "$output" == *"ledger/settle.clj"* ]]
}

@test "a compaction summary is not mistaken for something the user said" {
  claude_session
  {
    echo '{"type":"user","isCompactSummary":true,"message":{"content":"This session is being continued from a previous conversation. no, this repo uses make check"}}'
    echo '{"type":"user","message":{"content":"This session is being continued from a previous conversation. summary"}}'
  } >> "$T/claude/-home-me-app/s1.jsonl"
  bash "$SCRIPT" digest --out "$T/d"
  run grep -c "make check" "$T/d/claude-s1.md"
  [ "$output" -eq 2 ]
  run cat "$T/d/claude-s1.md"
  [[ "$output" != *"being continued"* ]]
}
