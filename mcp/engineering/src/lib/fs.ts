import * as fs from "fs";
import * as path from "path";
import * as os from "os";

export const ENG_DIR = path.join(os.homedir(), "engineering");
export const CARDS_DIR = path.join(ENG_DIR, "cards");
export const SESSIONS_DIR = path.join(ENG_DIR, "sessions");
export const FACTS_DIR = path.join(ENG_DIR, "facts");
export const SPIKES_DIR = path.join(ENG_DIR, "spikes");
export const COUNTERS_DIR = path.join(ENG_DIR, ".counters");

export async function readFile(filePath: string): Promise<string> {
  return fs.promises.readFile(filePath, "utf-8");
}

export async function writeFile(filePath: string, content: string): Promise<void> {
  await fs.promises.mkdir(path.dirname(filePath), { recursive: true });
  await fs.promises.writeFile(filePath, content, "utf-8");
}

export async function listFiles(dir: string, pattern?: RegExp): Promise<string[]> {
  let entries: fs.Dirent[];
  try {
    entries = await fs.promises.readdir(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const results: string[] = [];
  for (const entry of entries) {
    if (entry.isDirectory() && entry.name === "archive") continue;
    if (entry.isFile()) {
      const fullPath = path.join(dir, entry.name);
      if (!pattern || pattern.test(entry.name)) {
        results.push(fullPath);
      }
    }
  }
  return results;
}
