#!/usr/bin/env node

// PROTOTYPE: throwaway host-side Studio controller.
// Question: can one worker own Studio lifecycle, MCP probing, Rojo serving,
// and profiling without agentic UI clicking?

import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_STUDIO = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio";
const DEFAULT_MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP";
const DEFAULT_WORK_DIR = path.join(REPO_ROOT, ".omx/studio-controller-prototype");
const ROJO_PLUGIN_DEFAULT_PORT = 34872;
const DEFAULT_ROJO_PORT = 34879;

function usage() {
  console.error(`usage: node tools/studio_controller_prototype.mjs <command> [options]

Commands:
  research       Print researched controller options and source links
  env           Probe local Studio/Rojo/MCP availability
  build-place   Build a scratch .rbxl via rojo build
  start-rojo    Start a worker-owned rojo serve and write a manifest
  start-studio  Launch Studio for a place and write a manifest
  select-studio Select the intended Studio instance via built-in MCP
  isolate-desktop
                Activate Studio and move it into a macOS full-screen Space
  mcp-probe     Probe built-in StudioMCP tools and connected Studio sessions
  rojo-port-diagnostics
                Inspect worker/default Rojo ports and plugin-default risk
  rojo-sync-probe
                Write a temporary Rojo source sentinel and verify Studio sync
  startup-blockers
                OCR/AX probe for startup popups such as Auto-Recovery and Rojo connect
  profile       Sample accessibility, latency, CPU, and memory
  close-studio  Close only the worker-owned Studio pid from the manifest
  close-rojo    Close only the worker-owned Rojo pid from the manifest
  demo          Build place, start Rojo, launch Studio, probe/profile, close
  session       One-owner build/Rojo/Studio/MCP/profile/capture/cleanup flow

Options:
  --work-dir <dir>          Prototype work dir (default: ${DEFAULT_WORK_DIR})
  --place <path>            Place file path for start-studio/profile
  --project <path>          Rojo project file (default: default.project.json)
  --rojo-port <port>        Rojo port (default: ${DEFAULT_ROJO_PORT})
  --keep-open               Demo leaves Studio/Rojo running
  --wait-ms <ms>            Wait after launch before MCP/profile (default: 12000)
  --profile-ms <ms>         Resource sample duration (default: 8000)
  --studio-id <id>          Studio MCP id to select explicitly
  --expected-place <name>   Expected Studio game.Name / place basename
  --screenshot <path>       Existing screenshot for startup-blocker OCR test
  --text-fixture <path>     Existing text fixture for startup-blocker classifier test
  --isolate-desktop         Demo moves Studio into a full-screen Space before screenshots
  --startup-passes <n>      Re-capture startup blockers after safe actions (default: 1)
  --dismiss-startup-blockers
                            Click safe dismissal for detected Auto-Recovery
  --connect-rojo            Click Rojo connect prompt when detected
  --dismiss-stale-rojo      Click Dismiss for Rojo prompts whose port is not worker-owned
  --dry-run                 For session: emit the plan without launching Studio/Rojo
  --capture-plan <path>     For session: capture plan passed to the capture wrapper
  --capture-out <dir>       For session: capture output dir
  --skip-capture            For session: skip screenshot batch
  --rojo-sync-timeout-ms <ms>
                            For rojo-sync-probe: wait for temporary source sync (default: 10000)
`);
  process.exit(2);
}

function parseArgs(argv) {
  const command = argv[0] || usage();
  const args = createStudioControllerOptions({
    command,
  });

  for (let index = 1; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--work-dir") args.workDir = path.resolve(argv[++index] || usage());
    else if (arg === "--place") args.place = path.resolve(argv[++index] || usage());
    else if (arg === "--project") args.project = argv[++index] || usage();
    else if (arg === "--rojo-port") args.rojoPort = Number(argv[++index] || usage());
    else if (arg === "--keep-open") args.keepOpen = true;
    else if (arg === "--wait-ms") args.waitMs = Number(argv[++index] || usage());
    else if (arg === "--profile-ms") args.profileMs = Number(argv[++index] || usage());
    else if (arg === "--studio-id") args.studioId = argv[++index] || usage();
    else if (arg === "--expected-place") args.expectedPlace = argv[++index] || usage();
    else if (arg === "--screenshot") args.screenshot = path.resolve(argv[++index] || usage());
    else if (arg === "--text-fixture") args.textFixture = path.resolve(argv[++index] || usage());
    else if (arg === "--isolate-desktop") args.isolateDesktop = true;
    else if (arg === "--startup-passes") args.startupPasses = Number(argv[++index] || usage());
    else if (arg === "--dismiss-startup-blockers") args.dismissStartupBlockers = true;
    else if (arg === "--connect-rojo") args.connectRojo = true;
    else if (arg === "--dismiss-stale-rojo") args.dismissStaleRojo = true;
    else if (arg === "--dry-run") args.dryRun = true;
    else if (arg === "--capture-plan") args.capturePlan = path.resolve(argv[++index] || usage());
    else if (arg === "--capture-out") args.captureOut = path.resolve(argv[++index] || usage());
    else if (arg === "--skip-capture") args.skipCapture = true;
    else if (arg === "--rojo-sync-timeout-ms") args.rojoSyncTimeoutMs = Number(argv[++index] || usage());
    else if (arg === "--help" || arg === "-h") usage();
    else {
      console.error(`unknown option: ${arg}`);
      usage();
    }
  }
  validateStudioControllerOptions(args);
  return args;
}

export function createStudioControllerOptions(overrides = {}) {
  return {
    command: "env",
    workDir: DEFAULT_WORK_DIR,
    place: null,
    project: "default.project.json",
    rojoPort: DEFAULT_ROJO_PORT,
    keepOpen: false,
    waitMs: 12000,
    profileMs: 8000,
    studioId: null,
    expectedPlace: null,
    screenshot: null,
    textFixture: null,
    isolateDesktop: false,
    startupPasses: 1,
    dismissStartupBlockers: false,
    connectRojo: false,
    dismissStaleRojo: false,
    dryRun: false,
    capturePlan: null,
    captureOut: null,
    skipCapture: false,
    rojoSyncTimeoutMs: 10000,
    ...overrides,
  };
}

function validateStudioControllerOptions(args) {
  if (!Number.isFinite(args.rojoPort) || args.rojoPort < 1) throw new Error("--rojo-port must be a positive number");
  if (!Number.isFinite(args.startupPasses) || args.startupPasses < 1) throw new Error("--startup-passes must be a positive number");
  if (!Number.isFinite(args.rojoSyncTimeoutMs) || args.rojoSyncTimeoutMs < 1000) throw new Error("--rojo-sync-timeout-ms must be at least 1000");
}

function nowIso() {
  return new Date().toISOString();
}

function sleep(ms) {
  if (!ms || ms < 1) return;
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function mkdirp(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJson(filePath, value) {
  mkdirp(path.dirname(filePath));
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function commandExists(command) {
  const result = spawnSync("sh", ["-lc", `command -v ${JSON.stringify(command)}`], {
    encoding: "utf8",
  });
  return result.status === 0 ? result.stdout.trim() : null;
}

function runSync(command, args, options = {}) {
  const start = performance.now();
  const result = spawnSync(command, args, {
    cwd: REPO_ROOT,
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
    ...options,
  });
  return {
    command,
    args,
    status: result.status,
    signal: result.signal,
    durationMs: Math.round(performance.now() - start),
    stdout: result.stdout || "",
    stderr: result.stderr || "",
    error: result.error ? result.error.message : null,
  };
}

function runStartupOcr(screenshotPath, workDir) {
  const startedAt = performance.now();
  const ext = path.extname(screenshotPath) || ".png";
  const fullInputPath = path.join(workDir, `startup-blockers-ocr-full${ext}`);
  fs.copyFileSync(screenshotPath, fullInputPath);
  const full = runSync("tesseract", [fullInputPath, "stdout"]);
  const regions = [{
    name: "full",
    ok: full.status === 0,
    durationMs: full.durationMs,
    textSample: (full.stdout || "").slice(0, 1000),
    stderr: full.stderr,
  }];
  const crop = cropLowerRightForOcr(fullInputPath, workDir);
  let cropOcr = { status: 1, stdout: "", stderr: crop.stderr || "" };
  if (crop.ok) {
    cropOcr = runSync("tesseract", [crop.path, "stdout"]);
    regions.push({
      name: "lower_right",
      ok: cropOcr.status === 0,
      durationMs: cropOcr.durationMs,
      textSample: (cropOcr.stdout || "").slice(0, 1000),
      crop,
      stderr: cropOcr.stderr,
    });
  } else {
    regions.push({ name: "lower_right", ok: false, crop, stderr: crop.stderr });
  }
  return {
    status: full.status === 0 || cropOcr.status === 0 ? 0 : 1,
    durationMs: Math.round(performance.now() - startedAt),
    stdout: [full.stdout || "", cropOcr.stdout || ""].filter(Boolean).join("\n"),
    stderr: [full.stderr || "", cropOcr.stderr || "", crop.stderr || ""].filter(Boolean).join("\n"),
    regions,
  };
}

function cropLowerRightForOcr(imagePath, workDir) {
  const size = imagePixelSize(imagePath);
  if (!size.ok) return { ok: false, stderr: size.stderr || "missing image size" };
  const cropWidth = Math.max(240, Math.round(size.width * 0.36));
  const cropHeight = Math.max(160, Math.round(size.height * 0.24));
  const offsetX = Math.max(0, size.width - cropWidth);
  const offsetY = Math.max(0, size.height - cropHeight);
  const cropPath = path.join(workDir, "startup-blockers-ocr-lower-right.png");
  const result = runSync("sips", [
    "--cropToHeightWidth", String(cropHeight), String(cropWidth),
    "--cropOffset", String(offsetY), String(offsetX),
    imagePath,
    "--out", cropPath,
  ]);
  return {
    ok: result.status === 0 && fs.existsSync(cropPath),
    path: cropPath,
    source: imagePath,
    width: cropWidth,
    height: cropHeight,
    offsetX,
    offsetY,
    durationMs: result.durationMs,
    stderr: result.stderr,
  };
}

function imagePixelSize(imagePath) {
  const result = runSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", imagePath]);
  const width = Number((result.stdout.match(/pixelWidth:\s*(\d+)/) || [])[1]);
  const height = Number((result.stdout.match(/pixelHeight:\s*(\d+)/) || [])[1]);
  return {
    ok: result.status === 0 && Number.isFinite(width) && Number.isFinite(height),
    width,
    height,
    stderr: result.stderr,
  };
}

function listProcesses() {
  const result = runSync("ps", ["axo", "pid=,ppid=,%cpu=,%mem=,rss=,command="], {
    maxBuffer: 16 * 1024 * 1024,
  });
  const rows = [];
  for (const line of result.stdout.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const match = trimmed.match(/^(\d+)\s+(\d+)\s+([\d.]+)\s+([\d.]+)\s+(\d+)\s+(.+)$/);
    if (!match) continue;
    rows.push({
      pid: Number(match[1]),
      ppid: Number(match[2]),
      cpuPercent: Number(match[3]),
      memPercent: Number(match[4]),
      rssKb: Number(match[5]),
      command: match[6],
    });
  }
  return rows;
}

function isPidRunning(pid) {
  if (!pid) return false;
  const result = spawnSync("ps", ["-p", String(pid), "-o", "stat="], { encoding: "utf8" });
  if (result.status !== 0) return false;
  const stat = result.stdout.trim();
  return Boolean(stat) && !stat.includes("Z");
}

function waitForPidExit(pid, timeoutMs = 30000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (!isPidRunning(pid)) return true;
    sleep(500);
  }
  return !isPidRunning(pid);
}

function waitForPort(port, host = "127.0.0.1", timeoutMs = 10000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const ok = spawnSync(process.execPath, ["-e", `
const net = require("node:net");
const socket = net.createConnection({ host: ${JSON.stringify(host)}, port: ${Number(port)} });
socket.setTimeout(750);
socket.on("connect", () => process.exit(0));
socket.on("timeout", () => process.exit(1));
socket.on("error", () => process.exit(1));
`], { encoding: "utf8" });
    if (ok.status === 0) return true;
    sleep(250);
  }
  return false;
}

function readRojoServerInfo(port) {
  const result = runSync("curl", [
    "--silent",
    "--show-error",
    "--max-time",
    "2",
    `http://127.0.0.1:${Number(port)}/api/rojo`,
  ]);
  let parsed = null;
  let parseError = null;
  if (result.stdout) {
    try {
      parsed = JSON.parse(result.stdout);
    } catch (err) {
      parseError = err.message;
    }
  }
  return {
    ok: Boolean(result.status === 0 && parsed && typeof parsed === "object" && typeof parsed.projectName === "string"),
    port: Number(port),
    url: `http://127.0.0.1:${Number(port)}/api/rojo`,
    status: result.status,
    durationMs: result.durationMs,
    serverVersion: parsed?.serverVersion || null,
    protocolVersion: parsed?.protocolVersion || null,
    projectName: parsed?.projectName || null,
    sessionId: parsed?.sessionId || null,
    rootInstanceId: parsed?.rootInstanceId || null,
    expectedPlaceIds: parsed?.expectedPlaceIds ?? null,
    unexpectedPlaceIds: parsed?.unexpectedPlaceIds ?? null,
    parseError,
    stderr: result.stderr,
    stdoutSample: parsed ? undefined : result.stdout.slice(0, 500),
  };
}

function processInfoForPort(port) {
  const result = runSync("lsof", [
    "-nP",
    `-iTCP:${Number(port)}`,
    "-sTCP:LISTEN",
    "-t",
  ]);
  const pids = [...new Set(
    result.stdout
      .split(/\r?\n/)
      .map((line) => Number(line.trim()))
      .filter((pid) => Number.isFinite(pid) && pid > 0)
  )];
  const processes = listProcesses()
    .filter((entry) => pids.includes(entry.pid))
    .map((entry) => ({
      pid: entry.pid,
      ppid: entry.ppid,
      cpuPercent: entry.cpuPercent,
      memPercent: entry.memPercent,
      rssMb: Math.round(entry.rssKb / 102.4) / 10,
      command: entry.command.slice(0, 300),
    }));
  return {
    ok: pids.length > 0,
    port: Number(port),
    pids,
    processes,
    status: result.status,
    stderr: result.stderr,
  };
}

function collectRojoPortDiagnostics(workerPort, manifest = {}) {
  const workerRojoPid = manifest.processes?.rojo?.pid || null;
  const ports = [...new Set([ROJO_PLUGIN_DEFAULT_PORT, Number(workerPort)].filter(Boolean))];
  const checks = ports.map((port) => ({
    port,
    server: readRojoServerInfo(port),
    listener: processInfoForPort(port),
  }));
  const defaultCheck = checks.find((check) => check.port === ROJO_PLUGIN_DEFAULT_PORT) || null;
  const workerCheck = checks.find((check) => check.port === Number(workerPort)) || null;
  const defaultOwnedByWorker = Boolean(workerRojoPid && defaultCheck?.listener?.pids?.includes(workerRojoPid));
  const workerOwnedByWorker = Boolean(workerRojoPid && workerCheck?.listener?.pids?.includes(workerRojoPid));
  let acceptanceRisk = null;
  if (!workerCheck?.server?.ok) {
    acceptanceRisk = "worker_rojo_server_not_ready";
  } else if (Number(workerPort) !== ROJO_PLUGIN_DEFAULT_PORT && defaultCheck?.server?.ok && !defaultOwnedByWorker) {
    acceptanceRisk = "rojo_plugin_default_port_occupied_by_non_worker_server";
  } else if (Number(workerPort) !== ROJO_PLUGIN_DEFAULT_PORT) {
    acceptanceRisk = "worker_rojo_port_is_not_plugin_default";
  } else if (!workerOwnedByWorker) {
    acceptanceRisk = "default_rojo_port_not_owned_by_worker";
  }
  return {
    schema: "studio-controller-rojo-port-diagnostics/v1",
    generatedAt: nowIso(),
    pluginDefaultPort: ROJO_PLUGIN_DEFAULT_PORT,
    workerPort: Number(workerPort),
    workerRojoPid,
    workerServerReady: Boolean(workerCheck?.server?.ok),
    pluginDefaultCanReachWorker: Number(workerPort) === ROJO_PLUGIN_DEFAULT_PORT && defaultOwnedByWorker,
    acceptanceRisk,
    checks,
    recommendation: acceptanceRisk
      ? "Drive the Rojo Studio plugin to the worker-owned port or run the worker on the default port in a clean state before claiming Rojo acceptance."
      : "Rojo default-port ownership matches the worker; a Studio plugin Connect action can be treated as worker-owned if the sentinel also syncs.",
  };
}

export class StudioControllerPrototype {
  constructor(options) {
    this.options = options;
    this.workDir = options.workDir;
    this.manifestPath = path.join(this.workDir, "manifest.json");
    this.metricsPath = path.join(this.workDir, "profile.json");
    this.studioPath = DEFAULT_STUDIO;
    this.mcpPath = process.env.STUDIO_MCP_COMMAND || DEFAULT_MCP;
  }

  manifest() {
    return readJsonIfExists(this.manifestPath) || {
      schema: "studio-controller-prototype-manifest/v1",
      createdAt: nowIso(),
      workDir: this.workDir,
      processes: {},
      events: [],
    };
  }

  saveManifest(patch) {
    const manifest = this.manifest();
    const next = {
      ...manifest,
      ...patch,
      updatedAt: nowIso(),
      events: [...(manifest.events || []), ...(patch.events || [])],
      processes: { ...(manifest.processes || {}), ...(patch.processes || {}) },
    };
    writeJson(this.manifestPath, next);
    return next;
  }

  research() {
    return {
      schema: "studio-controller-research/v1",
      generatedAt: nowIso(),
      conclusions: [
        "Use built-in StudioMCP first because it supports list_roblox_studios and set_active_studio.",
        "Use run-in-roblox style session plugin as the coded-bot fallback for programmatic Studio bootstrap.",
        "Use Rojo serve as a worker-owned subprocess; Studio plugin connection may still need a Studio-side plugin or session plugin bridge.",
        "Use rbx-dom/Lune/Rojo build for file creation and mutation outside Studio; use Studio only for viewport/playtest evidence.",
      ],
      sources: [
        {
          label: "Roblox Studio MCP docs",
          url: "https://create.roblox.com/docs/studio/mcp",
          note: "Built-in stdio MCP, UI enable path, list_roblox_studios, set_active_studio.",
        },
        {
          label: "Roblox Studio CLI docs",
          url: "https://create.roblox.com/docs/studio/command-line-interface",
          note: "Supported command-line startup behavior; local -localPlaceFile is observed locally but not documented on the opened page.",
        },
        {
          label: "Roblox external tools / Rojo docs",
          url: "https://create.roblox.com/docs/projects/external-tools",
          note: "Rojo server plus Studio plugin connection pattern.",
        },
        {
          label: "rojo-rbx/run-in-roblox",
          url: "https://github.com/rojo-rbx/run-in-roblox",
          note: "Temp place, temp plugin, unique local bridge, run script, stream output, exit pattern.",
        },
        {
          label: "Roblox/studio-rust-mcp-server",
          url: "https://github.com/Roblox/studio-rust-mcp-server",
          note: "Archived reference for Rust stdio MCP plus Studio plugin long-poll bridge.",
        },
        {
          label: "rojo-rbx/rojo",
          url: "https://github.com/rojo-rbx/rojo",
          note: "Filesystem-first Roblox workflow and Rojo Studio plugin/server sync.",
        },
        {
          label: "rojo-rbx/rbx-dom",
          url: "https://github.com/rojo-rbx/rbx-dom",
          note: "rbxl/rbxm/rbxlx/rbxmx serializer/deserializer crates.",
        },
      ],
    };
  }

  env() {
    const studios = listProcesses().filter((entry) =>
      entry.command.includes("/Contents/MacOS/RobloxStudio")
      || entry.command.includes("/Contents/MacOS/StudioMCP")
      || /\brojo serve\b/.test(entry.command)
    );
    return {
      schema: "studio-controller-env/v1",
      generatedAt: nowIso(),
      repoRoot: REPO_ROOT,
      studioPath: this.studioPath,
      studioExists: fs.existsSync(this.studioPath),
      builtInMcpPath: DEFAULT_MCP,
      builtInMcpExists: fs.existsSync(DEFAULT_MCP),
      selectedMcpPath: this.mcpPath,
      selectedMcpExists: fs.existsSync(this.mcpPath),
      rojo: commandExists("rojo"),
      lune: commandExists("lune"),
      projectExists: fs.existsSync(path.resolve(REPO_ROOT, this.options.project)),
      relevantProcesses: studios,
    };
  }

  buildPlace() {
    mkdirp(this.workDir);
    const placePath = this.options.place || path.join(this.workDir, "prototype-place.rbxl");
    const projectPath = path.resolve(REPO_ROOT, this.options.project);
    const result = runSync("rojo", ["build", projectPath, "-o", placePath]);
    if (result.status !== 0) {
      throw new Error(`rojo build failed\n${result.stderr}\n${result.stdout}`);
    }
    const manifest = this.saveManifest({
      placePath,
      expectedPlace: this.options.expectedPlace || path.basename(placePath),
      events: [{ at: nowIso(), type: "build-place", durationMs: result.durationMs, placePath }],
    });
    return { ok: true, placePath, bytes: fs.statSync(placePath).size, durationMs: result.durationMs, manifestPath: this.manifestPath, manifest };
  }

  startRojo() {
    mkdirp(this.workDir);
    const projectPath = path.resolve(REPO_ROOT, this.options.project);
    const logPath = path.join(this.workDir, "rojo.log");
    const out = fs.openSync(logPath, "a");
    const child = spawn("rojo", ["serve", projectPath, "--address", "127.0.0.1", "--port", String(this.options.rojoPort)], {
      cwd: REPO_ROOT,
      detached: true,
      stdio: ["ignore", out, out],
    });
    child.unref();
    const ready = waitForPort(this.options.rojoPort, "127.0.0.1", 10000);
    const manifest = this.saveManifest({
      rojoPort: this.options.rojoPort,
      processes: {
        rojo: { pid: child.pid, logPath, projectPath, startedAt: nowIso(), workerOwned: true },
      },
      events: [{ at: nowIso(), type: "start-rojo", pid: child.pid, ready, port: this.options.rojoPort }],
    });
    return { ok: ready, pid: child.pid, port: this.options.rojoPort, logPath, manifestPath: this.manifestPath, manifest };
  }

  startStudio() {
    mkdirp(this.workDir);
    const manifest = this.manifest();
    const placePath = this.options.place || manifest.placePath || path.join(this.workDir, "prototype-place.rbxl");
    if (!fs.existsSync(placePath)) throw new Error(`place file does not exist: ${placePath}`);
    const logPath = path.join(this.workDir, "studio.log");
    const out = fs.openSync(logPath, "a");
    const start = performance.now();
    const child = spawn(this.studioPath, ["-localPlaceFile", placePath], {
      cwd: REPO_ROOT,
      detached: true,
      stdio: ["ignore", out, out],
    });
    child.unref();
    const updated = this.saveManifest({
      placePath,
      expectedPlace: this.options.expectedPlace || path.basename(placePath),
      processes: {
        studio: { pid: child.pid, logPath, placePath, startedAt: nowIso(), workerOwned: true },
      },
      events: [{ at: nowIso(), type: "start-studio", pid: child.pid, durationMs: Math.round(performance.now() - start) }],
    });
    return { ok: true, pid: child.pid, placePath, logPath, manifestPath: this.manifestPath, manifest: updated };
  }

  callMcp(toolName, args = {}, options = {}) {
    const start = performance.now();
    let argsValue = JSON.stringify(args || {});
    let tempDir = null;
    if (toolName === "run_code" && options.commandText) {
      mkdirp(this.workDir);
      tempDir = fs.mkdtempSync(path.join(this.workDir, "mcp-run-code-"));
      const commandPath = path.join(tempDir, "command.luau");
      fs.writeFileSync(commandPath, options.commandText);
      argsValue = `@${commandPath}`;
    }
    const result = spawnSync(process.execPath, ["tools/studio_mcp_call.js", toolName, argsValue], {
      cwd: REPO_ROOT,
      env: { ...process.env, STUDIO_MCP_COMMAND: this.mcpPath, STUDIO_MCP_TIMEOUT_MS: process.env.STUDIO_MCP_TIMEOUT_MS || "45000" },
      encoding: "utf8",
      maxBuffer: 128 * 1024 * 1024,
    });
    if (tempDir) fs.rmSync(tempDir, { recursive: true, force: true });
    const durationMs = Math.round(performance.now() - start);
    let parsed = null;
    try {
      parsed = result.stdout ? JSON.parse(result.stdout) : null;
    } catch {
      parsed = null;
    }
    return {
      ok: result.status === 0,
      status: result.status,
      signal: result.signal,
      durationMs,
      toolName,
      parsed,
      stdout: parsed ? undefined : result.stdout,
      stderr: result.stderr,
      error: result.error ? result.error.message : null,
    };
  }

  requireMcp(toolName, args = {}, options = {}) {
    const result = this.callMcp(toolName, args, options);
    if (!result.ok) {
      throw new Error(`${toolName} failed with status ${result.status}\n${result.stderr}\n${result.stdout || ""}`);
    }
    return result.parsed;
  }

  createMcpAdapter() {
    const toolsCall = this.callMcp("tools/list", {});
    const names = mcpToolNames(toolsCall);
    return {
      controller: this,
      toolsCall,
      toolsResult: toolsCall.parsed,
      toolNames: names,
      luauTool: names.includes("execute_luau") ? "execute_luau" : "run_code",
      captureTool: names.includes("screen_capture") ? "screen_capture" : "capture_screenshot",
    };
  }

  listStudioTargets() {
    const listStudios = this.callMcp("list_roblox_studios", {});
    return {
      raw: listStudios,
      studios: parseStudioList(listStudios),
    };
  }

  selectStudioTarget() {
    const manifest = this.manifest();
    const expectedPlace = this.options.expectedPlace || manifest.expectedPlace || null;
    const expectedBasename = expectedPlace ? path.basename(expectedPlace) : null;
    const listed = this.listStudioTargets();
    const studios = listed.studios;
    let selected = null;
    let reason = "";

    if (this.options.studioId) {
      selected = studios.find((studio) => studio.id === this.options.studioId) || null;
      reason = "explicit-studio-id";
    }
    if (!selected && expectedBasename) {
      selected = studios.find((studio) => studio.name === expectedBasename) || null;
      reason = "expected-place-name";
    }
    if (!selected && studios.length === 1) {
      selected = studios[0];
      reason = "single-open-studio";
    }
    if (!selected && studios.find((studio) => studio.active)) {
      selected = studios.find((studio) => studio.active);
      reason = "already-active-fallback";
    }

    const setActive = selected?.id
      ? this.callMcp("set_active_studio", { studio_id: selected.id })
      : { ok: false, skipped: "no matching Studio instance", durationMs: 0 };
    const verify = setActive.ok ? this.listStudioTargets() : null;
    const selection = {
      schema: "studio-controller-active-studio/v1",
      generatedAt: nowIso(),
      expectedPlace,
      explicitStudioId: this.options.studioId,
      selected,
      reason,
      listStudios: summarizeStudioList(listed.raw, studios),
      setActive: summarizeMcpCall(setActive),
      verify: verify && summarizeStudioList(verify.raw, verify.studios),
      ok: Boolean(selected?.id && setActive.ok),
    };
    this.saveManifest({
      activeStudio: selection,
      events: [{ at: nowIso(), type: "select-studio", ok: selection.ok, selected: selected && { id: selected.id, name: selected.name }, reason }],
    });
    return selection;
  }

  mcpProbe() {
    const tools = this.callMcp("tools/list", {});
    const toolNames = mcpToolNames(tools);
    const activeStudio = toolNames.includes("set_active_studio") && toolNames.includes("list_roblox_studios")
      ? this.selectStudioTarget()
      : { ok: false, skipped: "list_roblox_studios/set_active_studio not present in selected MCP" };
    const expectedPlace = this.options.expectedPlace || this.manifest().expectedPlace || null;
    const stateExpression = `HttpService:JSONEncode({
  placeName = game.Name,
  placeId = game.PlaceId,
  jobId = game.JobId,
  expectedPlace = ${JSON.stringify(expectedPlace)},
  workspaceName = workspace.Name,
  time = os.time(),
})`;
    const returnStateCode = `
local HttpService = game:GetService("HttpService")
return "STUDIO_CONTROLLER_PROTOTYPE_STATE " .. ${stateExpression}
`;
    const printStateCode = `
local HttpService = game:GetService("HttpService")
print("STUDIO_CONTROLLER_PROTOTYPE_STATE " .. ${stateExpression})
`;
    const luauTool = toolNames.includes("execute_luau") ? "execute_luau" : "run_code";
    const studioState = toolNames.includes("get_studio_state")
      ? this.callMcp("get_studio_state", {})
      : { ok: false, skipped: "get_studio_state not present in selected MCP" };
    const runCode = luauTool === "execute_luau"
      ? this.callMcp("execute_luau", { code: returnStateCode, datamodel_type: "Edit" })
      : this.callMcp("run_code", { command: printStateCode });
    const runSummary = summarizeRunCode(runCode);
    const targetMatch = Boolean(
      runSummary.state?.placeName
      && expectedPlace
      && runSummary.state.placeName === path.basename(expectedPlace)
    );
    const probe = {
      schema: "studio-controller-mcp-probe/v1",
      generatedAt: nowIso(),
      selectedMcpPath: this.mcpPath,
      expectedPlace,
      tools: summarizeMcpTools(tools),
      activeStudio,
      luauTool,
      studioState: summarizeMcpCall(studioState),
      runCode: runSummary,
      targetMatch,
      rawDurationsMs: {
        toolsList: tools.durationMs,
        selectStudio: activeStudio.setActive?.durationMs || 0,
        studioState: studioState.durationMs || 0,
        runCode: runCode.durationMs,
      },
    };
    this.saveManifest({
      lastMcpProbe: probe,
      events: [{ at: nowIso(), type: "mcp-probe", ok: tools.ok && runCode.ok && activeStudio.ok, expectedPlace, targetMatch }],
    });
    return probe;
  }

  rojoPortDiagnostics() {
    mkdirp(this.workDir);
    const manifest = this.manifest();
    const report = collectRojoPortDiagnostics(manifest.rojoPort || this.options.rojoPort, manifest);
    const reportPath = path.join(this.workDir, "rojo-port-diagnostics.json");
    writeJson(reportPath, report);
    this.saveManifest({
      lastRojoPortDiagnosticsPath: reportPath,
      lastRojoPortDiagnostics: {
        workerPort: report.workerPort,
        pluginDefaultPort: report.pluginDefaultPort,
        workerServerReady: report.workerServerReady,
        pluginDefaultCanReachWorker: report.pluginDefaultCanReachWorker,
        acceptanceRisk: report.acceptanceRisk,
        reportPath,
      },
      events: [{
        at: nowIso(),
        type: "rojo-port-diagnostics",
        workerPort: report.workerPort,
        pluginDefaultPort: report.pluginDefaultPort,
        acceptanceRisk: report.acceptanceRisk,
        reportPath,
      }],
    });
    return { ok: true, reportPath, report };
  }

  executeMarkedLuau(source, marker) {
    const tools = this.callMcp("tools/list", {});
    const toolNames = mcpToolNames(tools);
    const luauTool = toolNames.includes("execute_luau") ? "execute_luau" : "run_code";
    const result = luauTool === "execute_luau"
      ? this.callMcp("execute_luau", { code: source, datamodel_type: "Edit" })
      : this.callMcp("run_code", {}, { commandText: source });
    const text = mcpText(result);
    const line = text.split(/\r?\n/).find((candidate) => candidate.includes(marker));
    let payload = null;
    if (line) {
      try {
        payload = JSON.parse(line.slice(line.indexOf(marker) + marker.length));
      } catch {
        payload = null;
      }
    }
    return {
      ok: result.ok,
      luauTool,
      result: summarizeMcpCall(result),
      payload,
      markerFound: Boolean(line),
    };
  }

  rojoSyncProbe() {
    mkdirp(this.workDir);
    const manifest = this.manifest();
    const expectedPlace = this.options.expectedPlace || manifest.expectedPlace || null;
    const projectPath = path.resolve(REPO_ROOT, this.options.project);
    const sentinelName = `StudioControllerRojoSentinel_${Date.now()}`;
    const token = `${sentinelName}_${Math.random().toString(36).slice(2)}`;
    const sourceDir = path.join(REPO_ROOT, "src/ReplicatedStorage/Shared");
    const sourcePath = path.join(sourceDir, `${sentinelName}.lua`);
    const marker = "STUDIO_CONTROLLER_ROJO_SYNC ";
    const timeoutMs = this.options.rojoSyncTimeoutMs;
    const pollEveryMs = 500;
    const probes = [];
    const startedAt = performance.now();
    let writeError = null;
    let cleanupError = null;
    let observed = null;
    let removed = null;
    const portDiagnostics = this.rojoPortDiagnostics();

    const makeProbeLuau = () => `
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local target = shared and shared:FindFirstChild(${JSON.stringify(sentinelName)}) or nil
local source = nil
if target and target:IsA("ModuleScript") then
	source = target.Source
end
local payload = {
	schema = "studio-controller-rojo-sync-probe/v1",
	expectedPlace = ${JSON.stringify(expectedPlace)},
	placeName = game.Name,
	name = ${JSON.stringify(sentinelName)},
	exists = target ~= nil,
	className = target and target.ClassName or nil,
	sourceHasToken = source ~= nil and string.find(source, ${JSON.stringify(token)}, 1, true) ~= nil,
}
return ${JSON.stringify(marker)} .. HttpService:JSONEncode(payload)
`;

    try {
      mkdirp(sourceDir);
      fs.writeFileSync(sourcePath, `-- PROTOTYPE TEMP Rojo sync sentinel. Deleted by studio_controller_prototype.\nreturn { token = ${JSON.stringify(token)} }\n`);
    } catch (err) {
      writeError = err.message;
    }

    if (!writeError) {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        const probe = this.executeMarkedLuau(makeProbeLuau(), marker);
        probes.push({
          tMs: Math.round(performance.now() - startedAt),
          ok: probe.ok,
          markerFound: probe.markerFound,
          payload: probe.payload,
          luauTool: probe.luauTool,
        });
        if (
          probe.payload
          && probe.payload.placeName === path.basename(expectedPlace || probe.payload.placeName)
          && probe.payload.exists
          && probe.payload.sourceHasToken
        ) {
          observed = probe.payload;
          break;
        }
        sleep(pollEveryMs);
      }
    }

    try {
      if (fs.existsSync(sourcePath)) fs.rmSync(sourcePath, { force: true });
    } catch (err) {
      cleanupError = err.message;
    }

    if (observed) {
      const deadline = Date.now() + Math.min(timeoutMs, 5000);
      while (Date.now() < deadline) {
        const probe = this.executeMarkedLuau(makeProbeLuau(), marker);
        probes.push({
          tMs: Math.round(performance.now() - startedAt),
          ok: probe.ok,
          markerFound: probe.markerFound,
          payload: probe.payload,
          luauTool: probe.luauTool,
          phase: "delete-check",
        });
        if (probe.payload && probe.payload.exists === false) {
          removed = probe.payload;
          break;
        }
        sleep(pollEveryMs);
      }
    }

    const report = {
      schema: "studio-controller-rojo-sync-probe/v1",
      generatedAt: nowIso(),
      ok: Boolean(observed && removed && !writeError && !cleanupError),
      likelyFailureReason: inferRojoSyncFailureReason({
        observed,
        removed,
        writeError,
        cleanupError,
        diagnostics: portDiagnostics.report,
      }),
      projectPath,
      expectedPlace,
      rojoPort: manifest.rojoPort || this.options.rojoPort,
      rojoPortDiagnosticsPath: portDiagnostics.reportPath,
      rojoPortDiagnostics: portDiagnostics.report,
      sourcePath,
      sentinelName,
      token,
      timeoutMs,
      durationMs: Math.round(performance.now() - startedAt),
      writeError,
      cleanupError,
      observed,
      removed,
      probeCount: probes.length,
      probes,
    };
    const reportPath = path.join(this.workDir, "rojo-sync-probe.json");
    writeJson(reportPath, report);
    this.saveManifest({
      lastRojoSyncProbePath: reportPath,
      lastRojoSyncProbe: {
        ok: report.ok,
        observed: Boolean(observed),
        removed: Boolean(removed),
        sourcePath,
        reportPath,
      },
      events: [{ at: nowIso(), type: "rojo-sync-probe", ok: report.ok, observed: Boolean(observed), removed: Boolean(removed), reportPath }],
    });
    return { ok: report.ok, reportPath, observed: Boolean(observed), removed: Boolean(removed), durationMs: report.durationMs, report };
  }

  activateStudio() {
    const script = `
tell application "System Events"
  set activatedProcess to ""
  repeat with procName in {"RobloxStudio", "Roblox Studio"}
    if exists process procName then
      tell process procName
        set frontmost to true
      end tell
      set activatedProcess to procName as text
      exit repeat
    end if
  end repeat
  if activatedProcess is "" then
    return "missing"
  else
    return "activated=" & activatedProcess
  end if
end tell
`;
    const result = runSync("osascript", ["-e", script]);
    return {
      ok: result.status === 0 && result.stdout.includes("activated="),
      durationMs: result.durationMs,
      stdout: result.stdout.trim(),
      stderr: result.stderr.trim(),
    };
  }

  isolateStudioDesktop() {
    mkdirp(this.workDir);
    const before = this.accessibilityProbe();
    const activation = this.activateStudio();
    sleep(750);
    const script = `
tell application "System Events"
  set toggledProcess to ""
  repeat with procName in {"RobloxStudio", "Roblox Studio"}
    if exists process procName then
      tell process procName
        set frontmost to true
        delay 0.2
        keystroke "f" using {control down, command down}
      end tell
      set toggledProcess to procName as text
      exit repeat
    end if
  end repeat
  if toggledProcess is "" then
    return "missing"
  else
    return "fullscreen-space-toggle=" & toggledProcess
  end if
end tell
`;
    const toggle = runSync("osascript", ["-e", script]);
    sleep(2500);
    const afterActivation = this.activateStudio();
    const after = this.accessibilityProbe();
    const report = {
      schema: "studio-controller-desktop-isolation/v1",
      generatedAt: nowIso(),
      strategy: "macos-fullscreen-space",
      note: "macOS has no stable public CLI for creating Spaces; full-screen Studio creates an isolated Space for screenshots/OCR.",
      before,
      activation,
      toggle: {
        ok: toggle.status === 0 && toggle.stdout.includes("fullscreen-space-toggle="),
        durationMs: toggle.durationMs,
        stdout: toggle.stdout.trim(),
        stderr: toggle.stderr.trim(),
      },
      afterActivation,
      after,
    };
    const reportPath = path.join(this.workDir, "desktop-isolation.json");
    writeJson(reportPath, report);
    this.saveManifest({
      lastDesktopIsolationPath: reportPath,
      events: [{ at: nowIso(), type: "isolate-desktop", ok: report.toggle.ok, reportPath }],
    });
    return { ok: report.toggle.ok, reportPath, report };
  }

  startupBlockers() {
    const maxPasses = this.options.textFixture || this.options.screenshot
      ? 1
      : Math.max(1, Math.floor(this.options.startupPasses));
    const passes = [];
    let finalPass = null;

    for (let passIndex = 1; passIndex <= maxPasses; passIndex += 1) {
      finalPass = this.startupBlockerPass(passIndex);
      passes.push(finalPass);
      const shouldRecapture = finalPass.actions.some((action) => action.recapture);
      if (!shouldRecapture) break;
      sleep(900);
    }

    const report = {
      ...finalPass,
      schema: "studio-controller-startup-blockers/v1",
      generatedAt: nowIso(),
      maxPasses,
      passCount: passes.length,
      passes,
    };
    const reportPath = path.join(this.workDir, "startup-blockers.json");
    writeJson(reportPath, report);
    this.saveManifest({
      lastStartupBlockersPath: reportPath,
      events: [{
        at: nowIso(),
        type: "startup-blockers",
        blockerKinds: (finalPass.blockers || []).map((blocker) => blocker.kind),
        actionLabels: (finalPass.actions || []).map((action) => action.label),
        reportPath,
      }],
    });
    return { ok: true, reportPath, blockerKinds: (finalPass.blockers || []).map((blocker) => blocker.kind), report };
  }

  startupBlockerPass(passIndex) {
    mkdirp(this.workDir);
    const screenshotPath = this.options.screenshot || path.join(this.workDir, `startup-blockers-screen-pass-${passIndex}.png`);
    let screenshot = { ok: false, path: null, reused: false };
    let ocr = { status: 0, durationMs: 0, stdout: "", stderr: "" };
    let activation = null;
    const liveUiClickEnabled = !this.options.textFixture && !this.options.screenshot;
    if (this.options.textFixture) {
      ocr = {
        status: 0,
        durationMs: 0,
        stdout: fs.readFileSync(this.options.textFixture, "utf8"),
        stderr: "",
        fixturePath: this.options.textFixture,
      };
    } else if (this.options.screenshot) {
      screenshot = { ok: fs.existsSync(screenshotPath), path: screenshotPath, reused: true };
    } else {
      activation = this.activateStudio();
      sleep(500);
      const result = runSync("screencapture", ["-x", screenshotPath]);
      screenshot = { ok: result.status === 0, path: screenshotPath, reused: false, durationMs: result.durationMs, stderr: result.stderr };
    }
    if (!this.options.textFixture) {
      if (screenshot.ok) {
        ocr = runStartupOcr(screenshotPath, this.workDir);
      } else {
        ocr = { status: 1, stdout: "", stderr: "missing screenshot" };
      }
    }
    const ocrText = ocr.stdout || "";
    const blockers = detectStartupBlockersFromText(ocrText);
    const ax = liveUiClickEnabled
      ? this.accessibilityProbe()
      : { ok: true, skipped: "fixture/reused screenshot", durationMs: 0, stdout: "", stderr: "" };
    const actions = [];
    const expectedRojoPort = this.manifest().rojoPort || this.options.rojoPort;
    let modalActionTaken = false;

    if (this.options.dismissStartupBlockers && blockers.some((blocker) => blocker.kind === "auto_recovery")) {
      if (liveUiClickEnabled) {
        this.activateStudio();
        sleep(150);
        const axClick = this.clickAccessibilityButton("auto_recovery_ignore", "Auto-Recovery", "Ignore");
        actions.push({
          ...(axClick.ok ? axClick : this.clickScreenFraction("auto_recovery_ignore_fallback", 0.495, 0.64)),
          recapture: true,
        });
        modalActionTaken = true;
        sleep(750);
      } else {
        actions.push({
          label: "auto_recovery_ignore_skipped",
          ok: false,
          reason: "click disabled for fixture/reused screenshot",
        });
      }
    }
    const rojoConnect = blockers.find((blocker) => blocker.kind === "rojo_connect");
    if (!modalActionTaken && this.options.connectRojo && rojoConnect) {
      if (rojoConnect.port === expectedRojoPort) {
        if (liveUiClickEnabled) {
          this.activateStudio();
          sleep(150);
          actions.push({ ...this.clickScreenFraction("rojo_connect", 0.948, 0.907), recapture: true });
          sleep(750);
        } else {
          actions.push({
            label: "rojo_connect_skipped",
            ok: false,
            reason: "click disabled for fixture/reused screenshot",
            detectedPort: rojoConnect.port,
            expectedPort: expectedRojoPort,
          });
        }
      } else if (this.options.dismissStaleRojo) {
        if (liveUiClickEnabled) {
          this.activateStudio();
          sleep(150);
          actions.push({
            ...this.clickScreenFraction("rojo_stale_dismiss", 0.895, 0.907),
            recapture: true,
            detectedPort: rojoConnect.port,
            expectedPort: expectedRojoPort,
          });
          sleep(750);
        } else {
          actions.push({
            label: "rojo_stale_dismiss_skipped",
            ok: false,
            reason: "click disabled for fixture/reused screenshot",
            detectedPort: rojoConnect.port,
            expectedPort: expectedRojoPort,
          });
        }
      } else {
        actions.push({
          label: "rojo_connect_skipped",
          ok: false,
          reason: "detected Rojo prompt port does not match worker-owned manifest port",
          detectedPort: rojoConnect.port,
          expectedPort: expectedRojoPort,
        });
      }
    }

    return {
      passIndex,
      generatedAt: nowIso(),
      activation,
      expectedRojoPort,
      screenshot,
      ocr: {
        ok: ocr.status === 0,
        durationMs: ocr.durationMs,
        textSample: ocrText.slice(0, 2000),
        stderr: ocr.stderr,
        regions: ocr.regions || [],
      },
      blockers,
      accessibility: ax,
      actions,
    };
  }

  profile() {
    const manifest = this.manifest();
    const pid = manifest.processes?.studio?.pid;
    const placePath = this.options.place || manifest.placePath || null;
    const expectedPlace = this.options.expectedPlace || manifest.expectedPlace || (placePath ? path.basename(placePath) : null);
    const samples = [];
    const startedAt = Date.now();
    while (Date.now() - startedAt < this.options.profileMs) {
      const processes = listProcesses();
      const studio = processes.find((entry) => entry.pid === pid) || null;
      const mcp = processes.filter((entry) => entry.command.includes("/Contents/MacOS/StudioMCP"));
      const rojo = processes.filter((entry) => /\brojo serve\b/.test(entry.command));
      samples.push({
        tMs: Date.now() - startedAt,
        studio: studio && pickResource(studio),
        studioMcpCount: mcp.length,
        rojo: rojo.map(pickResource),
      });
      sleep(1000);
    }
    const accessibility = this.accessibilityProbe();
    const mcpLatency = this.mcpProbe();
    const report = {
      schema: "studio-controller-profile/v1",
      generatedAt: nowIso(),
      expectedPlace,
      placePath,
      workerStudioPid: pid || null,
      workerStudioRunning: isPidRunning(pid),
      samples,
      summary: summarizeSamples(samples),
      accessibility,
      mcpLatency,
    };
    writeJson(this.metricsPath, report);
    this.saveManifest({
      lastProfilePath: this.metricsPath,
      events: [{ at: nowIso(), type: "profile", profilePath: this.metricsPath, sampleCount: samples.length }],
    });
    return { ok: true, profilePath: this.metricsPath, report };
  }

  accessibilityProbe() {
    const script = `
tell application "System Events"
  set output to {}
  repeat with procName in {"RobloxStudio", "Roblox Studio"}
    if exists process procName then
      tell process procName
        set end of output to procName & "|frontmost=" & (frontmost as text) & "|windows=" & ((count of windows) as text)
      end tell
    end if
  end repeat
  return output as text
end tell
`;
    const result = runSync("osascript", ["-e", script]);
    return {
      ok: result.status === 0,
      durationMs: result.durationMs,
      stdout: result.stdout.trim(),
      stderr: result.stderr.trim(),
      note: result.status === 0 ? "Accessibility probe reached System Events." : "Accessibility permission/window visibility may be unavailable.",
    };
  }

  accessibilityWindowProbe() {
    const studioProcessExists = listProcesses().some((entry) =>
      entry.command.includes("/Contents/MacOS/RobloxStudio")
    );
    if (!studioProcessExists) {
      return {
        ok: true,
        skipped: "no RobloxStudio process",
        durationMs: 0,
        stdout: "",
        stderr: "",
      };
    }
    const script = `
tell application "System Events"
  set reportLines to {}
  repeat with procName in {"RobloxStudio", "Roblox Studio"}
    if exists process procName then
      tell process procName
        set end of reportLines to "process=" & procName
        repeat with w in windows
          set end of reportLines to "window=" & (name of w as text) & "|buttons=" & ((count of buttons of w) as text)
          repeat with b in buttons of w
            set buttonName to name of b
            if buttonName is missing value then set buttonName to "<missing>"
            set end of reportLines to "button=" & (buttonName as text)
          end repeat
        end repeat
      end tell
    end if
  end repeat
  return reportLines as text
end tell
`;
    const result = runSync("osascript", ["-e", script]);
    return {
      ok: result.status === 0,
      durationMs: result.durationMs,
      stdout: result.stdout.trim(),
      stderr: result.stderr.trim(),
    };
  }

  clickAccessibilityButton(label, windowName, buttonName) {
    const script = `
tell application "System Events"
  repeat with procName in {"RobloxStudio", "Roblox Studio"}
    if exists process procName then
      tell process procName
        set frontmost to true
        if exists window ${JSON.stringify(windowName)} then
          tell window ${JSON.stringify(windowName)}
            if exists button ${JSON.stringify(buttonName)} then
              click button ${JSON.stringify(buttonName)}
              return "clicked=" & ${JSON.stringify(windowName)} & ":" & ${JSON.stringify(buttonName)}
            end if
          end tell
        end if
      end tell
    end if
  end repeat
  return "missing"
end tell
`;
    const result = runSync("osascript", ["-e", script]);
    return {
      label,
      windowName,
      buttonName,
      ok: result.status === 0 && result.stdout.includes("clicked="),
      durationMs: result.durationMs,
      stdout: result.stdout.trim(),
      stderr: result.stderr.trim(),
    };
  }

  screenSizePoints() {
    const result = runSync("python3", ["-c", `
from AppKit import NSScreen
frame = NSScreen.mainScreen().frame()
print(f"{int(frame.size.width)} {int(frame.size.height)}")
`]);
    const [width, height] = result.stdout.trim().split(/\s+/).map(Number);
    if (!Number.isFinite(width) || !Number.isFinite(height)) {
      throw new Error(`could not read screen size: ${result.stderr}`);
    }
    return { width, height };
  }

  clickScreenFraction(label, xFraction, yFraction) {
    const screen = this.screenSizePoints();
    const x = Math.round(screen.width * xFraction);
    const y = Math.round(screen.height * yFraction);
    const result = runSync("python3", ["-c", `
import time
from Quartz import CGEventCreateMouseEvent, CGEventPost, kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp, kCGMouseButtonLeft, kCGHIDEventTap
x = ${x}
y = ${y}
for event_type in (kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp):
    event = CGEventCreateMouseEvent(None, event_type, (x, y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)
    time.sleep(0.08)
`]);
    return { label, x, y, screen, ok: result.status === 0, durationMs: result.durationMs, stderr: result.stderr };
  }

  closeStudio() {
    const manifest = this.manifest();
    const studio = manifest.processes?.studio;
    if (!studio?.pid || !studio.workerOwned) {
      return { ok: false, skipped: "No worker-owned Studio pid in manifest" };
    }
    const pid = studio.pid;
    const before = isPidRunning(pid);
    if (before) {
      spawnSync("kill", [`-${pid}`], { encoding: "utf8" });
      spawnSync("kill", [String(pid)], { encoding: "utf8" });
      waitForPidExit(pid, 30000);
      if (isPidRunning(pid)) {
        spawnSync("kill", ["-9", `-${pid}`], { encoding: "utf8" });
        spawnSync("kill", ["-9", String(pid)], { encoding: "utf8" });
        waitForPidExit(pid, 8000);
      }
    }
    const after = isPidRunning(pid);
    this.saveManifest({
      processes: { studio: { ...studio, closedAt: nowIso(), runningAfterClose: after } },
      events: [{ at: nowIso(), type: "close-studio", pid, before, after }],
    });
    return { ok: !after, pid, runningBefore: before, runningAfter: after };
  }

  closeRojo() {
    const manifest = this.manifest();
    const rojo = manifest.processes?.rojo;
    if (!rojo?.pid || !rojo.workerOwned) return { ok: false, skipped: "No worker-owned Rojo pid in manifest" };
    const before = isPidRunning(rojo.pid);
    if (before) {
      spawnSync("kill", [`-${rojo.pid}`], { encoding: "utf8" });
      spawnSync("kill", [String(rojo.pid)], { encoding: "utf8" });
      waitForPidExit(rojo.pid, 10000);
      if (isPidRunning(rojo.pid)) {
        spawnSync("kill", ["-9", `-${rojo.pid}`], { encoding: "utf8" });
        spawnSync("kill", ["-9", String(rojo.pid)], { encoding: "utf8" });
        waitForPidExit(rojo.pid, 3000);
      }
    }
    const after = isPidRunning(rojo.pid);
    this.saveManifest({
      processes: { rojo: { ...rojo, closedAt: nowIso(), runningAfterClose: after } },
      events: [{ at: nowIso(), type: "close-rojo", pid: rojo.pid, before, after }],
    });
    return { ok: !after, pid: rojo.pid, runningBefore: before, runningAfter: after };
  }

  sessionPlan() {
    const manifest = this.manifest();
    const placePath = this.options.place || manifest.placePath || path.join(this.workDir, "prototype-place.rbxl");
    const expectedPlace = this.options.expectedPlace || manifest.expectedPlace || path.basename(placePath);
    const captureOut = this.options.captureOut || path.join(this.workDir, "capture-batch");
    return {
      schema: "studio-controller-session-plan/v1",
      generatedAt: nowIso(),
      workDir: this.workDir,
      placePath,
      expectedPlace,
      rojoPort: this.options.rojoPort,
      isolateDesktop: this.options.isolateDesktop,
      startupPasses: this.options.startupPasses,
      startupPolicies: {
        dismissAutoRecovery: this.options.dismissStartupBlockers,
        connectWorkerOwnedRojo: this.options.connectRojo,
        dismissStaleRojo: this.options.dismissStaleRojo,
      },
      profileMs: this.options.profileMs,
      capture: this.options.skipCapture ? null : {
        outDir: captureOut,
        planPath: this.options.capturePlan,
        mode: this.options.capturePlan ? "plan" : "current-viewport",
      },
      cleanup: this.options.keepOpen ? "leave-worker-owned-processes-open" : "close-worker-owned-processes",
      steps: [
        "env",
        "build-place",
        "start-rojo",
        "start-studio",
        this.options.isolateDesktop ? "isolate-desktop" : null,
        "startup-blockers",
        "mcp-probe",
        "rojo-sync-probe",
        "profile",
        this.options.skipCapture ? null : "capture-batch",
        this.options.keepOpen ? null : "close-studio",
        this.options.keepOpen ? null : "close-rojo",
      ].filter(Boolean),
    };
  }

  captureBatch() {
    const manifest = this.manifest();
    const placePath = this.options.place || manifest.placePath || null;
    const expectedPlace = this.options.expectedPlace || manifest.expectedPlace || (placePath ? path.basename(placePath) : null);
    if (!expectedPlace) throw new Error("capture-batch requires expectedPlace from --expected-place, manifest, or place path");
    const outDir = this.options.captureOut || path.join(this.workDir, "capture-batch");
    const args = [
      "tools/studio_worker_capture_batch.mjs",
      "--expected-place", expectedPlace,
      "--out", outDir,
    ];
    if (this.options.capturePlan) {
      args.push("--plan", this.options.capturePlan);
    } else {
      args.push("--capture-current");
    }
    const result = runSync(process.execPath, args, { maxBuffer: 128 * 1024 * 1024 });
    let parsed = null;
    try {
      parsed = result.stdout ? JSON.parse(result.stdout) : null;
    } catch {
      parsed = null;
    }
    const report = {
      ok: result.status === 0 && parsed?.ok !== false,
      status: result.status,
      durationMs: result.durationMs,
      command: [process.execPath, ...args],
      parsed,
      stdout: parsed ? undefined : result.stdout,
      stderr: result.stderr,
      error: result.error,
    };
    this.saveManifest({
      lastCaptureBatch: report,
      events: [{ at: nowIso(), type: "capture-batch", ok: report.ok, outDir, reportPath: parsed?.reportPath || null }],
    });
    return report;
  }

  session() {
    mkdirp(this.workDir);
    const plan = this.sessionPlan();
    const steps = [];
    const reportPath = path.join(this.workDir, "session-report.json");

    if (this.options.dryRun) {
      const report = {
        schema: "studio-controller-session-report/v1",
        generatedAt: nowIso(),
        dryRun: true,
        plan,
        steps,
      };
      writeJson(reportPath, report);
      return { ok: true, dryRun: true, reportPath, plan };
    }

    const addStep = (name, fn) => {
      const startedAt = performance.now();
      try {
        const result = fn();
        steps.push({ name, ok: result?.ok !== false, durationMs: Math.round(performance.now() - startedAt), result });
        return result;
      } catch (err) {
        const result = { ok: false, error: err.message };
        steps.push({ name, ok: false, durationMs: Math.round(performance.now() - startedAt), result });
        throw err;
      }
    };

    let error = null;
    try {
      addStep("env", () => this.env());
      addStep("build-place", () => this.buildPlace());
      addStep("start-rojo", () => this.startRojo());
      addStep("start-studio", () => this.startStudio());
      const preIsolationWaitMs = this.options.isolateDesktop ? Math.min(this.options.waitMs, 3000) : this.options.waitMs;
      sleep(preIsolationWaitMs);
      if (this.options.isolateDesktop) {
        addStep("isolate-desktop", () => this.isolateStudioDesktop());
        sleep(Math.max(0, this.options.waitMs - preIsolationWaitMs));
      }
      addStep("startup-blockers", () => this.startupBlockers());
      addStep("mcp-probe", () => this.mcpProbe());
      addStep("rojo-sync-probe", () => this.rojoSyncProbe());
      addStep("profile", () => this.profile());
      if (!this.options.skipCapture) {
        addStep("capture-batch", () => this.captureBatch());
      }
    } catch (err) {
      error = err;
    } finally {
      if (!this.options.keepOpen) {
        try {
          addStep("close-studio", () => this.closeStudio());
        } catch {
          // The failing close step is already recorded by addStep.
        }
        try {
          addStep("close-rojo", () => this.closeRojo());
        } catch {
          // The failing close step is already recorded by addStep.
        }
      }
    }

    const report = {
      schema: "studio-controller-session-report/v1",
      generatedAt: nowIso(),
      dryRun: false,
      keepOpen: this.options.keepOpen,
      plan,
      ok: !error && steps.every((step) => step.ok !== false),
      error: error ? error.message : null,
      steps,
      manifestPath: this.manifestPath,
      profilePath: this.metricsPath,
    };
    writeJson(reportPath, report);
    if (error) {
      const wrapped = new Error(`session failed: ${error.message}`);
      wrapped.reportPath = reportPath;
      throw wrapped;
    }
    return { ok: report.ok, reportPath, manifestPath: this.manifestPath, steps: steps.map((step) => step.name) };
  }

  demo() {
    const steps = [];
    steps.push({ name: "env", result: this.env() });
    steps.push({ name: "build-place", result: this.buildPlace() });
    steps.push({ name: "start-rojo", result: this.startRojo() });
    steps.push({ name: "start-studio", result: this.startStudio() });
    const preIsolationWaitMs = this.options.isolateDesktop ? Math.min(this.options.waitMs, 3000) : this.options.waitMs;
    sleep(preIsolationWaitMs);
    if (this.options.isolateDesktop) {
      steps.push({ name: "isolate-desktop", result: this.isolateStudioDesktop() });
      sleep(Math.max(0, this.options.waitMs - preIsolationWaitMs));
    }
    steps.push({ name: "startup-blockers", result: this.startupBlockers() });
    steps.push({ name: "mcp-probe", result: this.mcpProbe() });
    steps.push({ name: "profile", result: this.profile() });
    if (!this.options.keepOpen) {
      steps.push({ name: "close-studio", result: this.closeStudio() });
      steps.push({ name: "close-rojo", result: this.closeRojo() });
    }
    const report = {
      schema: "studio-controller-demo-report/v1",
      generatedAt: nowIso(),
      keepOpen: this.options.keepOpen,
      steps,
      manifestPath: this.manifestPath,
      profilePath: this.metricsPath,
    };
    const reportPath = path.join(this.workDir, "demo-report.json");
    writeJson(reportPath, report);
    return { ok: true, reportPath, manifestPath: this.manifestPath, profilePath: this.metricsPath, steps: steps.map((step) => step.name) };
  }
}

function pickResource(entry) {
  return {
    pid: entry.pid,
    cpuPercent: entry.cpuPercent,
    memPercent: entry.memPercent,
    rssMb: Math.round(entry.rssKb / 102.4) / 10,
    command: entry.command.slice(0, 240),
  };
}

function summarizeSamples(samples) {
  const studio = samples.map((sample) => sample.studio).filter(Boolean);
  const maxRssMb = Math.max(0, ...studio.map((entry) => entry.rssMb));
  const avgCpu = studio.length
    ? Math.round((studio.reduce((sum, entry) => sum + entry.cpuPercent, 0) / studio.length) * 10) / 10
    : 0;
  return {
    sampleCount: samples.length,
    studioSamples: studio.length,
    maxStudioRssMb: maxRssMb,
    avgStudioCpuPercent: avgCpu,
    maxStudioMcpCount: Math.max(0, ...samples.map((sample) => sample.studioMcpCount || 0)),
  };
}

function mcpToolNames(result) {
  const tools = result.parsed?.tools || [];
  return Array.isArray(tools) ? tools.map((tool) => tool.name) : [];
}

function mcpText(result) {
  return (result.parsed?.content || [])
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n");
}

function parseStudioList(result) {
  const text = mcpText(result);
  if (!text) return [];
  try {
    const payload = JSON.parse(text);
    return Array.isArray(payload.studios) ? payload.studios.map(normalizeStudioTarget).filter(Boolean) : [];
  } catch {
    return [];
  }
}

function normalizeStudioTarget(studio) {
  if (!studio || typeof studio !== "object") return null;
  return {
    id: typeof studio.id === "string" ? studio.id : null,
    name: typeof studio.name === "string" ? studio.name : null,
    active: Boolean(studio.active),
  };
}

function summarizeStudioList(result, studios = parseStudioList(result)) {
  return {
    ok: result.ok,
    status: result.status,
    durationMs: result.durationMs,
    count: studios.length,
    studios,
    stderr: result.stderr,
    error: result.error,
    textSample: mcpText(result).slice(0, 1000),
  };
}

function summarizeMcpTools(result) {
  const names = mcpToolNames(result);
  return {
    ok: result.ok,
    status: result.status,
    durationMs: result.durationMs,
    count: names.length,
    names: names.slice(0, 80),
    stderr: result.stderr,
    error: result.error,
  };
}

function summarizeMcpCall(result) {
  return {
    ok: result.ok,
    status: result.status,
    durationMs: result.durationMs,
    stderr: result.stderr,
    error: result.error,
    text: mcpText(result).slice(0, 1000),
    skipped: result.skipped,
  };
}

function inferRojoSyncFailureReason({ observed, removed, writeError, cleanupError, diagnostics }) {
  if (writeError) return "sentinel_source_write_failed";
  if (cleanupError) return "sentinel_source_cleanup_failed";
  if (observed && !removed) return "sentinel_delete_did_not_sync";
  if (observed && removed) return null;
  if (diagnostics?.acceptanceRisk) return diagnostics.acceptanceRisk;
  return "studio_rojo_plugin_not_connected_to_worker_server";
}

function detectStartupBlockersFromText(text) {
  const normalized = text.replace(/\s+/g, " ").toLowerCase();
  const rojoPort = extractLocalhostPort(text);
  const blockers = [];
  if (
    normalized.includes("auto-recovered file was detected")
    || normalized.includes("auto recovered file was detected")
    || (
      (normalized.includes("auto-recovery") || normalized.includes("auto recovery"))
      && normalized.includes("open will open")
      && normalized.includes("ignore will continue")
      && normalized.includes("delete will confirm")
    )
  ) {
    blockers.push({
      kind: "auto_recovery",
      severity: "startup_blocker",
      safeDefaultAction: "ignore",
      evidence: "OCR text matched Auto-Recovery / auto-recovered file wording.",
    });
  }
  if (
    normalized.includes("would you like to connect")
    && (normalized.includes("serving at localhost") || normalized.includes("project"))
  ) {
    blockers.push({
      kind: "rojo_connect",
      severity: "sync_blocker",
      safeDefaultAction: "connect_when_worker_owned_rojo_port_matches_manifest",
      port: rojoPort,
      evidence: "OCR text matched Rojo project serving connection prompt.",
    });
  }
  return blockers;
}

function extractLocalhostPort(text) {
  const match = text.match(/localhost\s*:\s*(\d{2,5})/i);
  if (!match) return null;
  const port = Number(match[1]);
  return Number.isFinite(port) ? port : null;
}

function summarizeRunCode(result) {
  const text = mcpText(result);
  const marker = "STUDIO_CONTROLLER_PROTOTYPE_STATE ";
  const line = text.split(/\r?\n/).find((candidate) => candidate.includes(marker));
  let state = null;
  if (line) {
    try {
      state = JSON.parse(line.slice(line.indexOf(marker) + marker.length));
    } catch {
      state = null;
    }
  }
  return {
    ok: result.ok,
    status: result.status,
    durationMs: result.durationMs,
    state,
    stderr: result.stderr,
    error: result.error,
    text: state ? undefined : text.slice(0, 1000),
  };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const controller = new StudioControllerPrototype(args);
  const commandMap = {
    research: () => controller.research(),
    env: () => controller.env(),
    "build-place": () => controller.buildPlace(),
    "start-rojo": () => controller.startRojo(),
    "start-studio": () => controller.startStudio(),
    "select-studio": () => controller.selectStudioTarget(),
    "isolate-desktop": () => controller.isolateStudioDesktop(),
    "mcp-probe": () => controller.mcpProbe(),
    "rojo-port-diagnostics": () => controller.rojoPortDiagnostics(),
    "rojo-sync-probe": () => controller.rojoSyncProbe(),
    "startup-blockers": () => controller.startupBlockers(),
    profile: () => controller.profile(),
    "close-studio": () => controller.closeStudio(),
    "close-rojo": () => controller.closeRojo(),
    demo: () => controller.demo(),
    session: () => controller.session(),
  };
  const action = commandMap[args.command];
  if (!action) usage();
  const result = action();
  console.log(JSON.stringify(result, null, 2));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
