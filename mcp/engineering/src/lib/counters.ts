import * as fs from "fs";
import * as path from "path";
import { COUNTERS_DIR } from "./fs.js";

export async function nextId(entity: "cards" | "facts" | "spikes"): Promise<string> {
  const counterPath = path.join(COUNTERS_DIR, entity);

  let current = 0;
  try {
    const content = await fs.promises.readFile(counterPath, "utf-8");
    current = parseInt(content.trim(), 10);
    if (isNaN(current)) current = 0;
  } catch {
    await fs.promises.mkdir(COUNTERS_DIR, { recursive: true });
  }

  const next = current + 1;
  await fs.promises.writeFile(counterPath, String(next), "utf-8");
  return String(next).padStart(3, "0");
}
