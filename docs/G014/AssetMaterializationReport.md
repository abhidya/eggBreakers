# G014 Asset Materialization Report

Latest Commit: 8c22854 plus current live Studio import batch docs pending commit.

| State | Count |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 23 live imported assets from Studio audit after quality quarantine |
| Audited Imported Assets | 23 live assets marked script-audited after quality quarantine; below target |
| Tagged Imported Assets | 23 live tagged imported assets after quality quarantine; below target |
| Placed Visible Assets | 23 live placed/visible imported assets after quality quarantine; below target |
| Release Ready Visible Assets | 23 live release-ready visible assets after quality quarantine, below target |
| Script Objects Found | 0 in live imported visual roots during Studio audit |
| Scripts Quarantined | 0; no executable imported scripts found in the 23 live imported roots after quality quarantine |
| Remaining Release Ready Gap To 500 | 477 |

Plan/manifest consistency audit: see `docs/G014/NextCreatorStoreAssetAudit.md`. The audit confirms G011 remains a 500-ID catalog, while G014 live materialization is now 23/500 after quality quarantine; post-catalog live imports are not manifest errors, and catalog-only rows are not counted as imported assets.

G014 imported these/organized these required gameplay visuals in Studio for smoke proof:
- `Imported_Dinosaur_Egg_Nest` from Creator Store asset `8895193`.
- `Imported_Playable_Gallimimus_Model_Set` from asset `646098924`.
- `Imported_Playable_Triceratops_Model_Set` from asset `63385946`.
- `Imported_Playable_Velociraptor_Model_Set` from asset `412719275`.
- `Imported_Playable_Carnotaurus_Model_Set` from asset `471993246`.

These fix hatch/dinosaur visibility for the open Studio smoke, but do **not** close the 500 release-ready asset gate.

## G014 Import Batch — 2026-05-27

Added and organized 5 more live Creator Store imports in open Studio, then tagged and placed clones under `Workspace/Map/ImportedAssets`:

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Fern plant / herbivore food visual | 162897134 | FernPlains |
| Dead tree swamp prop | 7727678976 | SwampDelta |
| Old Eden city ruin prop | 108178603114720 | ApocalypticCity |
| Fossil/bone collectible visual | 3505076540 | ApocalypticCity |
| Pond/water source visual | 74355704971397 | SwampDelta |

Live Studio audit after the 2026-05-27 batch was previously recorded as 10/500. The current top-level counts above supersede that older batch count after later imports.


## G015 Follow-up Evidence — 2026-05-27

Later evidence supersedes stale intermediate counts: active `eggBreakers2.rbxl` now audits at 23/500 release-ready visible assets after quality quarantine, not release PASS. Fresh edit-mode all-category TestRunner was previously 146 total, 129 passed, 17 failed; a newer full reload TestRunner still remains required. Mobile/controller proof and `.rbxl` save/reopen persistence remain BLOCKED. G014 remains honest FAIL.

## G014 Import Batches — 2026-05-29

Added and organized multiple Creator Store import batches in open Studio. Live audit increased to 78/500 before quality quarantine, then dropped to 23/500 after LQ/mesh/simple generated asset quarantine; release validation still fails until 500 live release-ready assets are proven.

### Batch 2

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Redstone canyon rock | 116211098194180 | RedstoneCanyon |
| Canyon cactus/plant food | 393735021 | RedstoneCanyon |
| Jungle vines | 122280174982594 | JungleBasin |
| Nursery prehistoric plant food | 26953061 | NurseryGrove |
| Old Eden ruined building | 125968528580422 | ApocalypticCity |
| Old Eden abandoned car | 109905665910630 | ApocalypticCity |
| Fern Plains stump | 117401257092974 | FernPlains |
| Swamp log | 16458140435 | SwampDelta |
| Mountain nesting visual | 150068032 | MountainNestingCliffs |
| City dinosaur bones/fossil | 176461892 | ApocalypticCity |

### Batch 3

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Large fern herbivore food | 367401485 | FernPlains |
| Jungle mossy boulder | 8421400545 | JungleBasin |
| Old Eden street light | 14205708 | ApocalypticCity |
| Old Eden rusty barrel | 13304723548 | ApocalypticCity |
| Swamp bridge | 9016342250 | SwampDelta |
| Redstone rock arch | 122586576789991 | RedstoneCanyon |
| Swamp lily pad / water marker | 79823722717297 | SwampDelta |
| Jungle flower herbivore food | 7935277298 | JungleBasin |
| Nursery fallen branch | 13112823085 | NurseryGrove |
| Old Eden road sign | 87098449723130 | ApocalypticCity |

Live Studio audit after these batches: actuallyImportedAssets=23, auditedImportedAssets=23, taggedImportedAssets=23, placedVisibleAssets=23, releaseReadyVisibleAssets=23, scriptObjectsFound=0, scriptsQuarantined=0. Release validation still fails because the target is 500. Studio keyboard save attempt through MCP was rejected because `user_keyboard_input` is play-mode-only.

## G014 Import Batch — 2026-05-30

Added and organized 10 more Creator Store imports in active `eggBreakers2.rbxl` Studio:

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Fern Plains rock pack | 87735881884546 | FernPlains |
| Old Eden ancient ruins | 18249228365 | ApocalypticCity |
| Swamp tree | 18986634714 | SwampDelta |
| Jungle bush food | 18984868677 | JungleBasin |
| City dinosaur skeleton fossil | 123983185 | ApocalypticCity |
| Old Eden rusty crate | 247002357 | ApocalypticCity |
| Canyon cave rock | 139252642326961 | RedstoneCanyon |
| Jungle waterfall/water marker | 78569328753735 | JungleBasin |
| Redstone desert rock | 4490168579 | RedstoneCanyon |
| Old Eden fence | 5000110511 | ApocalypticCity |

Live Studio audit after this batch: actuallyImportedAssets=23, auditedImportedAssets=23, taggedImportedAssets=23, placedVisibleAssets=23, releaseReadyVisibleAssets=23, scriptObjectsFound=0, scriptsQuarantined=0. Release validation still fails because the target is 500.

## G014 Import Batch — 2026-05-30 B5

Added and organized 10 more Creator Store imports in active `eggBreakers2.rbxl` Studio:

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Fern mossy tree | 2534654468 | FernPlains |
| Jungle rock cluster | 12102020064 | JungleBasin |
| Old Eden debris | 119223386301433 | ApocalypticCity |
| Old Eden tire | 8465987147 | ApocalypticCity |
| City bone pile fossil | 54636442 | ApocalypticCity |
| Redstone cliff | 110547461624266 | RedstoneCanyon |
| Swamp grass herbivore food | 425145138 | SwampDelta |
| Fern pond water | 74107500 | FernPlains |
| Nursery flower food | 125622022063548 | NurseryGrove |
| Old Eden ruined wall | 102795034701648 | ApocalypticCity |

Live Studio audit after this batch: actuallyImportedAssets=23, auditedImportedAssets=23, taggedImportedAssets=23, placedVisibleAssets=23, releaseReadyVisibleAssets=23, scriptObjectsFound=0, scriptsQuarantined=0. Release validation still fails because the target is 500.

## G014 Import Batch — 2026-05-30 B6

Added and organized 10 more Creator Store imports in active `eggBreakers2.rbxl` Studio:

| Use | SourceAssetId | Placed Zone |
|---|---:|---|
| Jungle log | 5380493574 | JungleBasin |
| Fern moss patch | 375760608 | FernPlains |
| Old Eden broken concrete wall | 555552023 | ApocalypticCity |
| Old Eden rusty pipes | 11469354822 | ApocalypticCity |
| City skull fossil | 101613486945656 | ApocalypticCity |
| Redstone canyon arch | 96445666021133 | RedstoneCanyon |
| Swamp plant herbivore food | 84094116943108 | SwampDelta |
| Swamp river rocks / water marker | 230489811 | SwampDelta |
| Nursery berry bush food | 6708093 | NurseryGrove |
| Old Eden ruined pillar | 86335431479789 | ApocalypticCity |

Live Studio audit after this batch: actuallyImportedAssets=23, auditedImportedAssets=23, taggedImportedAssets=23, placedVisibleAssets=23, releaseReadyVisibleAssets=23, scriptObjectsFound=0, scriptsQuarantined=0. Release validation still fails because the target is 500.


## Source-only asset/map quality patch — 2026-05-30

- `AssetImportAuditService.lua` now quarantines non-required low-quality/mesh imported roots during mutate audits and reports `qualityAssetsQuarantined` separately.
- `MapLayoutService.lua` now uses exact half-scale source compaction, re-centers mismatched food/carcass placements into their declared zones, keeps procedural food/tree visuals hidden, and tags NPC spawns as potential food when defeated.
- No client UI or combat files were changed in this patch. Live G014 release count remains an honest 23/500 until Studio is synced and rerun.


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
