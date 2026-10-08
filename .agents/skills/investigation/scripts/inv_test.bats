#!/usr/bin/env bats

# Tests for inv. Every data command is a fake: fake-trino reads the SQL file it is
# given, sleeps for its "-- sleep N" line, prints "key<TAB>n" plus one row for its
# "-- key K" line, logs each call (to prove cache hits) and records how many copies
# ran at once (to prove the parallel limit).

INV="$BATS_TEST_DIRNAME/inv"

setup() {
  export INV_ROOT="$BATS_TEST_TMPDIR/inv"
  BIN="$BATS_TEST_TMPDIR/bin"
  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$BIN" "$WORK" "$BATS_TEST_TMPDIR/running"
  export FAKE_LOG="$BATS_TEST_TMPDIR/calls" FAKE_PEAKS="$BATS_TEST_TMPDIR/peaks"
  export FAKE_RUNNING="$BATS_TEST_TMPDIR/running"
  : > "$FAKE_LOG"; : > "$FAKE_PEAKS"

  cat > "$BIN/fake-trino" <<'EOF'
#!/usr/bin/env bash
file="$2"
key="$(sed -n 's/^-- key //p' "$file")"
nap="$(sed -n 's/^-- sleep //p' "$file")"
echo "$key" >> "$FAKE_LOG"
mkdir "$FAKE_RUNNING/$$"
ls "$FAKE_RUNNING" | wc -l >> "$FAKE_PEAKS"
[[ -z "$nap" ]] || sleep "$nap"
rmdir "$FAKE_RUNNING/$$"
printf 'key\tn\n%s\t1\n' "$key"
EOF
  # Spawns a grandchild that would leave a file behind if it outlived a kill.
  cat > "$BIN/slow-tree" <<EOF
#!/usr/bin/env bash
bash -c 'sleep 4; touch "$BATS_TEST_TMPDIR/orphan"' &
sleep 4
printf 'a\n1\n'
EOF
  chmod +x "$BIN"/*
  export PATH="$BIN:$PATH"
  cd "$WORK"
}

events() { tail -n +2 "$INV_ROOT/$1/events.tsv"; }
col() { events "$1" | awk -F'\t' -v s="$2" -v c="$3" '$1 == s { print $c }'; }

@test "run records a step under steps/ with eleven columns" {
  printf -- '-- key a\nselect 1\n' > q.sql
  run "$INV" run demo/f --why "first" --attach q.sql -- fake-trino --file q.sql
  [ "$status" -eq 0 ]
  [ -f "$INV_ROOT/demo/f/steps/1.sh" ]
  [ -f "$INV_ROOT/demo/f/steps/1.tsv" ]
  [ -f "$INV_ROOT/demo/f/steps/1.att/q.sql" ]
  [ "$(events demo/f | awk -F'\t' '{ print NF }')" = 11 ]
  [ "$(col demo/f 1 7)" = ok ]
  # the recorded command reads the snapshot, not the file that can change later
  grep -q "steps/1.att/q.sql" "$INV_ROOT/demo/f/steps/1.sh"
}

@test "a failed check exits 3" {
  run "$INV" run demo/f --expect-unique k -- printf 'k\nx\nx\n'
  [ "$status" -eq 3 ]
  [[ "$(col demo/f 1 7)" == FAIL:unique* ]]
}

@test "logs in the old layout still trace and continue" {
  dir="$INV_ROOT/old/f"
  mkdir -p "$dir/cmd" "$dir/out"
  printf 'step\tparent\ttimestamp\texit\trows\tout_sha\tcheck\twhy\n1\t0\t2026-10-07T10:00:00Z\t0\t1\tabc\tok\tlegacy step\n' > "$dir/events.tsv"
  echo "echo legacy" > "$dir/cmd/1.sh"
  printf 'a\n42\n' > "$dir/out/1.tsv"
  run "$INV" trace old/f 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"legacy step"* ]]
  [[ "$output" == *"42"* ]]
  run "$INV" run old/f -- printf 'a\n1\n'
  [ "$status" -eq 0 ]
  [ "$(col old/f 2 2)" = 1 ]
}

@test "concurrent runs get distinct step numbers" {
  for i in 1 2 3 4 5 6 7 8; do
    "$INV" run demo/f --parent 0 -- bash -c "sleep 0.2; printf 'v\n$i\n'" > /dev/null 2>&1 &
  done
  wait
  [ "$(events demo/f | cut -f1 | sort -n | tr '\n' ' ')" = "1 2 3 4 5 6 7 8 " ]
  [ "$(cat "$INV_ROOT"/demo/f/steps/*.tsv | grep -v v | sort -n | tr '\n' ' ')" = "1 2 3 4 5 6 7 8 " ]
}

@test "a step past its timeout is recorded as timeout and leaves no orphan" {
  run "$INV" run demo/f --timeout 1 -- slow-tree
  [ "$status" -eq 124 ]
  [ "$(col demo/f 1 7)" = timeout ]
  sleep 4
  [ ! -e "$BATS_TEST_TMPDIR/orphan" ]
}

@test "a TERM during a step is recorded as killed" {
  "$INV" run demo/f -- sleep 5 > /dev/null 2>&1 &
  pid=$!
  sleep 0.5
  kill -TERM "$pid"
  wait "$pid" || true
  [ "$(col demo/f 1 7)" = killed ]
}

@test "with as_of pinned, relative time is rejected and nothing is recorded" {
  "$INV" as-of demo "2026-10-07 06:00:00"
  printf 'select * from t where ts > NOW ()\n' > q.sql
  run "$INV" run demo/f --attach q.sql -- cat q.sql
  [ "$status" -eq 3 ]
  run "$INV" run demo/f -- echo "select current_date"
  [ "$status" -eq 3 ]
  [ ! -f "$INV_ROOT/demo/f/events.tsv" ] || [ -z "$(events demo/f)" ]
}

@test "{as_of} is rendered into the snapshot the command reads" {
  "$INV" as-of demo "2026-10-07 06:00:00"
  printf "h\nTIMESTAMP '{as_of}'\n" > q.sql
  run "$INV" run demo/f --attach q.sql -- cat q.sql
  [ "$status" -eq 0 ]
  [[ "$output" == *"TIMESTAMP '2026-10-07 06:00:00'"* ]]
  grep -q '{as_of}' q.sql
}

@test "{as_of} without a pinned as_of is an error" {
  printf "h\n'{as_of}'\n" > q.sql
  run "$INV" run demo/f --attach q.sql -- cat q.sql
  [ "$status" -eq 1 ]
  [[ "$output" == *"none is pinned"* ]]
}

@test "an expired lease refuses new steps with exit 4" {
  "$INV" _front set demo/f lease "$(( $(date +%s) - 1 )) (past)"
  run "$INV" run demo/f -- printf 'a\n1\n'
  [ "$status" -eq 4 ]
  [[ "$output" == *"time is up"* ]]
}

@test "a spent budget refuses new steps with exit 4" {
  "$INV" _front set demo/f budget 1
  "$INV" run demo/f -- printf 'a\n1\n'
  run "$INV" run demo/f -- printf 'a\n1\n'
  [ "$status" -eq 4 ]
}

params() {
  printf 'key\tnap\n' > params.tsv
  local k
  for k in "$@"; do printf '%s\t0\n' "$k" >> params.tsv; done
  printf -- '-- key {key}\n-- sleep {nap}\nselect 1\n' > q.sql.tmpl
}

@test "map runs one sibling step per row and merges them tagged by param" {
  params a b c
  "$INV" run demo/f -- printf 'x\n1\n'
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  for s in 2 3 4; do [ "$(col demo/f $s 2)" = 1 ]; done
  [ "$(col demo/f 5 2)" = 1 ]
  [ "$(col demo/f 5 7)" = ok ]
  merged="$INV_ROOT/demo/f/steps/5.tsv"
  [ "$(head -n 1 "$merged")" = "$(printf 'key\tnap\tstep\tkey\tn')" ]
  [ "$(tail -n +2 "$merged" | cut -f1 | sort | tr '\n' ' ')" = "a b c " ]
  [[ "$output" == *"$(printf 'b\t0\t')"* ]]
}

@test "a map rerun reuses rows that already ran ok" {
  params a b c
  "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$(wc -l < "$FAKE_LOG")" -eq 3 ]
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  [ "$(wc -l < "$FAKE_LOG")" -eq 3 ]
  [ "$(col demo/f 5 7)" = ok ]
  [[ "$(col demo/f 5 8)" == *"cached=3"* ]]
  run "$INV" map demo/f --fresh --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$(wc -l < "$FAKE_LOG")" -eq 6 ]
}

@test "a timed-out row fails the merge, and a rerun retries only that row" {
  printf 'key\tnap\na\t0\nb\t3\nc\t0\n' > params.tsv
  printf -- '-- key {key}\n-- sleep {nap}\nselect 1\n' > q.sql.tmpl
  run "$INV" map demo/f --timeout 1 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 3 ]
  [ "$(events demo/f | awk -F'\t' '$7 == "timeout"' | wc -l)" -eq 1 ]
  [[ "$(col demo/f 4 7)" == FAIL:incomplete:timeout=1* ]]
  : > "$FAKE_LOG"
  run "$INV" map demo/f --timeout 10 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_LOG")" = b ]
}

@test "map never runs more rows at once than --parallel" {
  printf 'key\tnap\n' > params.tsv
  for k in a b c d e f; do printf '%s\t0.5\n' "$k" >> params.tsv; done
  printf -- '-- key {key}\n-- sleep {nap}\nselect 1\n' > q.sql.tmpl
  run "$INV" map demo/f --parallel 2 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  [ "$(sort -n "$FAKE_PEAKS" | tail -n 1)" -eq 2 ]
}

@test "a map costs one step of the budget" {
  params a b c d e
  "$INV" _front set demo/f budget 2
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  run "$INV" run demo/f -- printf 'a\n1\n'
  [ "$status" -eq 0 ]
  run "$INV" map demo/f --fresh --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 4 ]
}

@test "a lease expiring mid-map skips the rows not started and exits 4" {
  printf 'key\tnap\na\t4\nb\t0\nc\t0\n' > params.tsv
  printf -- '-- key {key}\n-- sleep {nap}\nselect 1\n' > q.sql.tmpl
  "$INV" _front set demo/f lease "$(( $(date +%s) + 2 )) (soon)"
  run "$INV" map demo/f --parallel 1 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 4 ]
  [ "$(cat "$FAKE_LOG")" = a ]
  [[ "$(col demo/f 2 7)" == FAIL:incomplete:skipped=2* ]]
}

@test "map refuses a template with a placeholder no column fills" {
  printf 'key\na\n' > params.tsv
  printf -- '-- key {key} {missing}\n' > q.sql.tmpl
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 1 ]
  [[ "$output" == *"{missing}"* ]]
}

@test "map renders {as_of} and lints the template" {
  "$INV" as-of demo "2026-10-07"
  printf 'key\na\n' > params.tsv
  printf -- "-- key {key}\nwhere ts <= TIMESTAMP '{as_of}'\n" > q.sql.tmpl
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  grep -q "TIMESTAMP '2026-10-07'" "$INV_ROOT"/demo/f/steps/1.att/q.sql
  printf -- "-- key {key}\nwhere ts <= current_timestamp\n" > q.sql.tmpl
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 3 ]
}

@test "watermark probes are steps, later steps carry the stamp, and moved data is reported" {
  "$INV" as-of demo "2026-10-07 06:00:00"
  echo "2026-10-07 05:00:00" > "$BATS_TEST_TMPDIR/wm"
  "$INV" run demo/f --why "count" -- bash -c "printf 'n\n1\n' # from lake.sales.orders"
  run "$INV" watermark demo --probe "printf 'wm\n%s\n' \"\$(cat $BATS_TEST_TMPDIR/wm)\" # {table}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lake.sales.orders"* ]]
  [ "$(events demo/watermark | wc -l)" -eq 1 ]
  "$INV" run demo/f -- bash -c "printf 'n\n2\n' # from lake.sales.orders"
  [ "$(col demo/f 2 11)" = "w1@2026-10-07 05:00:00" ]
  run "$INV" trace demo/f 2
  [[ "$output" == *"data=w1@2026-10-07 05:00:00"* ]]
  [[ "$output" == *"ran=20"* ]]
  [[ "$output" == *"as_of: 2026-10-07 06:00:00"* ]]
  echo "2026-10-07 07:30:00" > "$BATS_TEST_TMPDIR/wm"
  run "$INV" watermark demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Data moved"* ]]
  [[ "$output" == *"demo/f#2 (w1@"* ]]
  [[ "$output" != *"demo/f#1 "* ]]
}

@test "an unchanged re-probe keeps the round, so stamps stay comparable" {
  echo "2026-10-07 05:00:00" > "$BATS_TEST_TMPDIR/wm"
  "$INV" watermark demo --table lake.s.t --probe "printf 'wm\n%s\n' \"\$(cat $BATS_TEST_TMPDIR/wm)\" # {table}" > /dev/null
  run "$INV" watermark demo
  [[ "$output" == *"w1@2026-10-07 05:00:00 (unchanged)"* ]]
  [ "$(tail -n +2 "$INV_ROOT/demo/watermarks.tsv" | cut -f1 | sort -u)" = 1 ]
}

@test "a merge of rows from different watermark rounds is stamped mixed" {
  echo "2026-10-07 05:00:00" > "$BATS_TEST_TMPDIR/wm"
  "$INV" watermark demo --table lake.s.t --probe "printf 'wm\n%s\n' \"\$(cat $BATS_TEST_TMPDIR/wm)\" # {table}" > /dev/null
  params a b
  "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql} > /dev/null 2>&1
  [[ "$(col demo/f 3 11)" == "w1@2026-10-07 05:00:00" ]]
  echo "2026-10-07 09:00:00" > "$BATS_TEST_TMPDIR/wm"
  "$INV" watermark demo > /dev/null
  params a b c
  run "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$(col demo/f 5 11)" = "mixed:w1,w2" ]
  [[ "$output" == *"--fresh"* ]]
}

@test "a cached row is not reused when the map asks for a stricter check" {
  params a
  "$INV" map demo/f --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql} > /dev/null 2>&1
  "$INV" map demo/f --expect-unique key --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql} > /dev/null 2>&1
  [ "$(wc -l < "$FAKE_LOG")" -eq 2 ]
}

@test "two attachments with the same name are refused before running" {
  mkdir a b
  printf 'x\n' > a/f.tsv
  printf 'y\n' > b/f.tsv
  run "$INV" run demo/f --attach a/f.tsv --attach b/f.tsv -- cat a/f.tsv b/f.tsv
  [ "$status" -eq 1 ]
  [[ "$output" == *"two --attach files are named f.tsv"* ]]
  [ ! -f "$INV_ROOT/demo/f/events.tsv" ]
}

@test "a killed map keeps finished rows, records the rest as killed, and resumes" {
  printf 'key\tnap\na\t0\nb\t0\nc\t4\nd\t4\n' > params.tsv
  printf -- '-- key {key}\n-- sleep {nap}\nselect 1\n' > q.sql.tmpl
  "$INV" map demo/f --parallel 2 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql} > /dev/null 2>&1 &
  pid=$!
  sleep 1.5
  kill -TERM "$pid"
  wait "$pid" || true
  [ "$(events demo/f | awk -F'\t' '$7 == "ok"' | wc -l)" -eq 2 ]
  [ "$(events demo/f | awk -F'\t' '$7 == "killed"' | wc -l)" -eq 2 ]
  ! grep -q '_merge' "$INV_ROOT"/demo/f/steps/*.sh
  sleep 0.5
  ! pgrep -f "sleep 4" > /dev/null
  : > "$FAKE_LOG"
  run "$INV" map demo/f --timeout 10 --template q.sql.tmpl --params params.tsv -- fake-trino --file {sql}
  [ "$status" -eq 0 ]
  [ "$(sort "$FAKE_LOG" | tr '\n' ' ')" = "c d " ]
}

@test "board shows each front's status from front.md" {
  "$INV" run demo/f -- printf 'a\n1\n'
  "$INV" _front set demo/f question "how many?"
  "$INV" _front set demo/f status running
  "$INV" _front set demo/f lease "$(( $(date +%s) - 5 )) (past)"
  run "$INV" board demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"late"* ]]
  [[ "$output" == *"how many?"* ]]
}
