#!/usr/bin/env -S bun --no-install
// inv-worker-sdk — run one investigation card on a local Cursor agent through @cursor/sdk.
//
//   inv-worker-sdk --model MODEL "<card>"    run the card, print one JSON result
//   inv-worker-sdk --install                 install the pinned SDK into INV_SDK_DIR
//   inv-worker-sdk --login                   browser login; the SDK stores its own key
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
//   CURSOR_API_KEY    used when set; otherwise the key stored by --login (the agent
//                     CLI's login does not carry over)
//
// On TERM (inv-worker's hard deadline) the run is cancelled, waiting at most 10s, and
// the partial answer is printed with status "cancelled". Exit: 0 finished, 1 error,
// 143 cancelled. Tool results are never written anywhere: they hold production data.

import { mkdirSync, writeFileSync, appendFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const SDK_PACKAGE = "@cursor/sdk";
const SDK_VERSION = "1.0.37";
const CANCEL_WAIT_MS = 10_000;
const ARGS_PREVIEW = 200;
const STEER_TEXT =
  "Time is up for this card. Stop running commands and return your answer now, " +
  "in the card's Return format, citing the steps you have.";

const dataHome = process.env.XDG_DATA_HOME ?? join(homedir(), ".local/share");
const sdkDir = process.env.INV_SDK_DIR ?? join(dataHome, "inv/sdk");
const storeDir = process.env.INV_SDK_STORE ?? join(dataHome, "inv/agents");
const livePath = process.env.INV_WORKER_LIVE ?? "";

type Result = { status: string; result: string; durationMs?: number; usage?: unknown; error?: string };

function die(message: string): never {
  process.stderr.write(`[inv-worker-sdk] error: ${message}\n`);
  process.exit(1);
}

function install(): void {
  mkdirSync(sdkDir, { recursive: true });
  if (!existsSync(join(sdkDir, "package.json"))) {
    writeFileSync(join(sdkDir, "package.json"), JSON.stringify({ name: "inv-sdk", private: true }) + "\n");
  }
  const child = Bun.spawnSync(["bun", "add", `${SDK_PACKAGE}@${SDK_VERSION}`], {
    cwd: sdkDir,
    stdout: "inherit",
    stderr: "inherit",
  });
  process.exit(child.exitCode ?? 1);
}

// Loads the SDK only from INV_SDK_DIR. Bun would otherwise auto-install a missing
// package from npm at import time (the shebang's --no-install also forbids that).
async function loadSdk(): Promise<any> {
  const missing = `${SDK_PACKAGE} is not installed in ${sdkDir}: run inv-worker-sdk --install`;
  if (!existsSync(join(sdkDir, "node_modules", SDK_PACKAGE, "package.json"))) die(missing);
  let path: string;
  try {
    path = Bun.resolveSync(SDK_PACKAGE, sdkDir);
  } catch {
    die(missing);
  }
  if (!path.startsWith(join(sdkDir, "node_modules") + "/")) die(missing);
  return import(path);
}

// Every SDK call lives here, so fitting a new SDK version is one edit.
async function startRun(sdk: any, model: string, card: string) {
  const local: Record<string, unknown> = {
    cwd: process.env.INV_WORKER_CWD ?? process.cwd(),
    settingSources: (process.env.INV_SDK_SETTINGS ?? "project,user").split(",").filter(Boolean),
  };
  // A JSONL store keeps the SDK off node:sqlite, which Bun does not provide.
  if (sdk.JsonlLocalAgentStore) {
    mkdirSync(storeDir, { recursive: true });
    local.store = new sdk.JsonlLocalAgentStore(storeDir);
  }
  const options: Record<string, unknown> = { model: { id: model }, local };
  if (process.env.CURSOR_API_KEY) options.apiKey = process.env.CURSOR_API_KEY;
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

function live(line: string): void {
  if (livePath) appendFileSync(livePath, `${clock()} ${line}\n`);
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
  // Exit only once stdout is flushed: inv-worker reads it from a pipe.
  process.stdout.write(JSON.stringify(result) + "\n", () => process.exit(code));
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  if (argv[0] === "--install") install();
  if (argv[0] === "--login") {
    const sdk = await loadSdk();
    await sdk.Cursor.auth.login();
    process.exit(0);
  }

  let model = "";
  const rest: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--model") model = argv[++i] ?? "";
    else rest.push(argv[i]);
  }
  const card = rest.join(" ");
  if (!model) die("missing --model");
  if (!card.trim()) die("missing card text");

  if (livePath) writeFileSync(livePath, "");
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
  const leaseAt = Number(process.env.INV_LEASE_AT ?? "");
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
