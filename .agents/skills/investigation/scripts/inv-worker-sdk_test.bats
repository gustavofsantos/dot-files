#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# Tests for inv-worker-sdk against a fake @cursor/sdk installed in INV_SDK_DIR. The fake
# follows the documented API (Agent.create, agent.send, run.stream/wait/cancel/steer),
# logs every call to FAKE_SDK_LOG, and picks its behaviour from FAKE_SDK_MODE.

RUNNER="$BATS_TEST_DIRNAME/inv-worker-sdk.ts"
WORKER="$BATS_TEST_DIRNAME/inv-worker"
INV="$BATS_TEST_DIRNAME/inv"

setup() {
  command -v bun > /dev/null || skip "bun is not installed"
  export INV_ROOT="$BATS_TEST_TMPDIR/inv"
  export INV_SDK_DIR="$BATS_TEST_TMPDIR/sdk"
  export INV_SDK_STORE="$BATS_TEST_TMPDIR/agents"
  export FAKE_SDK_LOG="$BATS_TEST_TMPDIR/sdk.log"
  export INV_WORKER_LIVE="$BATS_TEST_TMPDIR/live.log"
  pkg="$INV_SDK_DIR/node_modules/@cursor/sdk"
  mkdir -p "$pkg"
  echo '{"name":"@cursor/sdk","version":"0.0.0-fake","type":"module","exports":{".":"./index.js"}}' > "$pkg/package.json"
  cat > "$pkg/index.js" <<'EOF'
import { appendFileSync } from "node:fs";
const log = (line) => appendFileSync(process.env.FAKE_SDK_LOG, line + "\n");
const mode = process.env.FAKE_SDK_MODE ?? "answer";

export class JsonlLocalAgentStore { constructor(path) { this.path = path; } }

class Run {
  id = "run-1";
  #cancelled = false;
  #release = () => {};
  async *stream() {
    if (mode === "hang") {
      const keepAlive = setInterval(() => {}, 1000);
      await new Promise((resolve) => { this.#release = resolve; });
      clearInterval(keepAlive);
      return;
    }
    yield { type: "tool_call", call_id: "c1", name: "shell", status: "running", args: { command: "inv run demo/f -- trino-q" } };
    yield { type: "tool_call", call_id: "c1", name: "shell", status: "completed", result: "SECRET_ROW 42" };
    yield { type: "assistant", message: { content: [{ type: "text", text: "ANSWER: 42" }] } };
  }
  async wait() {
    if (this.#cancelled) return { id: this.id, status: "cancelled" };
    if (mode === "error") return { id: this.id, status: "error", error: { message: "boom" } };
    return { id: this.id, status: "finished", result: "ANSWER: 42", durationMs: 5, usage: { totalTokens: 10 } };
  }
  async cancel() { log("cancel"); this.#cancelled = true; this.#release(); }
  async steer(text) { log("steer " + text); return "complete_delivered"; }
}

export const Agent = {
  async create(options) {
    log("create " + JSON.stringify({ model: options.model, settingSources: options.local.settingSources, store: !!options.local.store }));
    return { send: async (card) => { log("send " + card.split("\n")[0]); return new Run(); }, close() { log("close"); } };
  },
};
EOF
  : > "$FAKE_SDK_LOG"
  printf '# demo/f — card\nQuestion: how many?\n' > "$BATS_TEST_TMPDIR/card.md"
  CARD="$BATS_TEST_TMPDIR/card.md"
}

@test "a finished run prints one JSON result and logs tool calls without their results" {
  run --separate-stderr "$RUNNER" --model cheap "$(< "$CARD")"
  [ "$status" -eq 0 ]
  [ "$(jq -r .status <<< "$output")" = finished ]
  [ "$(jq -r .result <<< "$output")" = "ANSWER: 42" ]
  grep -q 'create {"model":{"id":"cheap"},"settingSources":\["project","user"\],"store":true}' "$FAKE_SDK_LOG"
  grep -q "tool shell running .*inv run demo/f" "$INV_WORKER_LIVE"
  grep -q "tool shell completed" "$INV_WORKER_LIVE"
  ! grep -q SECRET_ROW "$INV_WORKER_LIVE"
}

@test "an errored run exits 1 with the error in the JSON" {
  FAKE_SDK_MODE=error run --separate-stderr "$RUNNER" --model cheap "$(< "$CARD")"
  [ "$status" -eq 1 ]
  [ "$(jq -r .error <<< "$output")" = boom ]
}

@test "TERM cancels the run and exits 143 promptly" {
  out="$BATS_TEST_TMPDIR/out.json"
  FAKE_SDK_MODE=hang "$RUNNER" --model cheap "$(< "$CARD")" > "$out" &
  pid=$!
  sleep 1
  started=$(date +%s)
  kill -TERM "$pid"
  set +e; wait "$pid"; code=$?; set -e
  [ "$code" -eq 143 ]
  [ $(( $(date +%s) - started )) -le 3 ]
  grep -qx cancel "$FAKE_SDK_LOG"
  [ "$(jq -r .status "$out")" = cancelled ]
}

@test "when the lease passes the agent is steered once to return" {
  FAKE_SDK_MODE=hang INV_LEASE_AT=$(( $(date +%s) + 1 )) "$RUNNER" --model cheap "$(< "$CARD")" > /dev/null &
  pid=$!
  sleep 2.5
  kill -TERM "$pid"
  wait "$pid" || true
  [ "$(grep -c '^steer Time is up' "$FAKE_SDK_LOG")" -eq 1 ]
}

@test "a missing SDK says how to install it, and nothing is fetched or run" {
  rm -rf "$INV_SDK_DIR"
  run "$RUNNER" --model cheap "card"
  [ "$status" -eq 1 ]
  [[ "$output" == *"inv-worker-sdk --install"* ]]
  [ ! -s "$FAKE_SDK_LOG" ]
  [ ! -e "$INV_SDK_STORE" ]
}

@test "through inv-worker, a hung run times out, keeps its live log and closes the lease" {
  unset INV_WORKER_LIVE
  FAKE_SDK_MODE=hang INV_WORKER_CMD="$RUNNER" run "$WORKER" demo/f "$CARD" --model cheap --soft 1s --hard 3s
  [ "$status" -eq 124 ]
  [[ "$output" == *"timed-out"* ]]
  grep -qx cancel "$FAKE_SDK_LOG"
  grep -q "^steer" "$FAKE_SDK_LOG"
  grep -q "TERM: cancelling" "$INV_ROOT/demo/f/worker/1.live"
  [ ! -f "$INV_ROOT/demo/f/live.log" ]
  [[ "$(cat "$INV_ROOT/demo/f/front.md")" == *"closed: timed-out"* ]]
  [ "$(jq -r .status "$INV_ROOT/demo/f/worker/1.out")" = cancelled ]
}

@test "through inv-worker, a finished run leaves no live log behind" {
  unset INV_WORKER_LIVE
  INV_WORKER_CMD="$RUNNER" run "$WORKER" demo/f "$CARD" --model cheap
  [ "$status" -eq 0 ]
  [[ "$output" == *"ANSWER: 42"* ]]
  [ ! -f "$INV_ROOT/demo/f/live.log" ]
  [ ! -d "$INV_ROOT/demo/f/worker" ]
}
