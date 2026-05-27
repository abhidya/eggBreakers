# G014 Test Results

Overall release gate: **FAIL**.

| Gate | Status | Evidence |
|---|---|---|
| Studio MCP responsiveness | PASS | `execute_luau` returned place `eggBreakers`, PlaceId `111212176992206`; `Bootstrap.Init()` created all required remotes. |
| Fresh hatch smoke | PASS | In Play mode, player `blazimann` spawned hidden default avatar (`visibleDefaultParts=0`), unhatched movement locked (`WalkSpeed=0`), `HatchScreen`, `MainHUD`, and `MobileControls` appeared, imported egg visual attached, then five Space inputs hatched into imported dinosaur visual with `WalkSpeed=12`, `JumpPower=50`, and HatchScreen disabled. |
| Lua syntax | PASS | `find src -name '*.lua' ... luac -p` passed after source fixes. |
| Rojo build | PASS | `rojo build default.project.json --output /tmp/eggBreakers-g014-source-fix.rbxl` passed. |
| Server visual release validation | PASS | Studio `CharacterVisualService:ValidateReleaseVisualAssets()` passed after Creator Store imports were organized under `ReplicatedStorage.ImportedAssetLibrary`. |
| E2E G013/G014 source gate | FAIL | Full E2E gate still includes release-blocking asset count 10/500 and other broad release placement/client/mobile gaps. |
| Asset release-ready count | FAIL | Studio `AssetImportAuditService` reports 10 live imported/release-ready assets; required target is 500 release-ready visible assets. |
| Full Studio TestRunner | FAIL | Edit-time G014 gate still fails release blockers including 10/500 imported asset count. Play VM cannot directly require `ServerScriptService.Tests` through current MCP path, so full Play TestRunner remains unproven. |

## Latest Continuation Evidence — 2026-05-27

| Gate | Status | Evidence |
|---|---|---|
| Studio live asset audit | FAIL | `AssetImportAuditService:AuditAndRepair({ mutate = true })` in Studio reported catalogedSourceAssetIds=500, actuallyImportedAssets=10, auditedImportedAssets=10 after scriptless audit mark, taggedImportedAssets=10, placedVisibleAssets=10, releaseReadyVisibleAssets=10, scriptObjectsFound=0, scriptsQuarantined=0. |
| Release import validation | FAIL | `ValidateReleaseCounts(500)` returned failures: `actuallyImportedAssets=10; expected at least 500`, `releaseReadyVisibleAssets=10; expected at least 500`. |
| Edit-mode TestRunner | FAIL | `G014FinalGateSuite` run in Studio reported 28 total, 18 passed, 10 failed. Source fixes were added for mock notification casts, reward profile loading, live import count honesty, and record-safe carcass creation. Current edit VM still has stale required module cache for several fixed services; fresh source build is required for authoritative rerun. |
| Source syntax/build after fixes | PASS | `find src -name '*.lua' ... luac -p`, `rojo build default.project.json --output /tmp/eggBreakers-g014-fixes-3.rbxl`, and `git diff --check -- . ':(exclude)eggBreakers.rbxl'` passed. |

## Import Batch Evidence — 2026-05-27

| Gate | Status | Evidence |
|---|---|---|
| G014 import batch | FAIL | Imported and placed 5 additional unique Creator Store assets: 162897134, 7727678976, 108178603114720, 3505076540, 74355704971397. Live audit improved to releaseReadyVisibleAssets=10/500, leaving a 490 gap. |
| Source verification after import docs | PASS | `luac -p`, `rojo build default.project.json --output /tmp/eggBreakers-g014-import-batch-10.rbxl`, and `git diff --check` passed. |
