# G014 RBXL Place Audit

- Open in Studio: PASS (`eggBreakers` instance detected by MCP).
- MCP Luau execution: PASS.
- Bootstrap remotes: PASS after `Bootstrap.Init()`.
- Fresh spawn/hatch: PASS in current open Studio after imported visual organization.
- Imported asset audit: FAIL for release; 23/500 live imported/release-ready assets after quality quarantine.
- Full TestRunner in fresh Play: BLOCKED by MCP Play VM visibility of `ServerScriptService.Tests`.
- `.rbxl` persistence: NEEDS VERIFICATION after saving/reopening the current Studio asset organization.


## G015 Follow-up Evidence — 2026-05-27

Current G014 continuation evidence supersedes stale G015-only counts: active `eggBreakers2.rbxl` now audits at 23/500 release-ready visible assets after quality quarantine with a 477 gap, not release PASS. Fresh edit-mode all-category TestRunner was previously 146 total, 129 passed, 17 failed; a newer fresh full reload/all-category TestRunner remains required. Mobile/controller proof and `.rbxl` save/reopen persistence remain BLOCKED. G014 remains honest FAIL.


## Source-only asset/map quality patch — 2026-05-30

- `AssetImportAuditService.lua` now quarantines non-required low-quality/mesh imported roots during mutate audits and reports `qualityAssetsQuarantined` separately.
- `MapLayoutService.lua` now uses exact half-scale source compaction, re-centers mismatched food/carcass placements into their declared zones, keeps procedural food/tree visuals hidden, and tags NPC spawns as potential food when defeated.
- No client UI or combat files were changed in this patch. Live G014 release count remains an honest 23/500 until Studio is synced and rerun.


## Continuation live Studio TestRunner — 2026-05-30T01:13:33Z

Active Studio: `eggBreakers2.rbxl` (`23b8836a-ed22-4397-9a96-75b0a4a96eed`).

OMX team runtime attempt remained blocked in this non-tmux pane (`Team mode requires running inside tmux current leader pane`), so native parallel worker lanes and direct MCP/source verification continued under the same tracked scope.

Fresh live TestRunner before runtime cleanup: `220 total / 180 passed / 40 failed`.

Runtime cleanup + source-aligned hot patch applied in Studio:
- removed 104 stale Workspace test fixtures/default Parts that were polluting release sweeps;
- normalized 47 procedural food/tree helpers as invisible gameplay query helpers;
- restored live MovementModes/CreatureCategory defaults for stale Studio SpeciesConfig cache;
- patched live asset audit helper rules to ignore Studio-only fixtures and accept hidden procedural query helpers.

Fresh live TestRunner after cleanup: `220 total / 185 passed / 35 failed`.

Remaining live failures are still real release blockers:
- 500 unique release-ready Creator Store materialized imports not met (`23/500`, gap `477`);
- mobile/touch proof and RBXL save/reopen proof missing;
- G016/G018 proof attributes missing because final all-category run is not green;
- stale open Studio cache still has source mismatches for several NPC/carnotaurus/food placement checks until a clean source sync/reopen is performed;
- client category remains `0` in server-side TestRunner coverage, so client proof must be run through the client test path.
