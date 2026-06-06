#!/usr/bin/env node

const { spawn } = require("node:child_process");
const fs = require("node:fs");

const [toolName, argsJson = "{}"] = process.argv.slice(2);

if (!toolName) {
  console.error("usage: tools/studio_mcp_call.js <tool|tools/list> '<json-args>'");
  process.exit(2);
}

let args;
if (toolName === "run_code" && argsJson.startsWith("@")) {
  args = { command: fs.readFileSync(argsJson.slice(1), "utf8") };
} else {
  try {
    args = JSON.parse(argsJson);
  } catch (err) {
    console.error(`invalid json args: ${err.message}`);
    process.exit(2);
  }
}

const BUILT_IN_STUDIO_MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP";
const RUST_STUDIO_MCP = "/Users/abdulrehmanbhidya/Downloads/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp";
const command = process.env.STUDIO_MCP_COMMAND
  || (fs.existsSync(BUILT_IN_STUDIO_MCP) ? BUILT_IN_STUDIO_MCP : RUST_STUDIO_MCP);
const requestTimeoutMs = Number(process.env.STUDIO_MCP_TIMEOUT_MS || 45000);

const child = spawn(command, ["--stdio"], {
  stdio: ["pipe", "pipe", "pipe"],
});

let nextId = 1;
const pending = new Map();
let buffer = Buffer.alloc(0);

function send(message) {
  child.stdin.write(`${JSON.stringify(message)}\n`);
}

function request(method, params) {
  const id = nextId++;
  send({ jsonrpc: "2.0", id, method, params });
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      if (pending.has(id)) {
        pending.delete(id);
        reject(new Error(`timeout waiting for ${method}`));
      }
    }, Number.isFinite(requestTimeoutMs) && requestTimeoutMs > 0 ? requestTimeoutMs : 45000);
    pending.set(id, { resolve, reject, timer });
  });
}

function parseMessages() {
  while (true) {
    const lineEnd = buffer.indexOf("\n");
    if (lineEnd === -1) return;

    const raw = buffer.slice(0, lineEnd).toString("utf8").trim();
    buffer = buffer.slice(lineEnd + 1);
    if (!raw) continue;

    let message;
    try {
      message = JSON.parse(raw);
    } catch (err) {
      throw new Error(`invalid JSON response: ${err.message}: ${raw}`);
    }

    if (message.id != null && pending.has(message.id)) {
      const { resolve, reject, timer } = pending.get(message.id);
      pending.delete(message.id);
      clearTimeout(timer);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    }
  }
}

child.stdout.on("data", (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);
  try {
    parseMessages();
  } catch (err) {
    console.error(err.message);
    child.kill();
    process.exit(1);
  }
});

child.stderr.on("data", (chunk) => {
  process.stderr.write(chunk);
});

child.on("error", (err) => {
  console.error(err.message);
  process.exit(1);
});

async function main() {
  await request("initialize", {
    protocolVersion: "2025-03-26",
    capabilities: {},
    clientInfo: { name: "codex-local-studio-mcp-call", version: "1.0.0" },
  });
  send({ jsonrpc: "2.0", method: "notifications/initialized" });

  let result;
  if (toolName === "tools/list") {
    result = await request("tools/list", {});
  } else {
    result = await request("tools/call", { name: toolName, arguments: args });
  }

  console.log(JSON.stringify(result, null, 2));
  child.stdin.end();
  child.kill();
}

main().catch((err) => {
  console.error(err.message);
  child.kill();
  process.exit(1);
});
