# AI Agent Cowork Review - 2026-06-06

## Current Repository State

- `main` now includes `codex/asset-brain-pump-20260605` at `83e22d3`.
- The asset-brain pump branch added the current inventory, dream queue, family
  inspection queue, player-view screenshot evidence, live inventory tools, and
  story asset placement cleanup.
- `codex/story-swarm-wave` is still unmerged. It is one local commit ahead of
  `origin/codex/story-swarm-wave`, non-linear with `main`, and conflicts with
  current `main` in code, docs, and `eggBreakers3.rbxl`.

## Cowork Pain Points Found

1. Asset orientation needs a family gate, not a one-off clone fix.
   Sideways ferns and face-down dinos must be grouped by source family, fixed
   canonically, propagated to every live visual clone, and recaptured from
   player height.

2. Screenshot work was too manual.
   The previous process required an agent to decide each camera and capture call
   interactively, which made it easy to miss before/after views or live
   placement proof.

3. Studio MCP active-place and persistence checks are brittle.
   Prior logs show save/reopen and play-session proof can fail when the Studio
   MCP is disconnected, in the wrong place, or operating on a local `PlaceId=0`
   file without save-as/reopen support.

4. Search MCP and Studio MCP responsibilities blurred.
   Search/curation should stay in asset-search MCP; Studio should only consume
   selected IDs or plans and return import, measurement, screenshot, or play
   proof.

5. Asset-brain handoffs can churn heavily.
   `codex/story-swarm-wave` would delete a large number of asset-brain JSON and
   NDJSON shards if merged carelessly. Treat asset-brain deletes as review
   events, not background noise.

6. Validator reports need stronger shape checks.
   Findings with blank title/description and reports missing preflight,
   route-camera, or screenshot evidence should fail before any signoff wording.

## MCP And Skill Fixes Applied

RobloxAIDev now has an executable world asset-family proof path:

- `plan_world_asset_family_sweep` emits active-place preflight, deterministic
  camera steps, clean/live screenshot contracts, collation paths, and a report
  template.
- `validate_world_asset_family_sweep` now also fails when the generated plan
  requires active-place preflight and the report lacks it, or when a finding is
  blank.
- `asset-search-mcp/scripts/run-studio-world-asset-family-sweep.mjs` consumes a
  family sweep plan through mock or `studio_mcp_stdio` transport and writes one
  collated report, manifest, alt-text index, and execution log.
- The visual-gate prompt lane now tells agents to use the family sweep adapter
  when available instead of issuing ad hoc screenshot calls.
- The local `roblox-asset-inspection-lab` and `roblox-playable-space-review`
  skills were updated to require family sweeps before asset/world signoff.

Useful command shape:

```bash
node asset-search-mcp/scripts/run-studio-world-asset-family-sweep.mjs \
  --plan family-sweep-plan.json \
  --active-place eggBreakers3.rbxl \
  --json
```

## EggBreakers Asset-Family Queue

Start with the existing queue in
`asset-brain/v1/queues/eggbreakers-family-inspection-queue.json`:

- `Q001` `fern_food_and_ground_cover`: reported ferns on their side. First
  candidate: `7979002756` Fern Bush.
- `Q002` / `Q003`: fallback fern/plant pack candidates if Q001 fails scale,
  orientation, or readability.
- `Q004` `staged_and_imported_dinosaurs`: reported dinos face down. First pack
  candidate: `18759347676` Rigged Dinosaur Models.
- `Q005`: scripted raptor candidate; quarantine scripts before visual use.
- `Q006`: hatchling candidate for small readable body orientation.

Do not promote any family into a release palette until it has clean front/back/
left/right/overhead/player-height before and after screenshots, one live
in-world player-height after screenshot, canonical up/forward/scale/grounding/
pivot metadata, propagated live clone counts, `record_inspection` refs, and temp
clone cleanup proof.

## Story Branch Merge Status

`codex/story-swarm-wave` should not be merged straight into `main` yet.

Known conflicts against current `main`:

- `eggBreakers3.rbxl` binary conflict.
- `docs/AssetSourcing.md`.
- `src/ServerScriptService/Services/FishService.lua`.
- `src/ServerScriptService/Services/MapLayoutService.lua`.
- `src/ServerScriptService/Tests/Placement/FoodWaterPlacementValidation.lua`.
- `src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua`.

Safe integration path:

1. Create a checkpoint branch from `codex/story-swarm-wave`.
2. Merge current `main` into that checkpoint branch.
3. Remove accidental `.DS_Store` and review the large asset-brain deletion set
   before accepting any delete.
4. Resolve the conflict files with priority to the current asset-family queue,
   food template caching, and live inventory tools now on `main`.
5. Run focused source/test validation for changed services and placement tests.
6. Only then merge the checkpoint into `main`.

## Verification Already Run

RobloxAIDev:

- `npm --prefix asset-search-mcp test`
- `node scripts/run_ai_game_dev_pocs.mjs`

EggBreakers:

- `codex/asset-brain-pump-20260605` was fast-forwarded into `main`.
- `main` was pushed to `origin/main` at `83e22d3`.
