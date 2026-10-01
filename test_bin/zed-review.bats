#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../bin/zed-review"

setup() {
  TEST_ROOT=$(mktemp -d)
  CAPTURE="$TEST_ROOT/rvw-args"
  LIST_JSON="$TEST_ROOT/list.json"
  export CAPTURE LIST_JSON

  # rvw stub: records the args of a write, answers `list` from LIST_JSON.
  cat >"$TEST_ROOT/rvw" <<'EOF'
#!/bin/sh
if [ "$1" = list ]; then
  cat "$LIST_JSON"
  exit 0
fi
printf '%s\n' "$@" >"$CAPTURE"
printf 'r7\n'
EOF
  chmod +x "$TEST_ROOT/rvw"

  # Editor stub: "types" $TYPED into the file it is handed. Its stdout must not
  # leak into the comment.
  cat >"$TEST_ROOT/editor" <<'EOF'
#!/bin/sh
printf '%s' "$TYPED" >"$1"
echo "editor noise"
EOF
  chmod +x "$TEST_ROOT/editor"

  mkdir -p "$TEST_ROOT/repo/src"
  printf 'a\nb\nc\nd\ne\n' >"$TEST_ROOT/repo/src/main.lua"

  export RVW_CMD="$TEST_ROOT/rvw"
  export ZED_REVIEW_EDITOR="$TEST_ROOT/editor"
  export ZED_FILE="$TEST_ROOT/repo/src/main.lua"
  export ZED_WORKTREE_ROOT="$TEST_ROOT/repo"
  export ZED_LANGUAGE=Lua
  unset ZED_SELECTED_TEXT
}

teardown() {
  rm -rf "$TEST_ROOT"
}

expected() {
  printf '%s\n' "$@"
}

@test "add queues the cursor line when nothing is selected" {
  export ZED_ROW=3 TYPED="Rename this."
  run "$SCRIPT" add
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "Review queued r7: main.lua:3" ]
  [ "$(<"$CAPTURE")" = "$(expected add --file "$ZED_FILE" --lines 3 \
    --comment "Rename this." --format ids --filetype lua)" ]
}

@test "add spans a characterwise selection from its first to its last line" {
  export ZED_ROW=2 ZED_SELECTED_TEXT=$'b\nc\nd' TYPED=$'Two lines\nof comment.'
  run "$SCRIPT" add
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "Review queued r7: main.lua:2-4" ]
  grep -qx -- 2-4 "$CAPTURE"
  [ "$(sed -n '/^--comment$/,/^--format$/p' "$CAPTURE")" = "$(expected --comment "Two lines" "of comment." --format)" ]
}

@test "add does not count the newline that ends a linewise selection" {
  export ZED_ROW=2 ZED_SELECTED_TEXT=$'b\nc\n' TYPED="x"
  run "$SCRIPT" add
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "Review queued r7: main.lua:2-3" ]
}

@test "add maps Zed language names to nvim filetypes" {
  export ZED_ROW=1 TYPED="x" ZED_LANGUAGE="Shell Script"
  run "$SCRIPT" add
  grep -qx sh "$CAPTURE"
  export ZED_LANGUAGE="TSX"
  run "$SCRIPT" add
  grep -qx typescriptreact "$CAPTURE"
}

@test "add queues nothing when the comment is left empty" {
  export ZED_ROW=1 TYPED=$'  \n\n'
  run "$SCRIPT" add
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "Review: empty comment, nothing queued" ]
  [ ! -e "$CAPTURE" ]
}

@test "add runs rvw from the file's directory so it resolves that workspace" {
  cat >"$TEST_ROOT/rvw" <<'EOF'
#!/bin/sh
pwd >"$CAPTURE"
EOF
  export ZED_ROW=1 TYPED="x"
  run "$SCRIPT" add
  [ "$(<"$CAPTURE")" = "$TEST_ROOT/repo/src" ]
}

@test "add fails without an active file" {
  unset ZED_FILE
  run "$SCRIPT" add
  [ "$status" -eq 1 ]
  [[ "$output" == *"no file is active"* ]]
}

@test "edit rewrites the comment nearest the cursor, pre-filled with its text" {
  cat >"$LIST_JSON" <<EOF
{"reviews": [
  {"id": "r1", "path": "$ZED_FILE", "start_line": 1, "end_line": 1, "comment": "far"},
  {"id": "r2", "path": "$ZED_FILE", "start_line": 4, "end_line": 5, "comment": "near"}
]}
EOF
  cat >"$TEST_ROOT/editor" <<'EOF'
#!/bin/sh
cp "$1" "$CAPTURE.prefill"
printf 'near, edited' >"$1"
EOF
  export ZED_ROW=3
  run "$SCRIPT" edit
  [ "$status" -eq 0 ]
  [ "$(<"$CAPTURE.prefill")" = "near" ]
  [ "$(<"$CAPTURE")" = "$(expected edit r2 --comment "near, edited")" ]
  [ "${lines[-1]}" = "Review updated r2: main.lua:4-5" ]
}

@test "edit prefers a range holding the cursor, then queue order on a tie" {
  cat >"$LIST_JSON" <<EOF
{"reviews": [
  {"id": "r0", "path": "$ZED_FILE", "start_line": 5, "end_line": 5, "comment": "next line"},
  {"id": "r1", "path": "$ZED_FILE", "start_line": 1, "end_line": 5, "comment": "wide"},
  {"id": "r2", "path": "$ZED_FILE", "start_line": 4, "end_line": 4, "comment": "on line"}
]}
EOF
  export ZED_ROW=4 TYPED="x"
  run "$SCRIPT" edit
  [ "${lines[-1]}" = "Review updated r1: main.lua:1-5" ]
}

@test "edit fails when the file has no queued comment" {
  echo '{"reviews": []}' >"$LIST_JSON"
  export ZED_ROW=1
  run "$SCRIPT" edit
  [ "$status" -eq 1 ]
  [[ "$output" == *"no queued comment near line 1 of main.lua"* ]]
}

@test "withdraw rejects the nearest comment with the given reason" {
  cat >"$LIST_JSON" <<EOF
{"reviews": [{"id": "r3", "path": "$ZED_FILE", "start_line": 2, "end_line": 2, "comment": "nit"}]}
EOF
  export ZED_ROW=2
  run "$SCRIPT" withdraw <<<"done already"
  [ "$status" -eq 0 ]
  [ "$(<"$CAPTURE")" = "$(expected reject r3 --note "done already")" ]
}

@test "withdraw falls back to a default reason" {
  cat >"$LIST_JSON" <<EOF
{"reviews": [{"id": "r3", "path": "$ZED_FILE", "start_line": 2, "end_line": 2, "comment": "nit"}]}
EOF
  export ZED_ROW=2
  run "$SCRIPT" withdraw </dev/null
  [ "$status" -eq 0 ]
  [ "$(<"$CAPTURE")" = "$(expected reject r3 --note withdrawn)" ]
}

@test "list prints the queue as clickable path:line entries" {
  cat >"$LIST_JSON" <<EOF
{"reviews": [
  {"id": "r1", "path": "/w/a.lua", "start_line": 3, "end_line": 3, "comment": "one\ntwo", "author": "gustavo", "lane": null},
  {"id": "r2", "path": "/w/b.lua", "start_line": 1, "end_line": 4, "comment": "x", "author": null, "lane": "feat"}
]}
EOF
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' \
    "/w/a.lua:3: r1. [3] @gustavo one" \
    "/w/b.lua:1: r2. [1-4] #feat x")" ]
}

@test "list says so when the queue is empty" {
  echo '{"reviews": []}' >"$LIST_JSON"
  run "$SCRIPT" list
  [ "$output" = "Review: the queue is empty for this workspace" ]
}

@test "submit sends the decision and the typed summary" {
  export TYPED="Looks good."
  run "$SCRIPT" submit approve
  [ "$status" -eq 0 ]
  [ "$(<"$CAPTURE")" = "$(expected submit --decision approve --summary "Looks good." --format ids)" ]
  [ "${lines[-1]}" = "Review submitted r7" ]
}

@test "submit rejects an unknown decision" {
  run "$SCRIPT" submit maybe
  [ "$status" -eq 1 ]
  [[ "$output" == *"decision must be"* ]]
}
