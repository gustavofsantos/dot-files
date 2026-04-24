import * as path from "path";
import * as fs from "fs";
import { CARDS_DIR, SESSIONS_DIR, readFile, writeFile, listFiles } from "../lib/fs.js";
import { nextId } from "../lib/counters.js";
import { parse, serialize } from "../lib/frontmatter.js";

const VALID_STATUSES = ["inbox", "not-now", "active", "done"] as const;

function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .split(/\s+/)
    .slice(0, 5)
    .join("-");
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

export async function findCardPath(id: string): Promise<string> {
  const files = await listFiles(CARDS_DIR, /\.md$/);
  const match = files.find((f) => path.basename(f).startsWith(`${id}-`));
  if (!match) throw new Error(`Card ${id} not found`);
  return match;
}

export interface CardCreateResult {
  id: string;
  title: string;
  status: string;
  path: string;
}

export async function card_create(
  title: string,
  status: string = "inbox",
  tags: string[] = []
): Promise<CardCreateResult> {
  if (!(VALID_STATUSES as readonly string[]).includes(status)) {
    throw new Error(`Invalid status: ${status}. Must be one of: ${VALID_STATUSES.join(", ")}`);
  }

  const id = await nextId("cards");
  const slug = slugify(title);
  const filename = `${id}-${slug}.md`;
  const filePath = path.join(CARDS_DIR, filename);
  const date = today();

  const frontmatter: Record<string, unknown> = {
    id,
    title,
    status,
    tags,
    created: date,
    updated: date,
    sessions: [],
  };

  const body = `
## Objective

## Context

## Tasks

## Current focus
`;

  await writeFile(filePath, serialize(frontmatter, body));
  return { id, title, status, path: filePath };
}

export interface CardListItem {
  id: string;
  title: string;
  status: string;
  tags: string[];
  path: string;
}

export async function card_list(
  status?: string,
  tag?: string
): Promise<CardListItem[]> {
  const files = await listFiles(CARDS_DIR, /\.md$/);
  const results: CardListItem[] = [];

  for (const filePath of files) {
    try {
      const content = await readFile(filePath);
      const { frontmatter } = parse(content);

      const cardStatus = String(frontmatter["status"] ?? "");
      const cardTitle = String(frontmatter["title"] ?? "");
      const cardId = String(frontmatter["id"] ?? "");
      const cardTags = Array.isArray(frontmatter["tags"])
        ? (frontmatter["tags"] as unknown[]).map(String)
        : [];

      if (status && cardStatus !== status) continue;
      if (tag && !cardTags.includes(tag)) continue;

      results.push({ id: cardId, title: cardTitle, status: cardStatus, tags: cardTags, path: filePath });
    } catch {
      // Skip unreadable files
    }
  }

  return results;
}

export async function card_get(id: string): Promise<string> {
  const filePath = await findCardPath(id);
  return readFile(filePath);
}

export interface CardSetStatusResult {
  id: string;
  status: string;
  updated: string;
}

export async function card_set_status(
  id: string,
  status: string
): Promise<CardSetStatusResult> {
  if (!(VALID_STATUSES as readonly string[]).includes(status)) {
    throw new Error(`Invalid status: ${status}. Must be one of: ${VALID_STATUSES.join(", ")}`);
  }

  const filePath = await findCardPath(id);
  const content = await readFile(filePath);
  const { frontmatter, body } = parse(content);

  const date = today();
  frontmatter["status"] = status;
  frontmatter["updated"] = date;

  await writeFile(filePath, serialize(frontmatter, body));
  return { id, status, updated: date };
}

export interface CardArchiveResult {
  id: string;
  card_archived: string;
  sessions_archived: string[];
  sessions_skipped: string[];
}

export async function card_archive(
  id: string,
  force: boolean = false
): Promise<CardArchiveResult> {
  const filePath = await findCardPath(id);
  const content = await readFile(filePath);
  const { frontmatter } = parse(content);

  const status = String(frontmatter["status"] ?? "");
  if (!force && status !== "done") {
    throw new Error(`Card ${id} has status "${status}". Set to "done" first or use force: true`);
  }

  const archiveCardDir = path.join(CARDS_DIR, "archive");
  await fs.promises.mkdir(archiveCardDir, { recursive: true });

  const basename = path.basename(filePath);
  const archiveCardPath = path.join(archiveCardDir, basename);
  await fs.promises.rename(filePath, archiveCardPath);

  const sessions_archived: string[] = [];
  const sessions_skipped: string[] = [];

  const sessionRefs = Array.isArray(frontmatter["sessions"])
    ? (frontmatter["sessions"] as unknown[]).map(String)
    : [];

  const archiveSessionDir = path.join(SESSIONS_DIR, "archive");

  for (const sessionRef of sessionRefs) {
    // sessionRef is an absolute path
    const sessionBasename = path.basename(sessionRef);
    const sessionSrc = path.isAbsolute(sessionRef)
      ? sessionRef
      : path.join(SESSIONS_DIR, sessionRef);

    try {
      await fs.promises.access(sessionSrc);
      await fs.promises.mkdir(archiveSessionDir, { recursive: true });
      const sessionDest = path.join(archiveSessionDir, sessionBasename);
      await fs.promises.rename(sessionSrc, sessionDest);
      sessions_archived.push(sessionBasename);
    } catch {
      sessions_skipped.push(sessionBasename);
    }
  }

  return {
    id,
    card_archived: archiveCardPath,
    sessions_archived,
    sessions_skipped,
  };
}
