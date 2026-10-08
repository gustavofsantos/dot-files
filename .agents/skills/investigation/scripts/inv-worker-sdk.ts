#!/usr/bin/env -S bun --no-install
// inv-worker-sdk — run one investigation card on a local Cursor agent through @cursor/sdk.
//
//   inv-worker-sdk --model MODEL "<card>"    run the card, print one JSON result
//
// Drop-in for inv-worker: INV_WORKER_CMD=inv-worker-sdk. Same card in, and on stdout
// one JSON object {status, result, durationMs, usage} that inv-worker reads `.result` from.
//
// Environment (inv-worker sets the first two):
//   INV_LEASE_AT      epoch seconds; when it passes, the agent is told once to return now
//   INV_WORKER_LIVE   file that gets one line per tool call while the card runs
//   INV_SDK_DIR       where the SDK is installed (default: $XDG_DATA_HOME/inv/sdk)
//   INV_SDK_STORE     where local agents keep their transcripts (default: $XDG_DATA_HOME/inv/agents)
//   INV_SDK_SETTINGS  setting sources the agent loads (default: project,user)
//   INV_WORKER_CWD    the agent's workspace (default: the current directory)
//   CURSOR_API_KEY    passed to the SDK when set
//
// On TERM (inv-worker's hard deadline) the run is cancelled, waiting at most 10s, and
// the partial answer is printed with status "cancelled". Exit: 0 finished, 1 error,
// 143 cancelled. Tool results are never written anywhere: they hold production data.

import { $ } from "bun";

const SDK_PACKAGE = "@cursor/sdk";
const CANCEL_WAIT_MS = 10_000;
const ARGS_PREVIEW = 200;
const STEER_TEXT =
  "Time is up for this card. Stop running commands and return your answer now, " +
  "in the card's Return format, citing the steps you have.";

const dataHome = Bun.env.XDG_DATA_HOME ?? `${Bun.env.HOME}/.local/share`;
const sdkDir = Bun.env.INV_SDK_DIR ?? `${dataHome}/inv/sdk`;
const storeDir = Bun.env.INV_SDK_STORE ?? `${dataHome}/inv/agents`;
const livePath = Bun.env.INV_WORKER_LIVE ?? "";

type Result = { status: string; result: string; durationMs?: number; usage?: unknown; error?: string };

function die(message: string): never {
  console.error(`[inv-worker-sdk] error: ${message}`);
  process.exit(1);
}

// Loads the SDK only from INV_SDK_DIR. Bun would otherwise auto-install a missing
// package from npm at import time (the shebang's --no-install also forbids that).
async function loadSdk(): Promise<any> {
  const missing = `${SDK_PACKAGE} is not installed in ${sdkDir}`;
  if (!(await Bun.file(`${sdkDir}/node_modules/${SDK_PACKAGE}/package.json`).exists())) die(missing);
  let path: string;
  try {
    path = Bun.resolveSync(SDK_PACKAGE, sdkDir);
  } catch {
    die(missing);
  }
  if (!path.startsWith(`${sdkDir}/node_modules/`)) die(missing);
  return import(path);
}

// Every SDK call lives here, so fitting a new SDK version is one edit.
async function startRun(sdk: any, model: string, card: string) {
  const local: Record<string, unknown> = {
    cwd: Bun.env.INV_WORKER_CWD ?? process.cwd(),
    settingSources: (Bun.env.INV_SDK_SETTINGS ?? "project,user").split(",").filter(Boolean),
  };
  // A JSONL store keeps the SDK off node:sqlite, which Bun does not provide.
  if (sdk.JsonlLocalAgentStore) {
    await $`mkdir -p ${storeDir}`;
    local.store = new sdk.JsonlLocalAgentStore(storeDir);
  }
  const options: Record<string, unknown> = { model: { id: model }, local };
  if (Bun.env.CURSOR_API_KEY) options.apiKey = Bun.env.CURSOR_API_KEY;
  const agent = await sdk.Agent.create(options);
  const run = await agent.send(card);
  return {
    agent,
    run,
    events: () => run.stream() as AsyncIterable<any>,
    wait: () => run.wait() as Promise<any>,
    cancel: () => run.cancel() as Promise<void>,
    steer: typeof run.steer === "function" ? (text: string) => run.steer(text) : null,
    close: () => (typeof agent.close === "function" ? agent.close() : undefined),
  };
}

function clock(): string {
  return new Date().toISOString().slice(11, 19);
}

// One writer for the whole card, flushed per line so the file is readable while the
// card runs and its mtime tells inv board when the last tool event was.
let liveSink: ReturnType<ReturnType<typeof Bun.file>["writer"]> | null = null;
function live(line: string): void {
  if (!liveSink) return;
  liveSink.write(`${clock()} ${line}\n`);
  liveSink.flush();
}

function preview(value: unknown): string {
  if (value === undefined) return "";
  const text = typeof value === "string" ? value : JSON.stringify(value);
  const flat = (text ?? "").replace(/\s+/g, " ");
  return flat.length > ARGS_PREVIEW ? flat.slice(0, ARGS_PREVIEW) + "…" : flat;
}

let printed = false;
function finish(result: Result, code: number): void {
  if (printed) return;
  printed = true;
  live(`end ${result.status}`);
  // Exit only once stdout is written: inv-worker reads it from a pipe.
  Bun.write(Bun.stdout, JSON.stringify(result) + "\n").then(() => process.exit(code));
}

async function main(): Promise<void> {
  const argv = Bun.argv.slice(2);

  let model = "";
  const rest: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--model") model = argv[++i] ?? "";
    else rest.push(argv[i]);
  }
  const card = rest.join(" ");
  if (!model) die("missing --model");
  if (!card.trim()) die("missing card text");

  if (livePath) {
    await Bun.write(livePath, ""); // the writer does not truncate
    liveSink = Bun.file(livePath).writer();
  }
  const sdk = await loadSdk();
  const started = Date.now();
  const handle = await startRun(sdk, model, card);
  live(`start model=${model} run=${handle.run.id ?? "?"}`);

  let partial = "";
  const callStarted = new Map<string, number>();

  let cancelling = false;
  const onTerm = async () => {
    if (cancelling) return;
    cancelling = true;
    live("TERM: cancelling the run");
    await Promise.race([handle.cancel().catch(() => {}), Bun.sleep(CANCEL_WAIT_MS)]);
    finish({ status: "cancelled", result: partial ? `(cancelled) ${partial}` : "", durationMs: Date.now() - started }, 143);
  };
  process.on("SIGTERM", onTerm);
  process.on("SIGINT", onTerm);

  // Past the lease inv refuses new steps; one steer gives the agent a chance to answer.
  const leaseAt = Number(Bun.env.INV_LEASE_AT ?? "");
  let steerTimer: ReturnType<typeof setTimeout> | undefined;
  if (handle.steer && Number.isFinite(leaseAt) && leaseAt > 0) {
    steerTimer = setTimeout(() => {
      live("lease passed: steering the agent to return");
      handle.steer!(STEER_TEXT).catch(() => {});
    }, Math.max(0, leaseAt * 1000 - Date.now()));
  }

  try {
    for await (const event of handle.events()) {
      if (event.type === "tool_call") {
        const id = String(event.call_id ?? "");
        if (event.status === "running") {
          callStarted.set(id, Date.now());
          live(`tool ${event.name} running ${preview(event.args)}`);
        } else {
          const secs = callStarted.has(id) ? ((Date.now() - callStarted.get(id)!) / 1000).toFixed(1) : "?";
          live(`tool ${event.name} ${event.status} ${secs}s`);
        }
      } else if (event.type === "request") {
        live(`request ${event.request_id}: the agent waits for approval or input`);
      } else if (event.type === "assistant") {
        const text = (event.message?.content ?? [])
          .filter((block: any) => block.type === "text")
          .map((block: any) => block.text)
          .join("");
        if (text) partial = text;
      }
    }
  } catch (error) {
    if (!cancelling) live(`stream error: ${preview(String(error))}`);
  }
  if (cancelling) return;

  const result = await handle.wait();
  if (steerTimer) clearTimeout(steerTimer);
  handle.close();
  const status = String(result.status ?? "error");
  finish(
    {
      status,
      result: result.result ?? partial,
      durationMs: result.durationMs ?? Date.now() - started,
      usage: result.usage,
      ...(result.error ? { error: result.error.message ?? String(result.error) } : {}),
    },
    status === "finished" ? 0 : status === "cancelled" ? 143 : 1,
  );
}

main().catch((error) => die(String(error?.stack ?? error)));
