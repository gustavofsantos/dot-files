import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import { card_create, card_list, card_get, card_set_status, card_archive } from "./tools/cards.js";
import { session_create, session_get, session_update_focus } from "./tools/sessions.js";
import { fact_create, fact_get, fact_update, fact_invalidate } from "./tools/facts.js";
import { knowledge_query } from "./tools/knowledge.js";

const pkg = { version: "0.1.0" };

const server = new Server(
  { name: "engineering", version: pkg.version },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "card_create",
      description: "Create a new engineering card",
      inputSchema: {
        type: "object",
        properties: {
          title: { type: "string" },
          status: { type: "string", enum: ["inbox", "not-now", "active", "done"], default: "inbox" },
          tags: { type: "array", items: { type: "string" } },
        },
        required: ["title"],
      },
    },
    {
      name: "card_list",
      description: "List non-archived engineering cards",
      inputSchema: {
        type: "object",
        properties: {
          status: { type: "string" },
          tag: { type: "string" },
        },
      },
    },
    {
      name: "card_get",
      description: "Get full content of a card by ID",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string" },
        },
        required: ["id"],
      },
    },
    {
      name: "card_set_status",
      description: "Update the status of a card",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string" },
          status: { type: "string", enum: ["inbox", "not-now", "active", "done"] },
        },
        required: ["id", "status"],
      },
    },
    {
      name: "card_archive",
      description: "Archive a done card and its associated sessions",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string" },
          force: { type: "boolean", default: false },
        },
        required: ["id"],
      },
    },
    {
      name: "session_create",
      description: "Create a work session linked to a card",
      inputSchema: {
        type: "object",
        properties: {
          card_id: { type: "string" },
          repo: { type: "string" },
          branch: { type: "string" },
          worktree: { type: "string", description: "Absolute path to git worktree" },
        },
        required: ["card_id", "repo", "branch", "worktree"],
      },
    },
    {
      name: "session_get",
      description: "Get full content of a session by ID",
      inputSchema: {
        type: "object",
        properties: {
          session_id: { type: "string" },
        },
        required: ["session_id"],
      },
    },
    {
      name: "session_update_focus",
      description: "Rewrite the Current focus section of a session",
      inputSchema: {
        type: "object",
        properties: {
          session_id: { type: "string" },
          done: { type: "array", items: { type: "string" } },
          in_progress: { type: "string" },
          next: { type: "array", items: { type: "string" } },
        },
        required: ["session_id", "done", "in_progress", "next"],
      },
    },
    {
      name: "fact_create",
      description: "Create a new engineering fact",
      inputSchema: {
        type: "object",
        properties: {
          title: { type: "string" },
          tags: { type: "array", items: { type: "string" } },
          confidence: { type: "string", enum: ["asserted", "validated"], default: "asserted" },
        },
        required: ["title"],
      },
    },
    {
      name: "fact_get",
      description: "Get full content of a fact by ID",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string", description: "FACT-001 or 001 format" },
        },
        required: ["id"],
      },
    },
    {
      name: "fact_update",
      description: "Merge fields into a fact's front-matter",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string" },
          fields: { type: "object" },
        },
        required: ["id", "fields"],
      },
    },
    {
      name: "fact_invalidate",
      description: "Mark a fact as invalidated with a reason",
      inputSchema: {
        type: "object",
        properties: {
          id: { type: "string" },
          reason: { type: "string" },
        },
        required: ["id", "reason"],
      },
    },
    {
      name: "knowledge_query",
      description: "Search facts using qmd or filename fallback",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string" },
          min_score: { type: "number", default: 0.5 },
          n: { type: "number", default: 8 },
        },
        required: ["query"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const a = (args ?? {}) as Record<string, unknown>;

  try {
    let result: unknown;

    switch (name) {
      case "card_create":
        result = await card_create(
          a["title"] as string,
          a["status"] as string | undefined,
          a["tags"] as string[] | undefined
        );
        break;

      case "card_list":
        result = await card_list(
          a["status"] as string | undefined,
          a["tag"] as string | undefined
        );
        break;

      case "card_get":
        result = await card_get(a["id"] as string);
        break;

      case "card_set_status":
        result = await card_set_status(a["id"] as string, a["status"] as string);
        break;

      case "card_archive":
        result = await card_archive(a["id"] as string, a["force"] as boolean | undefined);
        break;

      case "session_create":
        result = await session_create(
          a["card_id"] as string,
          a["repo"] as string,
          a["branch"] as string,
          a["worktree"] as string
        );
        break;

      case "session_get":
        result = await session_get(a["session_id"] as string);
        break;

      case "session_update_focus":
        result = await session_update_focus(
          a["session_id"] as string,
          a["done"] as string[],
          a["in_progress"] as string,
          a["next"] as string[]
        );
        break;

      case "fact_create":
        result = await fact_create(
          a["title"] as string,
          a["tags"] as string[] | undefined,
          a["confidence"] as "asserted" | "validated" | undefined
        );
        break;

      case "fact_get":
        result = await fact_get(a["id"] as string);
        break;

      case "fact_update":
        result = await fact_update(
          a["id"] as string,
          a["fields"] as Record<string, unknown>
        );
        break;

      case "fact_invalidate":
        result = await fact_invalidate(a["id"] as string, a["reason"] as string);
        break;

      case "knowledge_query":
        result = await knowledge_query(
          a["query"] as string,
          a["min_score"] as number | undefined,
          a["n"] as number | undefined
        );
        break;

      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }

    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      content: [{ type: "text", text: `Error: ${message}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);

// Registration:
//
// Claude Code (~/.claude/settings.json):
// {
//   "mcpServers": {
//     "engineering": {
//       "command": "bun",
//       "args": ["run", "/Users/YOU/.dotfiles/mcp/engineering/src/index.ts"]
//     }
//   }
// }
//
// Claude Desktop (~/Library/Application Support/Claude/claude_desktop_config.json):
// same structure as above
