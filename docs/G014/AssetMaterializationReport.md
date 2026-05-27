# G014 Asset Materialization Report

Latest Commit: af9fd05 plus current live Studio import batch docs pending commit.

| State | Count |
|---|---:|
| Cataloged SourceAssetIds | 500+ |
| Actually Imported Assets | 10 live imported assets from Studio audit |
| Audited Imported Assets | 10 live assets marked script-audited; below target |
| Tagged Imported Assets | 10 live tagged imported assets; below target |
| Placed Visible Assets | 10 live placed/visible imported assets; below target |
| Release Ready Visible Assets | 10 live release-ready visible assets, below target |
| Script Objects Found | 0 in live imported visual roots during Studio audit |
| Scripts Quarantined | 0; no executable imported scripts found in the 10 live imported roots |
| Remaining Release Ready Gap To 500 | 490 |

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

Live Studio audit after this batch: actuallyImportedAssets=10, auditedImportedAssets=10, taggedImportedAssets=10, placedVisibleAssets=10, releaseReadyVisibleAssets=10, scriptObjectsFound=0, scriptsQuarantined=0. Release validation still fails because the target is 500.
