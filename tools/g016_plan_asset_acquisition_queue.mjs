#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const DEFAULT_ASSET_BRAIN = "/Users/abdulrehmanbhidya/abhidya-public-repos/RobloxAIDev/asset-brain/v1/indexes/merged-project-assets.ndjson";
const DEFAULT_GROAN_REGISTRY = "/Users/abdulrehmanbhidya/PycharmProjects/GroanTubeHero/ReplicatedStorage/Shared/WorldV2/AssetRegistry.lua";

function usage() {
  return `Usage:
  node tools/g016_plan_asset_acquisition_queue.mjs --current eggBreakers7.rbxl --out-json docs/G016/ASSET_ACQUISITION_QUEUE.json --out-md docs/G016/ASSET_ACQUISITION_QUEUE.md [options]

Options:
  --asset-brain <path>       merged-project-assets.ndjson path
  --groan-registry <path>    GroanTubeHero WorldV2 AssetRegistry.lua path
  --limit <n>                queue length (default 205)
`;
}

function parseArgs(argv) {
  const args = {
    assetBrain: DEFAULT_ASSET_BRAIN,
    groanRegistry: DEFAULT_GROAN_REGISTRY,
    limit: 205,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    const next = argv[index + 1];
    if (arg === "--current") {
      args.current = next;
      index += 1;
    } else if (arg === "--asset-brain") {
      args.assetBrain = next;
      index += 1;
    } else if (arg === "--groan-registry") {
      args.groanRegistry = next;
      index += 1;
    } else if (arg === "--out-json") {
      args.outJson = next;
      index += 1;
    } else if (arg === "--out-md") {
      args.outMd = next;
      index += 1;
    } else if (arg === "--limit") {
      args.limit = Number(next);
      index += 1;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }
  return args;
}

function requireFile(filePath, label) {
  if (!filePath || !fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    throw new Error(`${label} file does not exist: ${filePath || "(missing)"}`);
  }
}

function normalizeId(value) {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  if (!/^\d+$/.test(text)) return null;
  if (text === "0") return null;
  return text;
}

function currentReleaseIds(currentPlace) {
  const output = execFileSync("lune", [
    "run",
    "tools/g016_release_ready_inventory.luau",
    currentPlace,
  ], { encoding: "utf8" });
  const ids = new Set();
  for (const line of output.split(/\r?\n/)) {
    if (!line || line.startsWith("#") || line.startsWith("count=")) continue;
    const id = normalizeId(line.split("\t")[0]);
    if (id) ids.add(id);
  }
  return ids;
}

function looksNonGeometry(record) {
  const text = [
    record.name,
    record.slot,
    record.family,
    record.query,
    ...(record.statuses || []),
  ].filter(Boolean).join(" ").toLowerCase();
  return /\b(audio|sound|music|song|skybox|image|icon|ui|decal|texture|shirt|pants|plugin|script)\b/.test(text);
}

function scoreAssetBrain(record) {
  let score = 0;
  const statuses = new Set(record.statuses || []);
  if (record.hasScripts === false) score += 30;
  if (statuses.has("pump_readiness")) score += 25;
  if (statuses.has("family_inspection_queue")) score += 20;
  if ((record.sourceLayers || []).includes("project_asset_manifest")) score += 16;
  if (record.slot) score += 12;
  if (record.family) score += 8;
  if ((record.blockers || []).length === 0) score += 6;
  if ((record.risks || []).length > 0) score -= 3;
  return score;
}

function readAssetBrain(filePath) {
  const candidates = [];
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const [lineIndex, line] of lines.entries()) {
    if (!line.trim()) continue;
    let record;
    try {
      record = JSON.parse(line);
    } catch (error) {
      throw new Error(`${filePath}:${lineIndex + 1}: invalid JSON: ${error.message}`);
    }
    if (record.project !== "eggbreakers") continue;
    const id = normalizeId(record.assetId);
    if (!id) continue;
    const statuses = record.statuses || [];
    if (statuses.includes("dream_seed") || statuses.includes("rejected_visual_audit")) continue;
    if (record.hasScripts === true) continue;
    if (looksNonGeometry(record)) continue;
    candidates.push({
      asset_id: id,
      name: record.name || null,
      slot: record.slot || null,
      family: record.family || null,
      query: record.query || null,
      source: "RobloxAIDev asset-brain merged-project-assets",
      source_path: filePath,
      source_line: lineIndex + 1,
      statuses,
      has_scripts_claim: record.hasScripts ?? null,
      visual_verdict: record.visualVerdict || null,
      risks: record.risks || [],
      blockers: record.blockers || [],
      evidence: record.evidence || [],
      next_actions: record.nextActions || [],
      priority_score: scoreAssetBrain(record),
      acquisition_status: "queued_not_delivered",
      release_credit_status: "not_release_credit_until_geometry_audits_pass",
    });
  }
  return candidates;
}

function parseLuaTableBlock(text, tableName) {
  const marker = `${tableName} = {`;
  const start = text.indexOf(marker);
  if (start < 0) return "";
  let depth = 0;
  let blockStart = text.indexOf("{", start);
  for (let index = blockStart; index < text.length; index += 1) {
    const char = text[index];
    if (char === "{") depth += 1;
    if (char === "}") {
      depth -= 1;
      if (depth === 0) return text.slice(blockStart + 1, index);
    }
  }
  return "";
}

function readGroanRegistry(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const text = fs.readFileSync(filePath, "utf8");
  const candidates = [];

  const inspected = parseLuaTableBlock(text, "AssetRegistry.InspectedRoomAssets");
  const inspectedRecordPattern = /assetId\s*=\s*"(\d+)"[\s\S]*?slot\s*=\s*"([^"]+)"[\s\S]*?verdict\s*=\s*"([^"]+)"[\s\S]*?scriptCount\s*=\s*(\d+)[\s\S]*?basePartCount\s*=\s*(\d+)[\s\S]*?note\s*=\s*"([^"]*)"/g;
  for (const match of inspected.matchAll(inspectedRecordPattern)) {
    const [, id, slot, verdict, scriptCount, basePartCount, note] = match;
    if (Number(scriptCount) !== 0 || Number(basePartCount) <= 0) continue;
    candidates.push({
      asset_id: id,
      name: null,
      slot: `groantube.${slot}`,
      family: "cross_project_inspected_palette",
      query: null,
      source: "GroanTubeHero WorldV2 inspected registry",
      source_path: filePath,
      statuses: ["studio_inspection", "cross_project_candidate"],
      has_scripts_claim: false,
      visual_verdict: verdict,
      risks: verdict === "fix" ? ["requires placement/orientation fix before release"] : [],
      blockers: [],
      evidence: [note],
      next_actions: ["Acquire real model bytes through Studio/Open Cloud, then run the G016 clean and place gate audit."],
      priority_score: verdict === "pass" ? 95 : 82,
      acquisition_status: "queued_not_delivered",
      release_credit_status: "not_release_credit_until_geometry_audits_pass",
    });
  }

  const palette = parseLuaTableBlock(text, "AssetRegistry.PaletteCommitments");
  const paletteRecordPattern = /slot\s*=\s*"([^"]+)"[\s\S]*?assetId\s*=\s*"(\d+)"[\s\S]*?name\s*=\s*"([^"]+)"[\s\S]*?verdict\s*=\s*"([^"]+)"/g;
  for (const match of palette.matchAll(paletteRecordPattern)) {
    const [, slot, id, name, verdict] = match;
    candidates.push({
      asset_id: id,
      name,
      slot: `groantube.${slot}`,
      family: "cross_project_palette_commitment",
      query: null,
      source: "GroanTubeHero WorldV2 palette commitment",
      source_path: filePath,
      statuses: ["committed_palette", "cross_project_candidate"],
      has_scripts_claim: false,
      visual_verdict: verdict,
      risks: verdict === "fix" ? ["requires placement/orientation fix before release"] : [],
      blockers: ["publish permission and model delivery still required"],
      evidence: ["Palette commitment in GroanTubeHero AssetRegistry.lua"],
      next_actions: ["Acquire real model bytes through Studio/Open Cloud, then run the G016 clean and place gate audit."],
      priority_score: verdict === "pass" ? 90 : 78,
      acquisition_status: "queued_not_delivered",
      release_credit_status: "not_release_credit_until_geometry_audits_pass",
    });
  }

  return candidates;
}

function mergeCandidates(sources, currentIds) {
  const byId = new Map();
  for (const candidate of sources.flat()) {
    if (currentIds.has(candidate.asset_id)) continue;
    const existing = byId.get(candidate.asset_id);
    if (!existing || candidate.priority_score > existing.priority_score) {
      byId.set(candidate.asset_id, candidate);
    }
  }
  return [...byId.values()].sort((a, b) => {
    if (b.priority_score !== a.priority_score) return b.priority_score - a.priority_score;
    return Number(a.asset_id) - Number(b.asset_id);
  });
}

function ensureParent(filePath) {
  if (!filePath) return;
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function writeJson(filePath, payload) {
  ensureParent(filePath);
  fs.writeFileSync(filePath, `${JSON.stringify(payload, null, 2)}\n`);
}

function markdown(payload) {
  const lines = [
    "# G016 Asset Acquisition Queue",
    "",
    "Status: queue only, not release credit.",
    "",
    `Current persisted baseline: \`${payload.current_place}\``,
    `Current release-ready visible ids: ${payload.current_release_ready_count}`,
    `Release gate gap: ${payload.release_gap_to_500}`,
    `Queued primary candidates: ${payload.queue.length}`,
    `Alternate candidates after the primary queue: ${payload.alternates.length}`,
    "",
    "These IDs must be acquired as real Roblox model geometry through Studio/Open Cloud or another validated delivery lane, cleaned, saved into a new `.rbxl`, and rerun through `tools/g016_place_gate_audit.luau` before they count toward US14.",
    "",
    "| # | Asset ID | Name | Slot/Family | Source | Status |",
    "| ---: | --- | --- | --- | --- | --- |",
  ];
  payload.queue.forEach((item, index) => {
    const name = (item.name || "(unnamed)").replace(/\|/g, "/");
    const slot = (item.slot || item.family || "(unassigned)").replace(/\|/g, "/");
    lines.push(`| ${index + 1} | ${item.asset_id} | ${name} | ${slot} | ${item.source} | ${item.release_credit_status} |`);
  });
  lines.push("");
  lines.push("## Required Gate");
  lines.push("");
  lines.push("- Deliver/import model bytes for each queued ID.");
  lines.push("- Remove or quarantine scripts before release counting.");
  lines.push("- Ensure visible `BasePart` geometry exists under `ReplicatedStorage.ImportedAssetLibrary` or `Workspace.Map.ImportedAssets`.");
  lines.push("- Run `tools/g016_clean_place_candidate.luau` and `tools/g016_place_gate_audit.luau`.");
  lines.push("- Keep `finalG016Pass=false` until the persisted place reaches `gateReleaseReadyVisibleAssets>=500`, fresh all-category proof, and RBXL persistence proof.");
  return `${lines.join("\n")}\n`;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(usage());
    return;
  }
  if (!args.current) throw new Error("--current is required");
  if (!args.outJson && !args.outMd) throw new Error("at least one of --out-json or --out-md is required");
  requireFile(args.current, "current place");
  requireFile(args.assetBrain, "asset brain");
  const currentIds = currentReleaseIds(args.current);
  const candidates = mergeCandidates([
    readGroanRegistry(args.groanRegistry),
    readAssetBrain(args.assetBrain),
  ], currentIds);
  const queue = candidates.slice(0, args.limit);
  const alternates = candidates.slice(args.limit);
  const payload = {
    schema: "g016-asset-acquisition-queue/v1",
    generated_at: new Date().toISOString(),
    current_place: args.current,
    current_release_ready_count: currentIds.size,
    release_gap_to_500: Math.max(0, 500 - currentIds.size),
    requested_queue_limit: args.limit,
    source_files: {
      asset_brain: args.assetBrain,
      groan_registry: args.groanRegistry,
    },
    release_credit_policy: "Queue entries are not release credit until real visible model geometry is acquired, script-cleaned, persisted, and accepted by tools/g016_place_gate_audit.luau.",
    direct_delivery_probe: {
      endpoint: "https://assetdelivery.roblox.com/v1/asset/?id=70617428",
      result: "401 without credentials in this lane",
      implication: "Use authenticated Studio/Open Cloud delivery or another validated model source for queued ids.",
    },
    queue,
    alternates,
  };
  if (args.outJson) writeJson(args.outJson, payload);
  if (args.outMd) {
    ensureParent(args.outMd);
    fs.writeFileSync(args.outMd, markdown(payload));
  }
  console.log(`currentReleaseReady=${currentIds.size}`);
  console.log(`releaseGapTo500=${payload.release_gap_to_500}`);
  console.log(`queue=${queue.length}`);
  console.log(`alternates=${alternates.length}`);
  if (queue.length < payload.release_gap_to_500) {
    console.log("warning=queue shorter than release gap; curate more assets before claiming readiness");
  }
}

try {
  main();
} catch (error) {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
}
