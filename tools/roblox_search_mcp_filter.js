#!/usr/bin/env node

const { spawn } = require("child_process");
const fs = require("fs");

const serverPath =
  process.env.ROBLOX_SEARCH_MCP_BIN ||
  "/Users/abdulrehmanbhidya/Downloads/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp";

const allowedTools = new Set([
  "search_assets",
  "preview_asset",
]);

let child;
let childStartError;

function startChild() {
  if (child || childStartError) return child;
  if (!fs.existsSync(serverPath)) {
    childStartError = `Roblox_Search MCP binary not found: ${serverPath}`;
    return null;
  }
  child = spawn(serverPath, ["--stdio"], {
    stdio: ["pipe", "pipe", "pipe"],
  });
  child.stderr.on("data", (chunk) => {
    process.stderr.write(chunk);
  });
  child.on("error", (err) => {
    childStartError = `Failed to start Roblox_Search MCP: ${err.message}`;
    child = null;
  });
  child.on("exit", (code, signal) => {
    process.stderr.write(`Roblox_Search filtered child exited code=${code} signal=${signal}\n`);
    child = null;
  });
  child.stdout.on("data", (chunk) => {
    pumpLines(chunk, { get buffer() { return childBuffer; }, set buffer(value) { childBuffer = value; } }, handleChildMessage);
  });
  return child;
}

let parentBuffer = "";
let childBuffer = "";

function writeJson(stream, message) {
  stream.write(`${JSON.stringify(message)}\n`);
}

function filterTool(tool) {
  return tool && allowedTools.has(tool.name);
}

function handleParentMessage(message) {
  if (
    message &&
    message.method === "tools/call" &&
    message.params &&
    !allowedTools.has(message.params.name)
  ) {
    writeJson(process.stdout, {
      jsonrpc: "2.0",
      id: message.id,
      error: {
        code: -32601,
        message: `Roblox_Search is restricted to ${Array.from(allowedTools).join(", ")}`,
      },
    });
    return;
  }

  const activeChild = startChild();
  if (!activeChild || childStartError) {
    writeJson(process.stdout, {
      jsonrpc: "2.0",
      id: message.id,
      error: {
        code: -32000,
        message: childStartError || "Roblox_Search MCP child is unavailable",
      },
    });
    return;
  }
  writeJson(activeChild.stdin, message);
}

function handleChildMessage(message) {
  if (message && message.result && Array.isArray(message.result.tools)) {
    message.result.tools = message.result.tools.filter(filterTool);
  }
  writeJson(process.stdout, message);
}

function pumpLines(chunk, state, handler) {
  state.buffer += chunk.toString();
  while (true) {
    const newline = state.buffer.indexOf("\n");
    if (newline < 0) break;
    const raw = state.buffer.slice(0, newline).trim();
    state.buffer = state.buffer.slice(newline + 1);
    if (!raw) continue;
    let message;
    try {
      message = JSON.parse(raw);
    } catch (err) {
      writeJson(process.stdout, {
        jsonrpc: "2.0",
        error: { code: -32700, message: `Invalid JSON through Roblox_Search filter: ${err.message}` },
      });
      continue;
    }
    handler(message);
  }
}

process.stdin.on("data", (chunk) => {
  pumpLines(chunk, { get buffer() { return parentBuffer; }, set buffer(value) { parentBuffer = value; } }, handleParentMessage);
});

process.on("exit", () => {
  if (child) child.kill();
});
