# G015 Asset Materialization Report

Overall: FAIL — live Studio audit after batch reached 34/500 release-ready visible unique SourceAssetIds.

## Counts

| State | Count |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 34 |
| Audited Imported Assets | 34 |
| Tagged Imported Assets | 34 |
| Placed Visible Assets | 34 |
| Release Ready Visible Assets | 34 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Remaining Gap To 500 | 466 |

## G015 Live Import Batch

| batchId | query | searchResultId | insertedAssetId | SourceAssetId | unique | duplicate | source creator | category | target biome/use | imported location | placed location | AssetManifestId | SourceAssetId attr | CreatorStoreOnly attr | ImportedVisibleAsset attr | script count before audit | scripts removed/quarantined | audit status | releaseReady | failure reason |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| G015-live-batch-001 | dinosaur nest egg | 5361cbc5-c3f6-4971-8a5c-43986e861456 | 4666597044 | 4666597044 | yes | no | Creator Store primary result | Egg/nest/hatch assets | MountainNestingCliffs | Workspace.G015_Dinosaur_Nest_Egg | Workspace.Map.ImportedAssets.G015_Dinosaur_Nest_Egg | G015-20260527-001 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes |  |
| G015-live-batch-001 | jungle fern plant | 36df7352-6529-4717-a9ef-3f4068a47e01 | 14703400302 | 14703400302 | yes | no | Creator Store primary result | Jungle Basin foliage/vines/logs | JungleBasin | Workspace.G015_Jungle_Fern_Plant | Workspace.Map.ImportedAssets.G015_Jungle_Fern_Plant | G015-20260527-002 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes |  |
| G015-live-batch-001 | swamp reeds plant | 09df9430-3005-4ef6-9486-09a88777686f | 13261235137 | 13261235137 | yes | no | Creator Store primary result | Swamp Delta reeds/water plants/logs | SwampDelta | Workspace.G015_Swamp_Reeds_Plant | Workspace.Map.ImportedAssets.G015_Swamp_Reeds_Plant | G015-20260527-003 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes |  |
| G015-live-batch-001 | apocalypse city ruins | 8d7e2acb-ea1c-45db-a300-48aa165a8fcc | 108178603114720 | 108178603114720 | no | yes, already in G014 set | Creator Store primary result | Apocalyptic City ruins/cars/rubble/overgrowth | ApocalypticCity | Workspace.G015_Apocalypse_City_Ruins | Workspace.Map.ImportedAssets.G015_Apocalypse_City_Ruins | G015-20260527-004 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes | duplicate SourceAssetId does not increase unique count |
| G015-live-batch-001 | wrecked car apocalypse | 171e2fd5-4757-485c-a599-64a77d56945b | 111614048167471 | 111614048167471 | yes | no | Creator Store primary result | Apocalyptic City ruins/cars/rubble/overgrowth | ApocalypticCity | Workspace.G015_Wrecked_Car_Apocalypse | Workspace.Map.ImportedAssets.G015_Wrecked_Car_Apocalypse | G015-20260527-005 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes |  |
| G015-live-batch-001 | dinosaur fossil bones | fb21ca5f-44ea-4697-98c5-f91b31b56e5b | 137420276606883 | 137420276606883 | no | yes, already in tracked set | Creator Store primary result | Redstone Canyon rocks/cliffs/fossils | RedstoneCanyon | Workspace.G015_Dinosaur_Fossil_Bones | Workspace.Map.ImportedAssets.G015_Dinosaur_Fossil_Bones | G015-20260527-006 | yes | yes | yes | unknown | quarantined by audit if executable | PASS | yes | duplicate SourceAssetId does not increase unique count |
