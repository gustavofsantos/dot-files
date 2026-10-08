#!/usr/bin/env bats

# Tests for inv-worker against a fake agent (INV_WORKER_CMD). The fake receives
# "--model M <card>" like the real CLI, and its behaviour is picked by FAKE_MODE.

WORKER="$BATS_TEST_DIRNAME/inv-worker"
INV="$BATS_TEST_DIRNAME/inv"

setup() {
  export INV_ROOT="$BATS_TEST_TMPDIR/inv"
  BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$BIN"
  export FAKE_CODES="$BATS_TEST_TMPDIR/codes"
  cat > "$BIN/fake-agent" <<EOF
#!/usr/bin/env bash
case "\$FAKE_MODE" in
  answer)
    "$INV" run demo/f --why "count" -- printf 'n\n7\n' > /dev/null 2>&1
    printf '{"result":"ANSWER: 7\\\\nCLAIMS:\\\\n- n=7 [step 1]"}\n' ;;
  # Keeps running steps past its lease, then hangs: only the hard deadline ends it.
  overrun)
    while :; do
      "$INV" run demo/f -- printf 'n\n1\n' > /dev/null 2>&1
      echo \$? >> "\$FAKE_CODES"
      sleep 0.3
    done ;;
  fail)
    echo "boom" >&2; exit 2 ;;
esac
EOF
  chmod +x "$BIN/fake-agent"
  export INV_WORKER_CMD="$BIN/fake-agent"
  printf '# demo/f — card\nQuestion: how many?\n' > "$BATS_TEST_TMPDIR/card.md"
  CARD="$BATS_TEST_TMPDIR/card.md"
}

front() { cat "$INV_ROOT/demo/f/front.md"; }

@test "a returned card lands in front.md with its result, and the lease is cleared" {
  FAKE_MODE=answer run "$WORKER" demo/f "$CARD" --model cheap
  [ "$status" -eq 0 ]
  [[ "$output" == *"card 1 returned"* ]]
  [[ "$output" == *"ANSWER: 7"* ]]
  [[ "$(front)" == *"question: how many?"* ]]
  [[ "$(front)" == *"status: returned"* ]]
  [[ "$(front)" == *"lease: -"* ]]
  [[ "$(front)" == *"## Card 1"* ]]
  [[ "$(front)" == *"Result of card 1 — returned (exit 0, steps 1..1)"* ]]
  [ ! -d "$INV_ROOT/demo/f/worker" ]
  [ ! -d "$INV_ROOT/demo/f/cards" ]
}

@test "past the lease inv refuses steps, and past the hard deadline the worker is killed" {
  FAKE_MODE=overrun run "$WORKER" demo/f "$CARD" --model cheap --soft 3s --hard 6s
  [ "$status" -eq 124 ]
  [[ "$output" == *"timed-out"* ]]
  grep -qx 4 "$FAKE_CODES"
  [[ "$(front)" == *"status: timed-out"* ]]
  # the lease stays expired, so a shell that escaped the kill cannot add steps
  [[ "$(front)" == *"closed: timed-out"* ]]
  run "$INV" run demo/f -- printf 'n\n1\n'
  [ "$status" -eq 4 ]
  [ -f "$INV_ROOT/demo/f/worker/1.out" ]
  # every step it ran before the lease is in the log
  [ "$(tail -n +2 "$INV_ROOT/demo/f/events.tsv" | wc -l)" -ge 1 ]
  sleep 0.5
  ! pgrep -f "$BIN/fake-agent" > /dev/null
}

@test "a failed worker keeps its raw output and stderr" {
  FAKE_MODE=fail run "$WORKER" demo/f "$CARD" --model cheap
  [ "$status" -eq 2 ]
  [[ "$(front)" == *"status: failed"* ]]
  grep -q boom "$INV_ROOT/demo/f/worker/1.err"
}

@test "a second card counts on and gets a fresh budget" {
  FAKE_MODE=answer "$WORKER" demo/f "$CARD" --model cheap --budget 3 > /dev/null
  FAKE_MODE=answer "$WORKER" demo/f "$CARD" --model cheap --budget 3 > /dev/null
  [[ "$(front)" == *"cards: 2"* ]]
  [[ "$(front)" == *"budget: 4"* ]]
  [[ "$(front)" == *"Result of card 2 — returned (exit 0, steps 2..2)"* ]]
}
