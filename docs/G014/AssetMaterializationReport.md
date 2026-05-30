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


## G024 import/materialization continuation — 2026-05-30T01:37:28Z

Inserted, sanitized, tagged, and intentionally placed 10 additional Creator Store assets:

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 212002982 | G024_Imported_LogBridge_01 | JungleBasin | JungleBridgeVisual | 0 | non-mesh |
| 60395419 | G024_Imported_JungleTree_01 | JungleBasin | JungleBrowseVisual | 0 | non-mesh |
| 44521224 | G024_Imported_SmallPlant_01 | NurseryGrove | HerbivoreFoodVisual | 1 removed | non-mesh |
| 6249242162 | G024_Imported_ForestMushroom_01 | FernPlains | HerbivoreFoodVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 4950237880 | G024_Imported_CrystalRock_01 | RedstoneCanyon | CanyonRockVisual | 0 | MeshPart detected; source policy will exclude until replacement/exception |
| 44100564 | G024_Imported_ConcreteBarrier_01 | ApocalypticCity | CityBarrierVisual | 4 removed | non-mesh |
| 35501437 | G024_Imported_RustyBarrel_01 | ApocalypticCity | CityLootPropVisual | 0 | non-mesh |
| 693865885 | G024_Imported_DinoSkeleton_01 | MountainNestingCliffs | FossilVisual | 0 | non-mesh |
| 1916851298 | G024_Imported_DinoFootprint_01 | RedstoneCanyon | FossilVisual | 0 | non-mesh |
| 148249956 | G024_Imported_CityJunkVehicle_01 | ApocalypticCity | CityCarWreckVisual | 3 removed | non-mesh |

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after this batch:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 68 |
| Audited Imported Assets | 68 |
| Tagged Imported Assets | 68 |
| Placed Visible Assets | 68 |
| Release Ready Visible Assets | 68 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 432 |

Live `AssetAuditService:ScanWorkspace()` after the batch: PASS (`scanFailureCount=0`).

Verification: `luac -p` all Lua PASS; `git diff --check` PASS; `rojo build /tmp/eggBreakers-g024-import-batch.rbxl` PASS.

Release still fails honestly because materialized live count is `68/500` and final mobile/RBXL/fresh all-category proof remains missing.

## G024 supplemental import/materialization continuation — 2026-05-30T01:41:40Z

Owner focus for this pass: do **not** pivot; keep tracking map placement, low-quality/mesh exclusion, kid-friendly mobile UI, food-capable vegetation, and honest 500-unique imported asset progress.

Inserted/sanitized/tagged/placed 10 additional Creator Store insertions in live Studio. Five were new unique live SourceAssetIds over the existing G024 checkpoint; duplicates and mesh-policy exclusions are not treated as proof of 500 final assets.

| SourceAssetId | Insert Name | Zone | Role | Script Audit | Mesh/LQ Note |
|---|---|---|---|---|---|
| 212002982 | G024_Imported_BridgeLog_01 | FernPlains | landmark-bridge | 0 | duplicate SourceAssetId already present |
| 60395419 | G024_Imported_JungleTree_01 | JungleBasin | vegetation-food-potential | 0 | duplicate SourceAssetId already present; tagged PotentialFood/FoodSource |
| 44521224 | G024_Imported_SmallPlant_01 | NurseryGrove | starter-plant-food | 0 | duplicate SourceAssetId already present; tagged FoodSource |
| 6249242162 | G024_Imported_Mushroom_01 | SwampDelta | swamp-plant-food | 0 | MeshPart detected; owner no-mesh policy marks as excluded/replacement-needed |
| 3082762400 | G024_Imported_CrystalRock_01 | RedstoneCanyon | landmark-rock | 0 | new unique import in live place |
| 44100564 | G024_Imported_Barricade_01 | ApocalypticCity | city-risk-cover | 0 | duplicate SourceAssetId already present |
| 12414580049 | G024_Imported_RustyPipe_01 | ApocalypticCity | city-ruin-prop | 0 | new unique import in live place |
| 15602137818 | G024_Imported_StreetLight_01 | ApocalypticCity | city-landmark-light | 0 | MeshPart detected; owner no-mesh policy marks as excluded/replacement-needed |
| 5618961046 | G024_Imported_SwampRoots_01 | SwampDelta | vegetation-food-potential | 0 | new unique import; tagged PotentialFood/FoodSource |
| 8382516725 | G024_Imported_StoneArch_01 | RedstoneCanyon | navigation-landmark | 0 | new unique import in live place |

Live Studio evidence after this supplemental pass:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 73 |
| Audited Imported Assets | 73 |
| Tagged Imported Assets | 73 |
| Placed Visible Assets | 73 |
| Release Ready Visible Assets | 73 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 427 |

Live `AssetAuditService:ScanWorkspace()` after the pass: PASS (`scanFailureCount=0`).

Additional source/UI cleanup in this checkpoint: mobile controls changed to icon-first labels, hidden optional Flight/Swim remains non-visible for the scoped vertical slice, action feedback is shorter, and the food/water waypoint cue now uses a visual arrow/sparkle instead of debug-shell text.

Verification: `luac -p` all Lua PASS; `git diff --check` PASS; `rojo build /tmp/eggBreakers-g024-supplement.rbxl` PASS.

Release still fails honestly because materialized live count is `73/500`; full mobile/touch proof, RBXL save/reopen proof, and all-category fresh Studio TestRunner are still not green.
