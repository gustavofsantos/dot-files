import * as path from "path";
import { FACTS_DIR, listFiles } from "../lib/fs.js";

export interface KnowledgeResult {
  path: string;
  score: number | null;
}

export interface KnowledgeQueryResult {
  results: KnowledgeResult[];
  source: "qmd" | "fallback";
}

export async function knowledge_query(
  query: string,
  min_score: number = 0.5,
  n: number = 8
): Promise<KnowledgeQueryResult> {
  try {
    const proc = Bun.spawn(
      ["qmd", "query", query, "--min-score", String(min_score), "-n", String(n), "--files"],
      { stdout: "pipe", stderr: "pipe" }
    );

    const exitCode = await proc.exited;
    if (exitCode !== 0) throw new Error("qmd exited non-zero");

    const stdout = await new Response(proc.stdout).text();
    const lines = stdout.split("\n").filter((l) => l.trim().length > 0);

    const results: KnowledgeResult[] = lines.map((line) => {
      const parts = line.trim().split(/\s+/);
      const lastPart = parts[parts.length - 1];
      const scoreCandidate = parseFloat(lastPart ?? "");
      if (!isNaN(scoreCandidate) && parts.length > 1) {
        return { path: parts.slice(0, -1).join(" "), score: scoreCandidate };
      }
      return { path: line.trim(), score: null };
    });

    return { results: results.slice(0, n), source: "qmd" };
  } catch {
    // Fallback: glob FACTS_DIR and filter by query words
    const files = await listFiles(FACTS_DIR, /\.md$/);
    const words = query
      .toLowerCase()
      .split(/\s+/)
      .filter((w) => w.length > 0);

    const matched = files.filter((f) => {
      const base = path.basename(f).toLowerCase();
      return words.some((w) => base.includes(w));
    });

    const results: KnowledgeResult[] = matched
      .slice(0, n)
      .map((p) => ({ path: p, score: null }));

    return { results, source: "fallback" };
  }
}
