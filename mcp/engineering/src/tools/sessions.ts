import * as path from "path";
import * as fs from "fs";
import { SESSIONS_DIR, readFile, writeFile } from "../lib/fs.js";
import { parse, serialize } from "../lib/frontmatter.js";
import { findCardPath } from "./cards.js";

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

function extractUncheckedTasks(body: string): string[] {
  const tasksMatch = body.match(/## Tasks\n([\s\S]*?)(?=\n## |\n$|$)/);
  if (!tasksMatch) return [];

  return tasksMatch[1]
    .split("\n")
    .filter((line) => /^\s*-\s*\[\s*\]\s+/.test(line))
    .map((line) => line.replace(/^\s*-\s*\[\s*\]\s+/, "").trim())
    .filter((t) => t.length > 0);
}

export interface SessionCreateResult {
  id: string;
  card_id: string;
  repo: string;
  branch: string;
  worktree: string;
  path: string;
  tasks_loaded: number;
}

export async function session_create(
  card_id: string,
  repo: string,
  branch: string,
  worktree: string
): Promise<SessionCreateResult> {
  if (!path.isAbsolute(worktree)) {
    throw new Error(`worktree must be an absolute path, got: ${worktree}`);
  }

  try {
    await fs.promises.access(worktree);
  } catch {
    throw new Error(`worktree path does not exist: ${worktree}`);
  }

  const session_id = `${card_id}-${repo}`;
  const sessionPath = path.join(SESSIONS_DIR, `${session_id}.md`);

  try {
    await fs.promises.access(sessionPath);
    throw new Error(`Session ${session_id} already exists at ${sessionPath}`);
  } catch (err) {
    if (err instanceof Error && err.message.includes("already exists")) throw err;
    // File doesn't exist — good
  }

  // Load tasks from card
  const cardPath = await findCardPath(card_id);
  const cardContent = await readFile(cardPath);
  const { frontmatter: cardFm, body: cardBody } = parse(cardContent);
  const tasks = extractUncheckedTasks(cardBody);

  const inProgress = tasks[0] ?? "";
  const next = tasks.slice(1);

  const date = today();
  const frontmatter: Record<string, unknown> = {
    id: session_id,
    card_id,
    repo,
    branch,
    worktree,
    created: date,
    updated: date,
  };

  let focusBody = "### In progress\n";
  if (inProgress) focusBody += `- [ ] ${inProgress}\n`;
  focusBody += "\n### Next\n";
  for (const t of next) focusBody += `- [ ] ${t}\n`;

  const body = `\n## Current focus\n\n${focusBody}`;
  await writeFile(sessionPath, serialize(frontmatter, body));

  // Update card: append session path to sessions field, update updated
  const existingSessions = Array.isArray(cardFm["sessions"])
    ? (cardFm["sessions"] as unknown[]).map(String)
    : [];
  cardFm["sessions"] = [...existingSessions, sessionPath];
  cardFm["updated"] = date;
  await writeFile(cardPath, serialize(cardFm, cardBody));

  return {
    id: session_id,
    card_id,
    repo,
    branch,
    worktree,
    path: sessionPath,
    tasks_loaded: tasks.length,
  };
}

export async function session_get(session_id: string): Promise<string> {
  const sessionPath = path.join(SESSIONS_DIR, `${session_id}.md`);
  return readFile(sessionPath);
}

export interface SessionUpdateFocusResult {
  session_id: string;
  updated: boolean;
}

export async function session_update_focus(
  session_id: string,
  done: string[],
  in_progress: string,
  next: string[]
): Promise<SessionUpdateFocusResult> {
  const sessionPath = path.join(SESSIONS_DIR, `${session_id}.md`);
  const content = await readFile(sessionPath);

  const focusSection = [
    "## Current focus",
    "",
    "### Done",
    ...done.map((d) => `- [x] ${d}`),
    "",
    "### In progress",
    `- [ ] ${in_progress}`,
    "",
    "### Next",
    ...next.map((n) => `- [ ] ${n}`),
    "",
  ].join("\n");

  // Replace from ## Current focus to next ## heading or EOF
  const replaced = content.replace(
    /## Current focus[\s\S]*?(?=\n## |\n$|$)/,
    focusSection
  );

  // If the pattern didn't match (section didn't exist), append
  const newContent = replaced === content
    ? content.trimEnd() + "\n\n" + focusSection
    : replaced;

  await writeFile(sessionPath, newContent);
  return { session_id, updated: true };
}
