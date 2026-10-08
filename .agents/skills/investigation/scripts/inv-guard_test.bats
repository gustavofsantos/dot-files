#!/usr/bin/env bats

# Tests for inv-guard with Claude Code PreToolUse payloads.

GUARD="$BATS_TEST_DIRNAME/inv-guard"

setup() {
  export INV_ROOT="$BATS_TEST_TMPDIR/inv"
  mkdir -p "$INV_ROOT"
  echo "trino-q" > "$INV_ROOT/guard"
}

call() {
  jq -n --arg c "$1" '{session_id: "s1", tool_input: {command: $c}}' | "$GUARD"
}

@test "an unbound session runs guarded commands freely" {
  run call "trino-q --file q.sql"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "inv map binds the session, then a bare guarded command is denied" {
  run call "inv map demo/f --template q.sql.tmpl --params p.tsv -- trino-q --file {sql}"
  [ -z "$output" ]
  run call "trino-q --file q.sql"
  [[ "$output" == *'"permissionDecision": "deny"'* ]]
  [[ "$output" == *"investigating 'demo/f'"* ]]
}

@test "a guarded command wrapped in inv run is allowed in a bound session" {
  call "inv run demo/f -- trino-q --file a.sql" > /dev/null
  run call "inv run demo/f --why x -- trino-q --file b.sql"
  [ -z "$output" ]
}
