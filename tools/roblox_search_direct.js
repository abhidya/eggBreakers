#!/usr/bin/env node

const { spawn } = require("child_process");
const fs = require("fs");

const serverPath =
  process.env.ROBLOX_SEARCH_MCP_BIN ||
  "/Users/abdulrehmanbhidya/Downloads/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp";

const [toolName, argsJson = "{}"] = process.argv.slice(2);
if (!toolName) {
  console.error("usage: tools/roblox_search_direct.js <tool> '<json-args>'");
  process.exit(2);
}

const allowedTools = new Set(["search_assets", "preview_asset"]);
if (!allowedTools.has(toolName)) {
  console.error(`Roblox_Search direct helper is restricted to ${Array.from(allowedTools).join(", ")}`);
  process.exit(2);
}

let args;
try {
  args = JSON.parse(argsJson);
} catch (err) {
  console.error(`invalid json args: ${err.message}`);
  process.exit(2);
}

if (!fs.existsSync(serverPath)) {
  console.error(`Roblox_Search MCP binary not found: ${serverPath}`);
  process.exit(1);
}

const child = spawn(serverPath, ["--stdio"], {
  stdio: ["pipe", "pipe", "pipe"],
});

let buffer = "";
let sawToolResponse = false;
let timeoutId;

function send(message) {
  child.stdin.write(`${JSON.stringify(message)}\n`);
}

function finish(code) {
  clearTimeout(timeoutId);
  child.kill();
  process.exit(code);
}

child.stderr.on("data", (data) => {
  const text = data.toString();
  if (text.trim()) process.stderr.write(text);
});

child.stdout.on("data", (data) => {
  buffer += data.toString();
  while (true) {
    const newline = buffer.indexOf("\n");
    if (newline < 0) return;
    const raw = buffer.slice(0, newline).trim();
    buffer = buffer.slice(newline + 1);
    if (!raw) continue;
    let message;
    try {
      message = JSON.parse(raw);
    } catch (err) {
      console.error(`invalid MCP json: ${raw}`);
      finish(1);
    }
    if (message.id === 2) {
      sawToolResponse = true;
      console.log(JSON.stringify(message.result || message.error, null, 2));
      finish(message.error ? 1 : 0);
    }
  }
});

child.on("exit", (code) => {
  if (!sawToolResponse) {
    console.error(`MCP process exited before tool response: ${code}`);
    process.exit(1);
  }
});

child.on("error", (err) => {
  console.error(`Failed to start Roblox_Search MCP: ${err.message}`);
  finish(1);
});

timeoutId = setTimeout(() => {
  console.error(`Timed out waiting for ${toolName}`);
  finish(124);
}, 45000);

send({
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: {
    protocolVersion: "2024-11-05",
    capabilities: {},
    clientInfo: { name: "eggBreakers-direct-search", version: "1" },
  },
});

setTimeout(() => {
  send({ jsonrpc: "2.0", method: "notifications/initialized", params: {} });
}, 100);

setTimeout(() => {
  send({
    jsonrpc: "2.0",
    id: 2,
    method: "tools/call",
    params: { name: toolName, arguments: args },
  });
}, 200);
