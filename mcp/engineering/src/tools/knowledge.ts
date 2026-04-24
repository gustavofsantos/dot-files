import * as path from "path";
import { FACTS_DIR, listFiles } from "../lib/fs.js";
import { createStore, getDefaultDbPath } from "@tobilu/qmd";

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
    const store = await createStore({ dbPath: getDefaultDbPath() });
    try {
      const hits = await store.search({ query, minScore: min_score, limit: n });
      const results: KnowledgeResult[] = hits.map((r) => ({
        path: r.displayPath,
        score: r.score,
      }));
      return { results, source: "qmd" };
    } finally {
      await store.close();
    }
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
