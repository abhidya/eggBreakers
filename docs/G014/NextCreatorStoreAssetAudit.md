# G014 Next Creator Store Asset Audit

Date: 2026-05-29
Scope: read-only plan/manifest/doc consistency audit for the next Creator Store asset batch. No Studio import was attempted in this worker lane.

## Source-of-truth split

- `src/ReplicatedStorage/Shared/AssetManifest.lua` / `docs/G011/AssetManifest.md` remain the G011 catalog source of truth: 500 manifest entries and 500 unique Creator Store `SourceAssetId` values.
- `docs/G014/AssetMaterializationReport.md` remains the G014 live materialization source of truth: 48 release-ready visible imported assets in the active Studio audit, so the release gap is 452 assets.
- Catalog membership is not required for a later live import to count as a materialized asset, but catalog rows alone never count as imported assets.

## Consistency findings

| Check | Result | Evidence |
|---|---|---|
| G011 catalog count | PASS | `AssetManifest.SourceAssets` validates at 500 entries / 500 unique `SourceAssetId` values. |
| G014 live count | PASS/FAIL-honest | G014 docs consistently report 48 release-ready visible imports, below the 500 release target. |
| G013/G015 plan freshness | FAIL-stale | Older plans still mention 44/500 or 34/500 baselines; those are superseded by G014's 48/500 audit and must not be used for the next batch gap. |
| G014 batch IDs vs G011 catalog | INFO | 6 of 25 documented G014 batch rows are in the G011 catalog; 19 are post-catalog live imports. This is acceptable only if reports keep cataloged vs live-imported states separate. |

## G014 documented batch IDs checked against G011 catalog

| Use | SourceAssetId | Placed Zone | In G011 manifest |
|---|---:|---|---|
| Fern plant / herbivore food visual | 162897134 | FernPlains | no |
| Dead tree swamp prop | 7727678976 | SwampDelta | yes |
| Old Eden city ruin prop | 108178603114720 | ApocalypticCity | yes |
| Fossil/bone collectible visual | 3505076540 | ApocalypticCity | no |
| Pond/water source visual | 74355704971397 | SwampDelta | no |
| Redstone canyon rock | 116211098194180 | RedstoneCanyon | no |
| Canyon cactus/plant food | 393735021 | RedstoneCanyon | no |
| Jungle vines | 122280174982594 | JungleBasin | no |
| Nursery prehistoric plant food | 26953061 | NurseryGrove | no |
| Old Eden ruined building | 125968528580422 | ApocalypticCity | no |
| Old Eden abandoned car | 109905665910630 | ApocalypticCity | yes |
| Fern Plains stump | 117401257092974 | FernPlains | no |
| Swamp log | 16458140435 | SwampDelta | no |
| Mountain nesting visual | 150068032 | MountainNestingCliffs | yes |
| City dinosaur bones/fossil | 176461892 | ApocalypticCity | yes |
| Large fern herbivore food | 367401485 | FernPlains | no |
| Jungle mossy boulder | 8421400545 | JungleBasin | no |
| Old Eden street light | 14205708 | ApocalypticCity | no |
| Old Eden rusty barrel | 13304723548 | ApocalypticCity | yes |
| Swamp bridge | 9016345250 | SwampDelta | no |
| Redstone rock arch | 122586576789991 | RedstoneCanyon | no |
| Swamp lily pad / water marker | 79823722717297 | SwampDelta | no |
| Jungle flower herbivore food | 7935277298 | JungleBasin | no |
| Nursery fallen branch | 13112823085 | NurseryGrove | no |
| Old Eden road sign | 87098449723130 | ApocalypticCity | no |

## Next asset plan guardrails

The next worker with live Creator Store insert access should use the G014 baseline, not older G013/G015 baselines:

1. Start from `releaseReadyVisibleAssets=48`; the current honest gap is `500 - 48 = 452`.
2. Prefer categories with zero or low proven release-ready coverage, especially carnivore carcass/food and NPC creature assets, before adding more city/foliage duplicates.
3. For each inserted primary result, dedupe against:
   - G014 documented live rows above,
   - `src/ReplicatedStorage/Shared/UniqueImportPilotReport.lua`, and
   - `src/ReplicatedStorage/Shared/AssetManifest.lua` only for catalog-membership reporting.
4. Count only real inserted primary `SourceAssetId` values that are tagged, script-audited/quarantined, placed visible, and release-ready.
5. Do not treat the 19 post-catalog G014 IDs as manifest errors, and do not treat any of the 500 G011 catalog rows as live imports without Studio audit proof.

## Stop condition

G014 remains FAIL until the live audit reaches at least 500 release-ready visible imported assets and a fresh Studio all-category/mobile/RBXL proof set is attached. This audit only closes the plan/manifest/doc consistency gap for the next Creator Store asset batch.
