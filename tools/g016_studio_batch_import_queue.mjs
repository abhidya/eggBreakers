#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const DEFAULT_QUEUE = "docs/G016/ASSET_ACQUISITION_QUEUE.json";
const DEFAULT_EXPECTED_PLACE = "eggBreakers7.rbxl";
const DEFAULT_LIMIT = 5;

function usage() {
  console.error(`usage: node tools/g016_studio_batch_import_queue.mjs [options]

Options:
  --queue <path>             Queue JSON path (default: ${DEFAULT_QUEUE})
  --expected-place <name>    Refuse Studio sessions not matching this game.Name
                             (default: ${DEFAULT_EXPECTED_PLACE})
  --start <n>                1-based queue row to start from (default: 1)
  --limit <n>                Max queue rows to process (default: ${DEFAULT_LIMIT})
  --apply                    Import missing queued assets into Studio
  --dry-run                  Inventory only (default)
  --compile-only             Ask Studio loadstring to compile the generated
                             command and print the parse result, then exit

This tool drives StudioMCP run_code. It does not save the .rbxl file and never
claims release credit by itself. After an --apply run, the place must still be
saved/reopened and audited with tools/g016_place_gate_audit.luau.`);
  process.exit(2);
}

function parseArgs(argv) {
  const args = {
    queue: DEFAULT_QUEUE,
    expectedPlace: DEFAULT_EXPECTED_PLACE,
    start: 1,
    limit: DEFAULT_LIMIT,
    apply: false,
    compileOnly: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--queue") args.queue = argv[++index] || usage();
    else if (arg === "--expected-place") args.expectedPlace = argv[++index] || usage();
    else if (arg === "--start") args.start = Number(argv[++index] || usage());
    else if (arg === "--limit") args.limit = Number(argv[++index] || usage());
    else if (arg === "--apply") args.apply = true;
    else if (arg === "--dry-run") args.apply = false;
    else if (arg === "--compile-only") args.compileOnly = true;
    else if (arg === "--help" || arg === "-h") usage();
    else {
      console.error(`unknown option: ${arg}`);
      usage();
    }
  }

  if (!Number.isInteger(args.start) || args.start < 1) {
    throw new Error("--start must be a positive 1-based integer");
  }
  if (!Number.isInteger(args.limit) || args.limit < 1) {
    throw new Error("--limit must be a positive integer");
  }
  if (args.apply && args.limit > 25) {
    throw new Error("--apply is capped at --limit 25 so Studio imports stay reviewable");
  }
  return args;
}

function readQueue(queuePath, start, limit) {
  const queueDoc = JSON.parse(fs.readFileSync(queuePath, "utf8"));
  if (!Array.isArray(queueDoc.queue)) {
    throw new Error(`queue JSON missing queue array: ${queuePath}`);
  }
  return queueDoc.queue.slice(start - 1, start - 1 + limit).map((entry, offset) => ({
    queueIndex: start + offset,
    assetId: String(entry.asset_id),
    name: entry.name || "",
    slot: entry.slot || "",
    family: entry.family || "",
    source: entry.source || "",
  }));
}

function studioCall(toolName, args, commandText) {
  let argsValue = JSON.stringify(args || {});
  let tempDir = null;
  if (toolName === "run_code" && commandText) {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "g016-studio-import-"));
    const commandPath = path.join(tempDir, "command.luau");
    fs.writeFileSync(commandPath, commandText);
    argsValue = `@${commandPath}`;
  }

  const result = spawnSync(process.execPath, ["tools/studio_mcp_call.js", toolName, argsValue], {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 32 * 1024 * 1024,
  });

  if (tempDir) {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${toolName} failed with status ${result.status}\n${result.stderr}\n${result.stdout}`);
  }
  return JSON.parse(result.stdout);
}

function listRobloxProcesses() {
  const result = spawnSync("ps", ["axo", "pid=,ppid=,command="], {
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    return {
      error: result.error ? result.error.message : result.stderr.trim(),
      robloxStudio: [],
      studioMcp: [],
    };
  }

  const robloxStudio = [];
  const studioMcp = [];
  for (const line of result.stdout.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const match = trimmed.match(/^(\d+)\s+(\d+)\s+(.+)$/);
    if (!match) continue;
    const [, pid, ppid, command] = match;
    if (command.includes("RobloxCrashHandler")) continue;
    if (command.includes("/Contents/MacOS/RobloxStudio")) {
      const localPlaceFile = command.match(/-localPlaceFile\s+(\S+)/)?.[1] || null;
      const parentPid = command.match(/-parentPid\s+(\d+)/)?.[1] || null;
      robloxStudio.push({
        pid: Number(pid),
        ppid: Number(ppid),
        parentPid: parentPid ? Number(parentPid) : null,
        localPlaceFile,
        command,
      });
    } else if (command.includes("/Contents/MacOS/StudioMCP")) {
      studioMcp.push({
        pid: Number(pid),
        ppid: Number(ppid),
        command,
      });
    }
  }
  return { robloxStudio, studioMcp };
}

function attachTargetDiagnostics(result, expectedPlace) {
  const processes = listRobloxProcesses();
  const expectedByProcess = (processes.robloxStudio || []).filter((entry) =>
    entry.localPlaceFile && path.basename(entry.localPlaceFile) === expectedPlace
  );
  return {
    ...result,
    mcpTargetMatchesExpectedPlace: result.placeName === expectedPlace,
    localStudioProcessSummary: {
      expectedPlaceProcessCount: expectedByProcess.length,
      robloxStudioProcessCount: (processes.robloxStudio || []).length,
      studioMcpProcessCount: (processes.studioMcp || []).length,
    },
    localStudioProcesses: processes.robloxStudio || [],
    localStudioMcpProcesses: processes.studioMcp || [],
    localProcessProbeError: processes.error || null,
  };
}

function extractText(toolResult) {
  return (toolResult.content || [])
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n");
}

function parseStudioState(toolResult) {
  const text = extractText(toolResult).trim();
  return JSON.parse(text);
}

function jsonForLua(value) {
  return JSON.stringify(value).replace(/]]>/g, "]] .. '>' .. [[");
}

function makeLuau(records, expectedPlace, apply) {
  const recordsJson = jsonForLua(records);
  const expectedJson = JSON.stringify(expectedPlace);
  return `
local function phase(name)
	print("G016_STUDIO_BATCH_PHASE " .. tostring(name))
end

phase("start")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace

local EXPECTED_PLACE = ${expectedJson}
local APPLY = ${apply ? "true" : "false"}
local RECORDS_JSON = [===[${recordsJson}]===]

local function emit(payload)
	payload.schema = "g016-studio-batch-import/v1"
	payload.apply = APPLY
	payload.expectedPlace = EXPECTED_PLACE
	payload.placeName = game.Name
	payload.placeId = game.PlaceId
	print("G016_STUDIO_BATCH_IMPORT " .. HttpService:JSONEncode(payload))
end

phase("decode_records")
local RECORDS = HttpService:JSONDecode(RECORDS_JSON)

if game.Name ~= EXPECTED_PLACE then
	emit({ ok = false, error = "wrong_place" })
	return
end

phase("ensure_roots")
local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local library = APPLY and ensureFolder(ReplicatedStorage, "ImportedAssetLibrary") or ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
local map = APPLY and ensureFolder(Workspace, "Map") or Workspace:FindFirstChild("Map")
local workspaceImported = nil
if map then
	workspaceImported = APPLY and ensureFolder(map, "ImportedAssets") or map:FindFirstChild("ImportedAssets")
end

local function meaningfulSourceId(value)
	if value == nil then return nil end
	local text = tostring(value)
	if text == "" or text == "0" or text == "-1" then return nil end
	return text
end

local function scanExisting()
	local existing = {}
	local function scan(root)
		if not root then return end
		local source = meaningfulSourceId(root:GetAttribute("SourceAssetId"))
		if source then existing[source] = true end
		for _, descendant in ipairs(root:GetDescendants()) do
			source = meaningfulSourceId(descendant:GetAttribute("SourceAssetId"))
			if source then existing[source] = true end
		end
	end
	scan(library)
	scan(workspaceImported)
	return existing
end

local function visiblePartCount(instance)
	local count = 0
	if instance:IsA("BasePart") and instance.Transparency < 1 then
		count += 1
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			count += 1
		end
	end
	return count
end

local function scriptCount(instance)
	local count = 0
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			count += 1
		end
	end
	return count
end

local function stripScripts(instance)
	local removed = 0
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
			removed += 1
		end
	end
	return removed
end

local function normalizeParts(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanQuery = true
			descendant.CanTouch = false
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanQuery = true
		instance.CanTouch = false
	end
end

local function safeName(value)
	local text = tostring(value or "")
	text = string.gsub(text, "[^%w_%-]+", "_")
	text = string.gsub(text, "_+", "_")
	text = string.sub(text, 1, 48)
	if text == "" then return "QueuedAsset" end
	return text
end

local function collapseObjects(objects)
	local hasPhysical = false
	for _, object in ipairs(objects) do
		if object:IsA("PVInstance") then
			hasPhysical = true
			break
		end
	end
	if hasPhysical then
		local model = Instance.new("Model")
		for _, object in ipairs(objects) do
			object.Parent = model
		end
		return model
	end
	if #objects > 1 then
		local folder = Instance.new("Folder")
		for _, object in ipairs(objects) do
			object.Parent = folder
		end
		return folder
	end
	return objects[1]
end

local function loadAsset(assetId)
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(assetId))
	end)
	if not ok then
		return nil, tostring(objects)
	end
	if not objects or #objects == 0 then
		return nil, "game:GetObjects returned no instances"
	end
	return collapseObjects(objects), nil
end

local function runAudit()
	local ServerScriptService = game:FindFirstChild("ServerScriptService")
	if not ServerScriptService then return nil, "missing ServerScriptService" end
	local services = ServerScriptService:FindFirstChild("Services")
	local module = services and services:FindFirstChild("AssetImportAuditService")
	if not module then return nil, "missing AssetImportAuditService" end
	local ok, result = pcall(function()
		return require(module):AuditAndRepair({ mutate = true })
	end)
	if not ok then return nil, tostring(result) end
	return result, nil
end

phase("scan_existing")
local existing = scanExisting()
local imported = {}
local skipped = {}
local failed = {}
local beforeCount = 0
for _ in pairs(existing) do beforeCount += 1 end

phase("process_records")
for _, record in ipairs(RECORDS) do
	local assetId = tostring(record.assetId)
	if existing[assetId] then
		table.insert(skipped, { queueIndex = record.queueIndex, assetId = assetId, reason = "already_present" })
	elseif not APPLY then
		table.insert(skipped, { queueIndex = record.queueIndex, assetId = assetId, reason = "dry_run_missing" })
	else
		local instance, err = loadAsset(assetId)
		if not instance then
			table.insert(failed, { queueIndex = record.queueIndex, assetId = assetId, reason = err })
		else
			instance.Name = "G016Queue_" .. string.format("%03d", tonumber(record.queueIndex) or 0) .. "_" .. safeName(record.name ~= "" and record.name or record.slot) .. "_" .. assetId
			local removedScripts = stripScripts(instance)
			normalizeParts(instance)
			instance:SetAttribute("SourceAssetId", assetId)
			instance:SetAttribute("AssetManifestId", "G016Queue_" .. assetId)
			instance:SetAttribute("CreatorStoreOnly", true)
			instance:SetAttribute("ScriptsAudited", true)
			instance:SetAttribute("G016QueueImported", true)
			instance:SetAttribute("G016QueueIndex", record.queueIndex)
			instance:SetAttribute("G016QueueSlot", record.slot)
			instance:SetAttribute("G016QueueFamily", record.family)
			instance:SetAttribute("G016QueueSource", record.source)
			instance:SetAttribute("G016ImportedAt", os.date("!%Y-%m-%dT%H:%M:%SZ"))
			instance:SetAttribute("WorldAssetVerificationStatus", "imported_geometry_needs_clean_spot_screenshots")
			instance:SetAttribute("ReleaseCreditPolicy", "requires save/reopen plus g016_place_gate_audit; screenshot signoff remains required")
			instance.Parent = library
			local visible = visiblePartCount(instance)
			instance:SetAttribute("ImportedVisibleAsset", visible > 0)
			if visible == 0 then
				instance:SetAttribute("ReleaseReadyBlockedReason", "no-visible-basepart")
			end
			existing[assetId] = true
			table.insert(imported, {
				queueIndex = record.queueIndex,
				assetId = assetId,
				name = instance.Name,
				className = instance.ClassName,
				visiblePartCount = visible,
				scriptsRemoved = removedScripts,
				remainingScripts = scriptCount(instance),
			})
		end
	end
end

local audit = nil
local auditError = nil
if APPLY then
	audit, auditError = runAudit()
end
local afterExisting = scanExisting()
local afterCount = 0
for _ in pairs(afterExisting) do afterCount += 1 end

phase("emit_result")
emit({
	ok = true,
	beforeUniqueSourceIds = beforeCount,
	afterUniqueSourceIds = afterCount,
	selectedCount = #RECORDS,
	importedCount = #imported,
	skippedCount = #skipped,
	failedCount = #failed,
	imported = imported,
	skipped = skipped,
	failed = failed,
	auditCounts = audit and audit.counts or nil,
	auditPassed = audit and audit.passed or false,
	auditFailures = audit and audit.failures or nil,
	auditError = auditError,
})
`;
}

function makeCompileOnlyLuau(command) {
  return `
local source = ${JSON.stringify(command)}
local chunk, err = loadstring(source)
print("G016_STUDIO_BATCH_COMPILE ok=" .. tostring(chunk ~= nil) .. " err=" .. tostring(err))
`;
}

function extractBatchPayload(toolResult) {
  const text = extractText(toolResult);
  const marker = "G016_STUDIO_BATCH_IMPORT ";
  const line = text.split(/\r?\n/).find((candidate) => candidate.includes(marker));
  if (!line) {
    throw new Error(`Studio output did not include ${marker}\n${text}`);
  }
  return JSON.parse(line.slice(line.indexOf(marker) + marker.length));
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const records = readQueue(args.queue, args.start, args.limit);
  const state = parseStudioState(studioCall("get_studio_state", {}));
  if (!state.canModify || !state.isEdit) {
    throw new Error(`Studio is not in editable mode: ${JSON.stringify(state)}`);
  }

  const command = makeLuau(records, args.expectedPlace, args.apply);
  if (args.compileOnly) {
    const compileResult = studioCall("run_code", {}, makeCompileOnlyLuau(command));
    console.log(extractText(compileResult));
    return;
  }
  const result = extractBatchPayload(studioCall("run_code", {}, command));
  console.log(JSON.stringify(attachTargetDiagnostics(result, args.expectedPlace), null, 2));
}

main();
