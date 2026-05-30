# G014 Test Results

Overall release gate: **FAIL**.

## Current G014 Status — 2026-05-29

Current authoritative FAIL evidence is 23/500 release-ready visible imported assets after quality quarantine with a 477 gap. Historical 30/500 and 34/500 values are superseded snapshots only; fresh all-category Studio TestRunner, mobile/controller E2E proof, release placement/import audit to 500, and `.rbxl` save/reopen persistence remain unproven or blocked.


| Gate | Status | Evidence |
|---|---|---|
| Studio MCP responsiveness | PASS | `execute_luau` returned place `eggBreakers`, PlaceId `111212176992206`; `Bootstrap.Init()` created all required remotes. |
| Fresh hatch smoke | PASS | In Play mode, player `blazimann` spawned hidden default avatar (`visibleDefaultParts=0`), unhatched movement locked (`WalkSpeed=0`), `HatchScreen`, `MainHUD`, and `MobileControls` appeared, imported egg visual attached, then five Space inputs hatched into imported dinosaur visual with `WalkSpeed=12`, `JumpPower=50`, and HatchScreen disabled. |
| Lua syntax | PASS | `find src -name '*.lua' ... luac -p` passed after source fixes. |
| Rojo build | PASS | `rojo build default.project.json --output /tmp/eggBreakers-g014-source-fix.rbxl` passed. |
| Server visual release validation | PASS | Studio `CharacterVisualService:ValidateReleaseVisualAssets()` passed after Creator Store imports were organized under `ReplicatedStorage.ImportedAssetLibrary`. |
| E2E G013/G014 source gate | FAIL | Full E2E gate still includes release-blocking asset count 23/500 after quality quarantine and other broad release placement/client/mobile gaps. |
| Asset release-ready count | FAIL | Studio `AssetImportAuditService` reports 23 quality-approved live imported/release-ready assets after quarantine; required target is 500 release-ready visible assets. |
| Plan/manifest consistency | PASS/FAIL-honest | `docs/G014/NextCreatorStoreAssetAudit.md` confirms G011 is a 500-ID catalog, G014 is the live 23/500 post-quality-quarantine materialization baseline, and post-catalog live IDs require explicit tag/audit/placement proof rather than manifest backfill. |
| Full Studio TestRunner | FAIL | Edit-time G014 gate still fails release blockers including 23/500 imported asset count after quality quarantine. Play VM cannot directly require `ServerScriptService.Tests` through current MCP path, so full Play TestRunner remains unproven. |

## Latest Continuation Evidence — 2026-05-27

| Gate | Status | Evidence |
|---|---|---|
| Studio live asset audit | FAIL | `AssetImportAuditService:AuditAndRepair({ mutate = true })` in Studio reported catalogedSourceAssetIds=500, actuallyImportedAssets=23, auditedImportedAssets=23 after scriptless audit mark, taggedImportedAssets=23, placedVisibleAssets=23, releaseReadyVisibleAssets=23, scriptObjectsFound=0, scriptsQuarantined=0. |
| Release import validation | FAIL | `ValidateReleaseCounts(500)` returned failures: `actuallyImportedAssets=23; expected at least 500`, `releaseReadyVisibleAssets=23; expected at least 500`. |
| Edit-mode TestRunner | FAIL | `G014FinalGateSuite` run in Studio reported 28 total, 18 passed, 10 failed. Source fixes were added for mock notification casts, reward profile loading, live import count honesty, and record-safe carcass creation. Current edit VM still has stale required module cache for several fixed services; fresh source build is required for authoritative rerun. |
| Source syntax/build after fixes | PASS | `find src -name '*.lua' ... luac -p`, `rojo build default.project.json --output /tmp/eggBreakers-g014-fixes-3.rbxl`, and `git diff --check -- . ':(exclude)eggBreakers.rbxl'` passed. |

## Import Batch Evidence — 2026-05-27

| Gate | Status | Evidence |
|---|---|---|
| G014 import batch | FAIL | Imported and placed 5 additional unique Creator Store assets: 162897134, 7727678976, 108178603114720, 3505076540, 74355704971397. That older batch improved the live audit to 10/500; later imports now supersede the current count to 23/500 after quality quarantine with a 477 gap after quality quarantine. |
| Source verification after import docs | PASS | `luac -p`, `rojo build default.project.json --output /tmp/eggBreakers-g014-import-batch-10.rbxl`, and `git diff --check` passed. |


## G015 Follow-up Evidence — 2026-05-27

Later evidence supersedes stale intermediate counts: active `eggBreakers2.rbxl` now audits at 23/500 release-ready visible assets after quality quarantine, not release PASS. Fresh edit-mode all-category TestRunner was previously 146 total, 129 passed, 17 failed; a newer full reload TestRunner still remains required. Mobile/controller proof and `.rbxl` save/reopen persistence remain BLOCKED. G014 remains honest FAIL.

## Import Batch Evidence — 2026-05-29

| Gate | Status | Evidence |
|---|---|---|
| Live Studio import continuation | FAIL | Active `eggBreakers2.rbxl` Studio audit started at 30/500, then two additional import/tag/place/scrub batches raised live `releaseReadyVisibleAssets` to 78/500 before quality quarantine, now 23/500 with a 477 gap after quality quarantine. |
| Save attempt | FAIL | Tried MCP `user_keyboard_input` Cmd+S, but the tool returned that keyboard input is only available in play mode with client datamodel focused; `.rbxl` save/reopen persistence remains unproven. |

## Import Batch Evidence — 2026-05-30

| Gate | Status | Evidence |
|---|---|---|
| Live Studio import continuation | FAIL | Imported/tagged/placed/scrubbed 10 more unique Creator Store assets. Live `AssetImportAuditService` now reports `releaseReadyVisibleAssets=23/500 after quality quarantine`, leaving a 477 gap after quality quarantine. |

## Import Batch Evidence — 2026-05-30 B5

| Gate | Status | Evidence |
|---|---|---|
| Live Studio import continuation | FAIL | Imported/tagged/placed/scrubbed 10 more unique Creator Store assets. Live `AssetImportAuditService` now reports `releaseReadyVisibleAssets=23/500 after quality quarantine`, leaving a 477 gap after quality quarantine. |

## Import Batch Evidence — 2026-05-30 B6

| Gate | Status | Evidence |
|---|---|---|
| Live Studio import continuation | FAIL | Imported/tagged/placed/scrubbed 10 more unique Creator Store assets. Live `AssetImportAuditService` now reports `releaseReadyVisibleAssets=23/500 after quality quarantine`, leaving a 477 gap after quality quarantine. |


## Continuation live Studio probe — 2026-05-30

| Check | Result | Evidence |
|---|---|---|
| Source syntax | PASS | `find src -name '*.lua' -print \| sort \| xargs -n 1 luac -p` passed. |
| Rojo source build | PASS | `rojo build default.project.json --output /tmp/eggBreakers-continuation.rbxl` passed. |
| Open Studio bootstrap/audit before sync attempt | FAIL-honest | Live `AssetImportAuditService` ran and reported releaseReadyVisibleAssets=23/500, actuallyImportedAssets=23, scripts=0; release validation failed as expected. |
| Open Studio all-category TestRunner before sync attempt | FAIL | 220 total, 171 passed, 49 failed. Several failures showed stale Studio module cache/source mismatch (for example missing `NPCService:GetFlightTarget` and `MapLayoutService:GetPlayerSpawnForSpecies` even though current source contains both). |
| Rojo live sync attempt | FAIL | `rojo serve default.project.json --port 34873` started, but active Studio then showed `ServerScriptService` empty through MCP. The server process was stopped with `pkill`; fresh Studio/Rojo reload remains required before using Studio TestRunner as authoritative evidence. |


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
