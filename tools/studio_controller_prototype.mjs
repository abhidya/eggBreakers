#!/usr/bin/env node

// PROTOTYPE: throwaway host-side Studio controller.
// Question: can one worker own Studio lifecycle, MCP probing, Rojo serving,
// and profiling without agentic UI clicking?

import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_STUDIO = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio";
const DEFAULT_MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP";
const DEFAULT_WORK_DIR = path.join(REPO_ROOT, ".omx/studio-controller-prototype");
const DEFAULT_ROJO_PORT = 34879;

function usage() {
  console.error(`usage: node tools/studio_controller_prototype.mjs <command> [options]

Commands:
  research       Print researched controller options and source links
  env           Probe local Studio/Rojo/MCP availability
  build-place   Build a scratch .rbxl via rojo build
  start-rojo    Start a worker-owned rojo serve and write a manifest
  start-studio  Launch Studio for a place and write a manifest
  isolate-desktop
                Activate Studio and move it into a macOS full-screen Space
  mcp-probe     Probe built-in StudioMCP tools and connected Studio sessions
  startup-blockers
                OCR/AX probe for startup popups such as Auto-Recovery and Rojo connect
  profile       Sample accessibility, latency, CPU, and memory
  close-studio  Close only the worker-owned Studio pid from the manifest
  close-rojo    Close only the worker-owned Rojo pid from the manifest
  demo          Build place, start Rojo, launch Studio, probe/profile, close

Options:
  --work-dir <dir>          Prototype work dir (default: ${DEFAULT_WORK_DIR})
  --place <path>            Place file path for start-studio/profile
  --project <path>          Rojo project file (default: default.project.json)
  --rojo-port <port>        Rojo port (default: ${DEFAULT_ROJO_PORT})
  --keep-open               Demo leaves Studio/Rojo running
  --wait-ms <ms>            Wait after launch before MCP/profile (default: 12000)
  --profile-ms <ms>         Resource sample duration (default: 8000)
  --expected-place <name>   Expected Studio game.Name / place basename
  --screenshot <path>       Existing screenshot for startup-blocker OCR test
  --text-fixture <path>     Existing text fixture for startup-blocker classifier test
  --isolate-desktop         Demo moves Studio into a full-screen Space before screenshots
  --dismiss-startup-blockers
                            Click safe dismissal for detected Auto-Recovery
  --connect-rojo            Click Rojo connect prompt when detected
`);
  process.exit(2);
}

function parseArgs(argv) {
  const command = argv[0] || usage();
  const args = {
    command,
    workDir: DEFAULT_WORK_DIR,
    place: null,
    project: "default.project.json",
    rojoPort: DEFAULT_ROJO_PORT,
    keepOpen: false,
    waitMs: 12000,
    profileMs: 8000,
    expectedPlace: null,
    screenshot: null,
    textFixture: null,
    isolateDesktop: false,
    dismissStartupBlockers: false,
    connectRojo: false,
  };

  for (let index = 1; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--work-dir") args.workDir = path.resolve(argv[++index] || usage());
    else if (arg === "--place") args.place = path.resolve(argv[++index] || usage());
    else if (arg === "--project") args.project = argv[++index] || usage();
    else if (arg === "--rojo-port") args.rojoPort = Number(argv[++index] || usage());
    else if (arg === "--keep-open") args.keepOpen = true;
    else if (arg === "--wait-ms") args.waitMs = Number(argv[++index] || usage());
    else if (arg === "--profile-ms") args.profileMs = Number(argv[++index] || usage());
    else if (arg === "--expected-place") args.expectedPlace = argv[++index] || usage();
    else if (arg === "--screenshot") args.screenshot = path.resolve(argv[++index] || usage());
    else if (arg === "--text-fixture") args.textFixture = path.resolve(argv[++index] || usage());
    else if (arg === "--isolate-desktop") args.isolateDesktop = true;
    else if (arg === "--dismiss-startup-blockers") args.dismissStartupBlockers = true;
    else if (arg === "--connect-rojo") args.connectRojo = true;
    else if (arg === "--help" || arg === "-h") usage();
    else {
      console.error(`unknown option: ${arg}`);
      usage();
    }
  }
  if (!Number.isFinite(args.rojoPort) || args.rojoPort < 1) throw new Error("--rojo-port must be a positive number");
  return args;
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
  const result = spawnSync("ps", ["-p", String(pid), "-o", "pid="], { encoding: "utf8" });
  return result.status === 0;
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

class StudioControllerPrototype {
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

  callMcp(toolName, args = {}) {
    const start = performance.now();
    const result = spawnSync(process.execPath, ["tools/studio_mcp_call.js", toolName, JSON.stringify(args)], {
      cwd: REPO_ROOT,
      env: { ...process.env, STUDIO_MCP_COMMAND: this.mcpPath },
      encoding: "utf8",
      maxBuffer: 128 * 1024 * 1024,
    });
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

  mcpProbe() {
    const tools = this.callMcp("tools/list", {});
    const toolNames = mcpToolNames(tools);
    const listStudios = tools.ok && JSON.stringify(tools.parsed || {}).includes("list_roblox_studios")
      ? this.callMcp("list_roblox_studios", {})
      : { ok: false, skipped: "list_roblox_studios not present in selected MCP" };
    const expectedPlace = this.options.expectedPlace || this.manifest().expectedPlace || null;
    const code = `
local HttpService = game:GetService("HttpService")
print("STUDIO_CONTROLLER_PROTOTYPE_STATE " .. HttpService:JSONEncode({
  placeName = game.Name,
  placeId = game.PlaceId,
  jobId = game.JobId,
  expectedPlace = ${JSON.stringify(expectedPlace)},
  workspaceName = workspace.Name,
  time = os.time(),
}))
`;
    const luauTool = toolNames.includes("execute_luau") ? "execute_luau" : "run_code";
    const runCode = luauTool === "execute_luau"
      ? this.callMcp("execute_luau", { code, datamodel_type: "Edit" })
      : this.callMcp("run_code", { command: code });
    const probe = {
      schema: "studio-controller-mcp-probe/v1",
      generatedAt: nowIso(),
      selectedMcpPath: this.mcpPath,
      expectedPlace,
      tools: summarizeMcpTools(tools),
      listStudios,
      luauTool,
      runCode: summarizeRunCode(runCode),
      rawDurationsMs: {
        toolsList: tools.durationMs,
        listStudios: listStudios.durationMs,
        runCode: runCode.durationMs,
      },
    };
    this.saveManifest({
      lastMcpProbe: probe,
      events: [{ at: nowIso(), type: "mcp-probe", ok: tools.ok && runCode.ok, expectedPlace }],
    });
    return probe;
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
    mkdirp(this.workDir);
    const screenshotPath = this.options.screenshot || path.join(this.workDir, "startup-blockers-screen.png");
    let screenshot = { ok: false, path: null, reused: false };
    let ocr = { status: 0, durationMs: 0, stdout: "", stderr: "" };
    let activation = null;
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
        const ocrInputPath = path.join(this.workDir, `startup-blockers-ocr-input${path.extname(screenshotPath) || ".png"}`);
        fs.copyFileSync(screenshotPath, ocrInputPath);
        ocr = runSync("tesseract", [ocrInputPath, "stdout"]);
      } else {
        ocr = { status: 1, stdout: "", stderr: "missing screenshot" };
      }
    }
    const ocrText = ocr.stdout || "";
    const blockers = detectStartupBlockersFromText(ocrText);
    const ax = this.accessibilityWindowProbe();
    const actions = [];
    const expectedRojoPort = this.manifest().rojoPort || this.options.rojoPort;

    if (this.options.dismissStartupBlockers && blockers.some((blocker) => blocker.kind === "auto_recovery")) {
      this.activateStudio();
      sleep(150);
      actions.push(this.clickScreenFraction("auto_recovery_ignore", 0.552, 0.714));
      sleep(750);
    }
    const rojoConnect = blockers.find((blocker) => blocker.kind === "rojo_connect");
    if (this.options.connectRojo && rojoConnect) {
      if (rojoConnect.port === expectedRojoPort) {
        this.activateStudio();
        sleep(150);
        actions.push(this.clickScreenFraction("rojo_connect", 0.493, 0.987));
        sleep(750);
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

    const report = {
      schema: "studio-controller-startup-blockers/v1",
      generatedAt: nowIso(),
      activation,
      expectedRojoPort,
      screenshot,
      ocr: {
        ok: ocr.status === 0,
        durationMs: ocr.durationMs,
        textSample: ocrText.slice(0, 2000),
        stderr: ocr.stderr,
      },
      blockers,
      accessibility: ax,
      actions,
    };
    const reportPath = path.join(this.workDir, "startup-blockers.json");
    writeJson(reportPath, report);
    this.saveManifest({
      lastStartupBlockersPath: reportPath,
      events: [{ at: nowIso(), type: "startup-blockers", blockerKinds: blockers.map((blocker) => blocker.kind), reportPath }],
    });
    return { ok: true, reportPath, blockerKinds: blockers.map((blocker) => blocker.kind), report };
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
      const deadline = Date.now() + 12000;
      while (Date.now() < deadline && isPidRunning(pid)) sleep(500);
      if (isPidRunning(pid)) {
        spawnSync("kill", ["-9", `-${pid}`], { encoding: "utf8" });
        spawnSync("kill", ["-9", String(pid)], { encoding: "utf8" });
        sleep(500);
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
    }
    sleep(500);
    const after = isPidRunning(rojo.pid);
    this.saveManifest({
      processes: { rojo: { ...rojo, closedAt: nowIso(), runningAfterClose: after } },
      events: [{ at: nowIso(), type: "close-rojo", pid: rojo.pid, before, after }],
    });
    return { ok: !after, pid: rojo.pid, runningBefore: before, runningAfter: after };
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
  const text = (result.parsed?.content || [])
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n");
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
    "isolate-desktop": () => controller.isolateStudioDesktop(),
    "mcp-probe": () => controller.mcpProbe(),
    "startup-blockers": () => controller.startupBlockers(),
    profile: () => controller.profile(),
    "close-studio": () => controller.closeStudio(),
    "close-rojo": () => controller.closeRojo(),
    demo: () => controller.demo(),
  };
  const action = commandMap[args.command];
  if (!action) usage();
  const result = action();
  console.log(JSON.stringify(result, null, 2));
}

main();
