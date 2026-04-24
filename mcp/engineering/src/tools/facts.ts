import * as path from "path";
import { FACTS_DIR, readFile, writeFile, listFiles } from "../lib/fs.js";
import { nextId } from "../lib/counters.js";
import { parse, serialize } from "../lib/frontmatter.js";

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

async function findFactPath(id: string): Promise<string> {
  // Accept "FACT-001" or "001"
  const normalized = id.toUpperCase().startsWith("FACT-") ? id.toUpperCase() : `FACT-${id}`;
  const files = await listFiles(FACTS_DIR, /\.md$/);
  const match = files.find((f) => path.basename(f).startsWith(`${normalized}-`));
  if (!match) throw new Error(`Fact ${id} not found`);
  return match;
}

export interface FactCreateResult {
  id: string;
  title: string;
  confidence: string;
  path: string;
}

export async function fact_create(
  title: string,
  tags: string[] = [],
  confidence: "asserted" | "validated" = "asserted"
): Promise<FactCreateResult> {
  const id = await nextId("facts");
  const slug = slugify(title);
  const filename = `FACT-${id}-${slug}.md`;
  const filePath = path.join(FACTS_DIR, filename);
  const date = today();

  const frontmatter: Record<string, unknown> = {
    id: `FACT-${id}`,
    title,
    tags,
    confidence,
    created: date,
  };

  if (confidence === "validated") {
    frontmatter["confirmed"] = date;
  }

  const body = `
## Statement

## Evidence

## Depends on

## Notes
`;

  await writeFile(filePath, serialize(frontmatter, body));
  return { id: `FACT-${id}`, title, confidence, path: filePath };
}

export async function fact_get(id: string): Promise<string> {
  const filePath = await findFactPath(id);
  return readFile(filePath);
}

export async function fact_update(
  id: string,
  fields: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const filePath = await findFactPath(id);
  const content = await readFile(filePath);
  const { frontmatter, body } = parse(content);

  const merged = { ...frontmatter, ...fields };
  await writeFile(filePath, serialize(merged, body));
  return merged;
}

export interface FactInvalidateResult {
  id: string;
  invalidated: boolean;
}

export async function fact_invalidate(
  id: string,
  reason: string
): Promise<FactInvalidateResult> {
  const filePath = await findFactPath(id);
  const content = await readFile(filePath);
  const { frontmatter, body } = parse(content);

  frontmatter["confidence"] = "invalidated";

  const date = today();
  const invalidatedSection = `\n## Invalidated\n\n**Date:** ${date}\n\n**Reason:** ${reason}\n`;
  const newBody = body.trimEnd() + "\n" + invalidatedSection;

  await writeFile(filePath, serialize(frontmatter, newBody));
  return { id: String(frontmatter["id"] ?? id), invalidated: true };
}
