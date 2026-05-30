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
