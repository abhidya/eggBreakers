#!/usr/bin/env node
/**
 * roblox_search_mcp_server.js
 *
 * MCP stdio server that exposes search_assets and preview_asset by proxying
 * calls to the rbx-studio-mcp binary (separate from the main Roblox_Studio
 * instance). Register in claude_desktop_config.json as "Roblox_Search".
 *
 * Usage (direct CLI, for testing):
 *   node tools/roblox_search_direct.js search_assets '{"query":"...", "max_results":5}'
 *
 * Usage (as MCP server):
 *   registered via claude_desktop_config.json — Claude calls it automatically.
 */

const { spawn } = require("child_process");
const fs = require("fs");
const readline = require("readline");

const SERVER_PATH =
  process.env.ROBLOX_SEARCH_MCP_BIN ||
  "/Users/abdulrehmanbhidya/Downloads/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp";

const ALLOWED_TOOLS = ["search_assets", "preview_asset"];

const TOOL_SCHEMAS = {
  search_assets: {
    name: "search_assets",
    description: "Search the Roblox Creator Store for assets by keyword.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search query" },
        max_results: { type: "number", description: "Maximum results to return (default 5)" },
      },
      required: ["query"],
    },
  },
  preview_asset: {
    name: "preview_asset",
    description: "Preview a Roblox asset by asset ID.",
    inputSchema: {
      type: "object",
      properties: {
        asset_id: { type: "string", description: "Roblox asset ID to preview" },
      },
      required: ["asset_id"],
    },
  },
};

function respond(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}

function callBinary(toolName, args) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(SERVER_PATH)) {
      return reject(new Error(`Roblox_Search binary not found: ${SERVER_PATH}`));
    }

    const child = spawn(SERVER_PATH, ["--stdio"], { stdio: ["pipe", "pipe", "pipe"] });
    let buffer = "";
    let done = false;

    const timeout = setTimeout(() => {
      if (!done) { done = true; child.kill(); reject(new Error(`Timed out waiting for ${toolName}`)); }
    }, 45000);

    function send(msg) { child.stdin.write(JSON.stringify(msg) + "\n"); }

    child.stderr.on("data", (d) => { if (d.toString().trim()) process.stderr.write(d); });

    child.stdout.on("data", (data) => {
      buffer += data.toString();
      while (true) {
        const nl = buffer.indexOf("\n");
        if (nl < 0) break;
        const raw = buffer.slice(0, nl).trim();
        buffer = buffer.slice(nl + 1);
        if (!raw) continue;
        let msg;
        try { msg = JSON.parse(raw); } catch { continue; }
        if (msg.id === 2) {
          done = true;
          clearTimeout(timeout);
          child.kill();
          if (msg.error) reject(new Error(JSON.stringify(msg.error)));
          else resolve(msg.result);
        }
      }
    });

    child.on("error", (err) => { if (!done) { done = true; clearTimeout(timeout); reject(err); } });

    send({ jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "roblox-search-mcp-server", version: "1" } } });
    setTimeout(() => send({ jsonrpc: "2.0", method: "notifications/initialized", params: {} }), 100);
    setTimeout(() => send({ jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: toolName, arguments: args } }), 200);
  });
}

const rl = readline.createInterface({ input: process.stdin, terminal: false });

rl.on("line", async (line) => {
  const raw = line.trim();
  if (!raw) return;
  let msg;
  try { msg = JSON.parse(raw); } catch { return; }

  const { id, method, params } = msg;

  if (method === "initialize") {
    return respond({
      jsonrpc: "2.0", id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "Roblox_Search", version: "1.0.0" },
      },
    });
  }

  if (method === "notifications/initialized") return;

  if (method === "tools/list") {
    return respond({
      jsonrpc: "2.0", id,
      result: { tools: ALLOWED_TOOLS.map((t) => TOOL_SCHEMAS[t]) },
    });
  }

  if (method === "tools/call") {
    const toolName = params?.name;
    const toolArgs = params?.arguments ?? {};
    if (!ALLOWED_TOOLS.includes(toolName)) {
      return respond({ jsonrpc: "2.0", id, error: { code: -32601, message: `Unknown tool: ${toolName}` } });
    }
    try {
      const result = await callBinary(toolName, toolArgs);
      return respond({ jsonrpc: "2.0", id, result });
    } catch (err) {
      return respond({ jsonrpc: "2.0", id, error: { code: -32603, message: err.message } });
    }
  }

  respond({ jsonrpc: "2.0", id, error: { code: -32601, message: `Method not found: ${method}` } });
});

rl.on("close", () => process.exit(0));
