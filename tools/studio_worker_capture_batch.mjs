#!/usr/bin/env node

import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const DEFAULT_OUT_DIR = ".omx/studio-worker-captures";
const DEFAULT_TEMP_PREFIXES = [
  "StudioWorkerTemp_",
  "G016CleanSpot_",
  "G016Validation_",
  "Preview_",
];

function usage() {
  console.error(`usage: node tools/studio_worker_capture_batch.mjs [options]

Options:
  --expected-place <name>    Required active game.Name, for example eggBreakers7.rbxl
  --plan <path>              Capture plan JSON. If omitted, captures the current viewport once
  --out <dir>                Output directory (default: ${DEFAULT_OUT_DIR})
  --capture-current          Capture current viewport once without a plan
  --dry-run                  Validate plan and active Studio target, but do not capture
  --keep-camera              Do not restore the original camera after scripted captures

Plan schema:
  {
    "schema": "studio-worker-capture-plan/v1",
    "expectedPlace": "eggBreakers7.rbxl",
    "tempNamePrefixes": ["G016CleanSpot_"],
    "captures": [
      {
        "id": "nest-front-before",
        "camera": {
          "position": [0, 8, -24],
          "lookAt": [0, 4, 0],
          "fov": 70
        },
        "beforeLuau": "print('optional setup')",
        "afterLuau": "print('optional cleanup')",
        "settleMs": 500
      }
    ]
  }`);
  process.exit(2);
}

function parseArgs(argv) {
  const args = {
    expectedPlace: null,
    planPath: null,
    outDir: DEFAULT_OUT_DIR,
    captureCurrent: false,
    dryRun: false,
    keepCamera: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--expected-place") args.expectedPlace = argv[++index] || usage();
    else if (arg === "--plan") args.planPath = argv[++index] || usage();
    else if (arg === "--out") args.outDir = argv[++index] || usage();
    else if (arg === "--capture-current") args.captureCurrent = true;
    else if (arg === "--dry-run") args.dryRun = true;
    else if (arg === "--keep-camera") args.keepCamera = true;
    else if (arg === "--help" || arg === "-h") usage();
    else {
      console.error(`unknown option: ${arg}`);
      usage();
    }
  }

  if (!args.expectedPlace) {
    throw new Error("--expected-place is required so the wrapper cannot hit a stale Studio DataModel");
  }
  if (!args.planPath && !args.captureCurrent) {
    args.captureCurrent = true;
  }
  return args;
}

function readPlan(args) {
  if (!args.planPath) {
    return {
      schema: "studio-worker-capture-plan/v1",
      expectedPlace: args.expectedPlace,
      captures: [{ id: "current-viewport" }],
      tempNamePrefixes: DEFAULT_TEMP_PREFIXES,
    };
  }

  const plan = JSON.parse(fs.readFileSync(args.planPath, "utf8"));
  if (plan.schema !== "studio-worker-capture-plan/v1") {
    throw new Error(`unsupported plan schema: ${plan.schema || "(missing)"}`);
  }
  if (plan.expectedPlace && plan.expectedPlace !== args.expectedPlace) {
    throw new Error(`plan expectedPlace ${plan.expectedPlace} does not match --expected-place ${args.expectedPlace}`);
  }
  if (!Array.isArray(plan.captures) || plan.captures.length === 0) {
    throw new Error("plan must include at least one capture");
  }
  return {
    ...plan,
    expectedPlace: args.expectedPlace,
    tempNamePrefixes: Array.isArray(plan.tempNamePrefixes) && plan.tempNamePrefixes.length > 0
      ? plan.tempNamePrefixes
      : DEFAULT_TEMP_PREFIXES,
  };
}

function sleep(ms) {
  if (!ms || ms < 1) return;
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function safeName(value) {
  const text = String(value || "capture")
    .replace(/[^A-Za-z0-9_.-]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  return text.slice(0, 96) || "capture";
}

function studioCall(toolName, args, commandText) {
  let argsValue = JSON.stringify(args || {});
  let tempDir = null;
  if (toolName === "run_code" && commandText) {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "studio-worker-"));
    const commandPath = path.join(tempDir, "command.luau");
    fs.writeFileSync(commandPath, commandText);
    argsValue = `@${commandPath}`;
  }

  const result = spawnSync(process.execPath, ["tools/studio_mcp_call.js", toolName, argsValue], {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 96 * 1024 * 1024,
  });

  if (tempDir) fs.rmSync(tempDir, { recursive: true, force: true });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${toolName} failed with status ${result.status}\n${result.stderr}\n${result.stdout}`);
  }
  return JSON.parse(result.stdout);
}

function extractText(toolResult) {
  return (toolResult.content || [])
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n");
}

function extractMarkedJson(toolResult, marker) {
  const text = extractText(toolResult);
  const line = text.split(/\r?\n/).find((candidate) => candidate.includes(marker));
  if (!line) {
    throw new Error(`Studio output did not include ${marker}\n${text}`);
  }
  return JSON.parse(line.slice(line.indexOf(marker) + marker.length));
}

function listRobloxProcesses(expectedPlace) {
  const result = spawnSync("ps", ["axo", "pid=,ppid=,command="], {
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    return {
      error: result.error ? result.error.message : result.stderr.trim(),
      expectedPlaceProcessCount: 0,
      robloxStudioProcessCount: 0,
      studioMcpProcessCount: 0,
      robloxStudio: [],
    };
  }

  const robloxStudio = [];
  let studioMcpProcessCount = 0;
  for (const line of result.stdout.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const match = trimmed.match(/^(\d+)\s+(\d+)\s+(.+)$/);
    if (!match) continue;
    const [, pid, ppid, command] = match;
    if (command.includes("RobloxCrashHandler")) continue;
    if (command.includes("/Contents/MacOS/RobloxStudio")) {
      const localPlaceFile = command.match(/-localPlaceFile\s+(\S+)/)?.[1] || null;
      robloxStudio.push({
        pid: Number(pid),
        ppid: Number(ppid),
        localPlaceFile,
        basename: localPlaceFile ? path.basename(localPlaceFile) : null,
      });
    } else if (command.includes("/Contents/MacOS/StudioMCP")) {
      studioMcpProcessCount += 1;
    }
  }

  return {
    expectedPlaceProcessCount: robloxStudio.filter((entry) => entry.basename === expectedPlace).length,
    robloxStudioProcessCount: robloxStudio.length,
    studioMcpProcessCount,
    robloxStudio,
  };
}

function makeStateLuau(expectedPlace) {
  return `
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local function callBool(name)
	local ok, value = pcall(function()
		return RunService[name](RunService)
	end)
	if ok then return value end
	return nil
end
local camera = workspace.CurrentCamera
local payload = {
	schema = "studio-worker-state/v1",
	expectedPlace = ${JSON.stringify(expectedPlace)},
	placeName = game.Name,
	placeId = game.PlaceId,
	jobId = game.JobId,
	creatorId = game.CreatorId,
	workspaceName = workspace.Name,
	isEdit = callBool("IsEdit"),
	isRunning = callBool("IsRunning"),
	currentCameraExists = camera ~= nil,
	currentCameraCFrame = camera and tostring(camera.CFrame) or nil,
	currentCameraFov = camera and camera.FieldOfView or nil,
}
print("STUDIO_WORKER_STATE " .. HttpService:JSONEncode(payload))
`;
}

function makeCameraLuau(capture) {
  if (!capture.camera) return null;
  const position = vector(capture.camera.position, "camera.position");
  const lookAt = vector(capture.camera.lookAt, "camera.lookAt");
  const fov = capture.camera.fov == null ? 70 : Number(capture.camera.fov);
  if (!Number.isFinite(fov) || fov < 1 || fov > 120) {
    throw new Error(`capture ${capture.id} camera.fov must be between 1 and 120`);
  }

  return `
local camera = workspace.CurrentCamera
if not camera then
	camera = Instance.new("Camera")
	camera.Name = "StudioWorkerCamera"
	camera.Parent = workspace
	workspace.CurrentCamera = camera
end
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(
	Vector3.new(${position[0]}, ${position[1]}, ${position[2]}),
	Vector3.new(${lookAt[0]}, ${lookAt[1]}, ${lookAt[2]})
)
camera.FieldOfView = ${fov}
print("STUDIO_WORKER_CAMERA_SET " .. ${JSON.stringify(String(capture.id))})
`;
}

function vector(value, label) {
  if (!Array.isArray(value) || value.length !== 3) {
    throw new Error(`${label} must be a [x, y, z] array`);
  }
  return value.map((item) => {
    const number = Number(item);
    if (!Number.isFinite(number)) throw new Error(`${label} contains a non-number`);
    return number;
  });
}

function makeTempAuditLuau(prefixes) {
  return `
local HttpService = game:GetService("HttpService")
local prefixes = HttpService:JSONDecode([===[${JSON.stringify(prefixes)}]===])
local matches = {}
for _, instance in ipairs(workspace:GetDescendants()) do
	for _, prefix in ipairs(prefixes) do
		if string.sub(instance.Name, 1, #prefix) == prefix then
			table.insert(matches, {
				path = instance:GetFullName(),
				className = instance.ClassName,
				prefix = prefix,
			})
			break
		end
	end
end
print("STUDIO_WORKER_TEMP_AUDIT " .. HttpService:JSONEncode({
	schema = "studio-worker-temp-audit/v1",
	prefixes = prefixes,
	count = #matches,
	sample = { unpack(matches, 1, math.min(#matches, 25)) },
}))
`;
}

function runLuau(label, source) {
  if (!source) return null;
  const result = studioCall("run_code", {}, source);
  if (result.isError) {
    throw new Error(`${label} returned isError=true\n${extractText(result)}`);
  }
  return extractText(result);
}

function writeScreenshot(outDir, index, capture, toolResult) {
  const image = (toolResult.content || []).find((part) => part.type === "image" && part.data);
  if (!image) {
    throw new Error(`capture ${capture.id} did not return an image payload`);
  }
  const mimeType = image.mimeType || "image/jpeg";
  const ext = mimeType.includes("png") ? "png" : "jpg";
  const fileName = `${String(index + 1).padStart(3, "0")}_${safeName(capture.id)}.${ext}`;
  const filePath = path.resolve(outDir, fileName);
  const bytes = Buffer.from(image.data, "base64");
  fs.writeFileSync(filePath, bytes);
  return {
    id: capture.id,
    label: capture.label || null,
    file: filePath,
    mimeType,
    bytes: bytes.length,
    sha256: crypto.createHash("sha256").update(bytes).digest("hex"),
    camera: capture.camera || null,
  };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const plan = readPlan(args);
  const outDir = path.resolve(args.outDir);
  fs.mkdirSync(outDir, { recursive: true });

  const state = extractMarkedJson(studioCall("run_code", {}, makeStateLuau(args.expectedPlace)), "STUDIO_WORKER_STATE ");
  const processes = listRobloxProcesses(args.expectedPlace);
  if (state.placeName !== args.expectedPlace) {
    throw new Error(`wrong Studio target: MCP reached ${state.placeName}, expected ${args.expectedPlace}`);
  }

  const report = {
    schema: "studio-worker-capture-report/v1",
    generatedAt: new Date().toISOString(),
    expectedPlace: args.expectedPlace,
    dryRun: args.dryRun,
    planPath: args.planPath ? path.resolve(args.planPath) : null,
    outputDirectory: outDir,
    studioState: state,
    processSummary: processes,
    captures: [],
    tempAudit: null,
    notes: [
      "Screenshots are Studio viewport evidence only; release credit still requires save/reopen and gate audit.",
    ],
  };

  if (!args.dryRun) {
    for (const [index, capture] of plan.captures.entries()) {
      if (!capture.id) throw new Error(`capture at index ${index} is missing id`);
      runLuau(`${capture.id} beforeLuau`, capture.beforeLuau);
      runLuau(`${capture.id} camera`, makeCameraLuau(capture));
      sleep(Number(capture.settleMs || 250));
      const screenshot = studioCall("capture_screenshot", {});
      report.captures.push(writeScreenshot(outDir, index, capture, screenshot));
      runLuau(`${capture.id} afterLuau`, capture.afterLuau);
    }
    if (!args.keepCamera) {
      runLuau("restore camera", `
local camera = workspace.CurrentCamera
if camera then
	camera.CameraType = Enum.CameraType.Custom
end
print("STUDIO_WORKER_CAMERA_RESTORED")
`);
    }
  }

  report.tempAudit = extractMarkedJson(
    studioCall("run_code", {}, makeTempAuditLuau(plan.tempNamePrefixes || DEFAULT_TEMP_PREFIXES)),
    "STUDIO_WORKER_TEMP_AUDIT "
  );

  const reportPath = path.join(outDir, "capture-report.json");
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify({
    ok: true,
    dryRun: args.dryRun,
    expectedPlace: args.expectedPlace,
    captureCount: report.captures.length,
    tempArtifactCount: report.tempAudit.count,
    reportPath,
  }, null, 2));
}

main();
