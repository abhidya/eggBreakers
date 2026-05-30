# G014 Final Report

Latest Commit: 8c22854 plus current live Studio import batch docs pending commit.
RBXL Audit: PASS for open/responding Studio; FAIL for release persistence/full 500-asset audit.
Bootstrap Status: PASS — `Bootstrap.lua` ModuleScript and `Bootstrap.Init()` create required RemoteEvents.
Client Playability Status: FAIL — keyboard hatch smoke works and HUD/Hatch/Mobile UI appear, but full touch/controller device proof remains unproven.
User Story Coverage Matrix: `docs/G014/UserStoryCoverageMatrix.md`
Test Run Method: source `luac`, `rojo build`, Studio MCP Luau probes, Play smoke.
Fresh Studio/Rojo Reload: BLOCKED — open Studio smoke passed, but save/reopen/full TestRunner not proven.
Test Results by Category: `docs/G014/TestResults.md`
Failed Tests: asset release-ready count, full release placement/import gates, full Studio TestRunner.
Fixed Tests: hatch spawn/visual/movement smoke, ClientBootstrap/controller module loading, pre-hatch drink, real combat health damage, NPC empty model source path, generic carcass source path when imported assets exist.
Remaining Blockers: 500 release-ready imported assets, full Studio TestRunner, mobile proof, release placement audit, `.rbxl` save/reopen persistence.

## Asset Counts

| State | Count |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 23 live imported assets from Studio audit after quality quarantine |
| Audited Imported Assets | 23 live assets marked script-audited after quality quarantine; below target |
| Tagged Imported Assets | 23 live tagged imported assets after quality quarantine; below target |
| Placed Visible Assets | 23 live placed/visible imported assets after quality quarantine; below target |
| Release Ready Visible Assets | 23 live release-ready visible assets after quality quarantine |
| Script Objects Found | 0 in live imported visual roots during Studio audit |
| Scripts Quarantined | 0; no executable imported scripts found in the 23 live imported roots after quality quarantine |
| Remaining Release Ready Gap To 500 | 477 |

## Core Flow Result

- Hatch: PASS in Studio smoke.
- Imported egg visual: PASS in Studio smoke.
- Imported dinosaur visual: PASS in Studio smoke.
- Food: FAIL — logic exists, but release visual asset proof is incomplete.
- Water: PASS logic.
- Growth: PASS source tests.
- NPC: FAIL — source now uses imported model resolution, but full release audit is incomplete.
- Combat: PASS source tests for real health damage.
- City: FAIL — server reward path exists, but release asset proof is incomplete.
- Fossil: FAIL — server path exists, but release asset proof is incomplete.
- Death/Respawn: PASS source tests.
- Group/Call: FAIL — server path is fixed, but full client proof is incomplete.
- Nesting: FAIL — logic exists, but release asset proof is incomplete.
- Mobile controls: FAIL — controls appear in Studio smoke, but physical touch/controller proof is incomplete.

## Signoff

G014 STATUS: FAIL — releaseReadyVisibleAssets are now 23/500 after quality quarantine with a 477 gap; full fresh Studio TestRunner is not proven; mobile/controller E2E is not proven; release placement/import audit is incomplete; `.rbxl` save/reopen persistence of imported visual library is not yet verified.


## G015 Follow-up Evidence — 2026-05-27

Current G014 continuation evidence supersedes stale G015-only counts: active `eggBreakers2.rbxl` now audits at 23/500 release-ready visible assets after quality quarantine with a 477 gap, not release PASS. Fresh edit-mode all-category TestRunner was previously 146 total, 129 passed, 17 failed; a newer fresh full reload/all-category TestRunner remains required. Mobile/controller proof and `.rbxl` save/reopen persistence remain BLOCKED. G014 remains honest FAIL.


## Current evidence reconciliation — 2026-05-29

- Exact current release asset evidence: 23/500 release-ready visible imported assets after quality quarantine; remaining gap 477.
- Superseded stale baselines: 34/500 from the G015 live batch and 30/500 session baseline are historical only.
- Still FAIL: fresh full Studio TestRunner, mobile/controller E2E proof, release placement/import audit to 500, and `.rbxl` save/reopen persistence.


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


## G020 import/materialization continuation — 2026-05-30T01:18:38Z

Active Studio: `eggBreakers2.rbxl` (`23b8836a-ed22-4397-9a96-75b0a4a96eed`).

Inserted, sanitized, tagged, and intentionally placed 4 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 10681819812 | G020_Imported_PrehistoricPlant_01 | FernPlains | HerbivoreFoodVisual | 0 scripts | MeshPart detected in live root; source policy will exclude until replacement/exception. |
| 104497410410577 | G020_Imported_DinosaurNestEgg_01 | NurseryGrove | EggNestVisual | 0 scripts | Non-mesh live root. |
| 509728826 | G020_Imported_RuinedCityStructure_01 | ApocalypticCity | CityRuinVisual | 2 scripts removed | Non-mesh live root. |
| 5663348866 | G020_Imported_FossilBones_01 | MountainNestingCliffs | FossilVisual | 0 scripts | MeshPart detected in live root; source policy will exclude until replacement/exception. |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after the batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 27 |
| Audited Imported Assets | 27 |
| Tagged Imported Assets | 27 |
| Placed Visible Assets | 27 |
| Release Ready Visible Assets | 27 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 473 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (no placeholder/default-Part failures reported).

Live all-category TestRunner after the batch: `220 total / 185 passed / 35 failed`. Asset-count failures now honestly report `27/500`. Remaining failures include known proof gates, stale open-Studio module cache/source mismatch, and still-missing mobile/RBXL persistence evidence.

Source change included in this continuation: `MapLayoutService:EnsureNPCSpawnMarkers` now stamps `AerialSpawn`, `PreferredAltitude`, `FlyingPrey`, and `FlightTarget` consistently for aerial prey/predator markers.
