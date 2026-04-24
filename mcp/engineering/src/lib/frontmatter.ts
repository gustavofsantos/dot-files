export interface ParseResult {
  frontmatter: Record<string, unknown>;
  body: string;
}

export function parse(content: string): ParseResult {
  const lines = content.split("\n");

  if (lines[0]?.trim() !== "---") {
    return { frontmatter: {}, body: content };
  }

  let endIndex = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i]?.trim() === "---") {
      endIndex = i;
      break;
    }
  }

  if (endIndex === -1) {
    return { frontmatter: {}, body: content };
  }

  const fmLines = lines.slice(1, endIndex);
  const body = lines.slice(endIndex + 1).join("\n");
  const frontmatter = parseFrontmatterLines(fmLines);

  return { frontmatter, body };
}

function parseFrontmatterLines(lines: string[]): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];
    if (!line || line.trim() === "") {
      i++;
      continue;
    }

    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) {
      i++;
      continue;
    }

    const key = line.slice(0, colonIdx).trim();
    const rawValue = line.slice(colonIdx + 1).trim();

    if (rawValue === "") {
      // Check if next lines are a list block
      const listItems: string[] = [];
      let j = i + 1;
      while (j < lines.length) {
        const nextLine = lines[j];
        if (!nextLine || nextLine.trim() === "") break;
        const listMatch = nextLine.match(/^\s+-\s+(.*)/);
        if (listMatch) {
          listItems.push(listMatch[1].trim());
          j++;
        } else {
          break;
        }
      }
      if (listItems.length > 0) {
        result[key] = listItems;
        i = j;
      } else {
        result[key] = null;
        i++;
      }
    } else if (rawValue.startsWith("[") && rawValue.endsWith("]")) {
      result[key] = parseInlineArray(rawValue);
      i++;
    } else {
      result[key] = parseScalar(rawValue);
      i++;
    }
  }

  return result;
}

function parseInlineArray(raw: string): string[] {
  const inner = raw.slice(1, -1).trim();
  if (inner === "") return [];
  return inner.split(",").map((s) => s.trim());
}

function parseScalar(raw: string): string | number | boolean | null {
  if (raw === "null" || raw === "~") return null;
  if (raw === "true") return true;
  if (raw === "false") return false;
  const num = Number(raw);
  if (!isNaN(num) && raw !== "") return num;
  // Strip surrounding quotes
  if (
    (raw.startsWith('"') && raw.endsWith('"')) ||
    (raw.startsWith("'") && raw.endsWith("'"))
  ) {
    return raw.slice(1, -1);
  }
  return raw;
}

export function serialize(frontmatter: Record<string, unknown>, body: string): string {
  const lines: string[] = ["---"];

  for (const [key, value] of Object.entries(frontmatter)) {
    if (value === null || value === undefined) {
      lines.push(`${key}: `);
    } else if (Array.isArray(value)) {
      // Sessions field uses multiline list; other arrays use inline style
      if (key === "sessions") {
        if (value.length === 0) {
          lines.push(`${key}: []`);
        } else {
          lines.push(`${key}:`);
          for (const item of value) {
            lines.push(`  - ${item}`);
          }
        }
      } else {
        lines.push(`${key}: [${value.join(", ")}]`);
      }
    } else if (typeof value === "boolean") {
      lines.push(`${key}: ${value}`);
    } else if (typeof value === "number") {
      lines.push(`${key}: ${value}`);
    } else {
      lines.push(`${key}: ${value}`);
    }
  }

  lines.push("---");

  const bodyStr = body.startsWith("\n") ? body : "\n" + body;
  return lines.join("\n") + bodyStr;
}
