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


## G020 import/materialization continuation B — 2026-05-30T01:20:53Z

Inserted, sanitized, tagged, and intentionally placed 6 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 8788719671 | G020_Imported_ClassicTree_02 | FernPlains | TreeBrowseVisual | 0 | non-mesh |
| 4536575513 | G020_Imported_FernBush_02 | NurseryGrove | HerbivoreFoodVisual | 0 | non-mesh |
| 267220625 | G020_Imported_JungleVine_02 | JungleBasin | JungleBrowseVisual | 0 | non-mesh |
| 751054565 | G020_Imported_SwampTree_02 | SwampDelta | SwampBrowseVisual | 0 | non-mesh |
| 8370969390 | G020_Imported_RockBoulder_02 | RedstoneCanyon | CanyonRockVisual | 1 removed | MeshPart detected; source policy will exclude until replacement/exception |
| 71324147289761 | G020_Imported_RuinedWall_02 | ApocalypticCity | CityRuinVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after this second batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 33 |
| Audited Imported Assets | 33 |
| Tagged Imported Assets | 33 |
| Placed Visible Assets | 33 |
| Release Ready Visible Assets | 33 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 467 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (`scanFailureCount=0`).

Release still fails honestly because the materialized live count is `33/500`.


## G021 import/materialization continuation — 2026-05-30T01:24:46Z

Inserted, sanitized, tagged, and intentionally placed 10 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 4536575513 | G021_Imported_FernPlant_01 | FernPlains | HerbivoreFoodVisual | 0 | non-mesh; duplicate SourceAssetId already present so unique count did not increase |
| 3198452967 | G021_Imported_BushPlant_01 | NurseryGrove | HerbivoreFoodVisual | 0 | non-mesh |
| 44380873 | G021_Imported_JunglePlant_01 | JungleBasin | JungleBrowseVisual | 0 | non-mesh |
| 1784440735 | G021_Imported_SwampReeds_01 | SwampDelta | SwampBrowseVisual | 0 | non-mesh |
| 75926765575812 | G021_Imported_TreeStump_01 | RedstoneCanyon | CanyonBrowseVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 107209332 | G021_Imported_RuinedWall_01 | ApocalypticCity | CityRuinVisual | 39 removed | non-mesh |
| 288799473 | G021_Imported_WreckedCar_01 | ApocalypticCity | CityCarWreckVisual | 5 removed | non-mesh |
| 7175045109 | G021_Imported_RockNature_01 | MountainNestingCliffs | MountainRockVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 2555886764 | G021_Imported_DinoFossil_01 | MountainNestingCliffs | FossilVisual | 0 | non-mesh |
| 24648974 | G021_Imported_NestEggs_01 | NurseryGrove | EggNestVisual | 0 | non-mesh |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after this batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 42 |
| Audited Imported Assets | 42 |
| Tagged Imported Assets | 42 |
| Placed Visible Assets | 42 |
| Release Ready Visible Assets | 42 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 458 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (`scanFailureCount=0`).

Verification: `luac -p` all Lua PASS; `git diff --check` PASS; `rojo build /tmp/eggBreakers-g021-import-batch.rbxl` PASS.

Release still fails honestly because materialized live count is `42/500` and final mobile/RBXL/fresh all-category proof remains missing.


## G022 import/materialization continuation — 2026-05-30T01:28:39Z

Inserted, sanitized, tagged, and intentionally placed 10 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 58306225 | G022_Imported_GrassClump_01 | FernPlains | HerbivoreFoodVisual | 0 | non-mesh |
| 44380873 | G022_Imported_TropicalPlant_01 | JungleBasin | JungleBrowseVisual | 0 | non-mesh; duplicate SourceAssetId already present so unique count did not increase |
| 16458140435 | G022_Imported_FallenLog_01 | JungleBasin | JungleLogVisual | 6 removed | non-mesh |
| 11239705094 | G022_Imported_CaveArch_01 | RedstoneCanyon | CanyonRockVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 11442829678 | G022_Imported_CityDebris_01 | ApocalypticCity | CityRubbleVisual | 0 | non-mesh |
| 9460880283 | G022_Imported_RoadSign_01 | ApocalypticCity | CitySignVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 2523657735 | G022_Imported_WaterLily_01 | SwampDelta | SwampBrowseVisual | 0 | non-mesh |
| 11530343070 | G022_Imported_NestStraw_01 | NurseryGrove | EggNestVisual | 0 | non-mesh |
| 2555886764 | G022_Imported_BoneFossil_01 | MountainNestingCliffs | FossilVisual | 0 | non-mesh; duplicate SourceAssetId already present so unique count did not increase |
| 40749106 | G022_Imported_DinoStatue_01 | ApocalypticCity | CityDinosaurLandmark | 114 removed | non-mesh |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after this batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 49 |
| Audited Imported Assets | 49 |
| Tagged Imported Assets | 49 |
| Placed Visible Assets | 49 |
| Release Ready Visible Assets | 49 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 451 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (`scanFailureCount=0`).

Verification: `luac -p` all Lua PASS; `git diff --check` PASS; `rojo build /tmp/eggBreakers-g022-import-batch.rbxl` PASS.

Release still fails honestly because materialized live count is `49/500` and final mobile/RBXL/fresh all-category proof remains missing.


## G023 import/materialization continuation — 2026-05-30T01:32:52Z

Inserted, sanitized, tagged, and intentionally placed 10 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 4997062124 | G023_Imported_MossRock_01 | JungleBasin | JungleRockVisual | 0 | non-mesh |
| 12111784707 | G023_Imported_DesertScrub_01 | RedstoneCanyon | CanyonBrowseVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 4536575513 | G023_Imported_FernPack_01 | NurseryGrove | HerbivoreFoodVisual | 0 | non-mesh; duplicate SourceAssetId already present so unique count did not increase |
| 13824437794 | G023_Imported_StoneRuins_01 | ApocalypticCity | CityRuinVisual | 0 | non-mesh |
| 3979000279 | G023_Imported_BrokenFence_01 | ApocalypticCity | CityFenceVisual | 4 removed | MeshPart detected; source policy will exclude until replacement/exception |
| 9164615040 | G023_Imported_SwampLog_01 | SwampDelta | SwampLogVisual | 0 | non-mesh |
| 54636442 | G023_Imported_BonesPile_01 | RedstoneCanyon | CanyonBonesVisual | 12 removed | non-mesh |
| 15715044528 | G023_Imported_BirdNest_01 | MountainNestingCliffs | NestVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 4511257322 | G023_Imported_OldCrateBarrel_01 | ApocalypticCity | CityLootPropVisual | 1 removed | non-mesh |
| 5529000803 | G023_Imported_WaterReeds_01 | SwampDelta | SwampBrowseVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after this batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 58 |
| Audited Imported Assets | 58 |
| Tagged Imported Assets | 58 |
| Placed Visible Assets | 58 |
| Release Ready Visible Assets | 58 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 442 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (`scanFailureCount=0`).

Verification: `luac -p` all Lua PASS; `git diff --check` PASS; `rojo build /tmp/eggBreakers-g023-import-batch.rbxl` PASS.

Release still fails honestly because materialized live count is `58/500` and final mobile/RBXL/fresh all-category proof remains missing.
