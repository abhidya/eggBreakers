# G013 Next Creator Store Import Batch Plan

## Current Honest Count

- Required release target: **500** unique, materialized Roblox Creator Store primary `SourceAssetId` values.
- Current tracked materialized unique primary imports: **44**.
- Remaining unique primary import gap: **456**.
- Manifest/catalog-only rows are **not counted** as imported.
- Duplicate primary `SourceAssetId` values are **not counted**.
- Mesh-only, fake placeholder, blockout, or locally cloned stand-ins are **not counted**.

## Why This Task Does Not Claim New Imports

Studio MCP was available only as the generic Studio bridge in this worker lane. A safe live Luau audit probe was attempted, but `Roblox_Studio/execute_luau` timed out after 120 seconds. No Creator Store search/insert MCP tool was exposed in this session, and the task explicitly forbids pretending manifest rows or duplicates were imported.

Therefore this task leaves the materialized count unchanged at **44/500** and provides the next import plan needed to close the **456** gap.

## Import Rules For The Next Worker With Live Creator Store Insert Access

1. Run only in Studio edit mode; stop play mode before inserting.
2. Insert real Creator Store primary assets only through the Creator Store insertion tool.
3. Record the returned primary `SourceAssetId` for each insertion.
4. Before counting a row, dedupe against:
   - `src/ReplicatedStorage/Shared/UniqueImportPilotReport.lua`
   - any new rows produced in the same batch
   - `AssetManifest.SourceAssets` when reporting whether the source was already cataloged
5. Do not count secondary result IDs unless that exact secondary asset is directly inserted/materialized.
6. Do not count mesh/fake placeholders, default visible `Part` blockouts, or local clones.
7. Quarantine or reject imported executable scripts before marking a visible asset release-ready.
8. Keep these states separate in reports: cataloged, inserted/materialized, tagged, script-audited, placed visible, release-ready.

## Exact Query Categories And Target Counts

The next batch should target exactly **456** new unique primary imports. The counts below intentionally sum to 456.

| Batch | Zone / Need | Exact Creator Store search queries | Target new unique primary imports |
| --- | --- | --- | ---: |
| 1 | Nursery/Fern starter vegetation | `low poly tree pack`, `fern plant pack`, `bush nature pack`, `grass clump field` | 38 |
| 2 | Jungle canopy and vines | `jungle tree pack`, `hanging vines jungle`, `tropical plant pack`, `jungle ruins plants` | 38 |
| 3 | Swamp vegetation and reeds | `swamp tree cypress`, `marsh reeds grass`, `mangrove roots swamp`, `swamp lily pads` | 38 |
| 4 | Logs, stumps, deadfall | `fallen log forest`, `tree stump nature`, `mossy logs`, `dead tree swamp` | 38 |
| 5 | Redstone canyon rocks | `red rock canyon`, `canyon boulder set`, `desert rock formation`, `rock cliff canyon` | 38 |
| 6 | Mountain nesting cliffs | `mountain cliff rocks`, `stone arch cliff`, `nesting cliff cave`, `rock ledge mountain` | 38 |
| 7 | Fossils and dinosaur bones | `dinosaur fossil bones`, `prehistoric skeleton`, `large fossil bones`, `dino skull fossil` | 38 |
| 8 | Nests and egg props | `dinosaur nest`, `egg nest model`, `prehistoric nest`, `large bird nest` | 38 |
| 9 | Apocalyptic city buildings | `post apocalyptic building`, `ruined wall building`, `abandoned city ruins`, `broken building rubble` | 38 |
| 10 | City vehicles and debris | `wrecked car apocalypse`, `rusty car wreck`, `abandoned vehicle wreck`, `concrete debris pile` | 38 |
| 11 | Water/shoreline gameplay props | `pond water nature`, `shallow water plants`, `river rocks reeds`, `swamp water plants` | 38 |
| 12 | Food/carcass and interactable props | `animal carcass food`, `dinosaur meat carcass`, `berry bush food`, `prehistoric plant food` | 38 |
| **Total** |  |  | **456** |

## Reporting Template For The Import Worker

For each successful primary insertion, append a row with:

```lua
{ Query = "<exact query>", SearchId = "<tool search id>", InsertGuid = "<tool insert guid>", SourceAssetId = "<primary numeric id>" }
```

Then update counts honestly:

- `SuccessfulPrimaryImports`: inserted primary rows in that batch.
- `UniquePrimarySourceAssetIds`: unique IDs in that batch after dedupe.
- `NewPrimaryIdsVersusTrackedReport`: unique IDs not already present in prior materialized reports.
- `CumulativeTrackedUniquePrimaryIds`: prior cumulative count + new unique IDs only.
- `RemainingGapTo500`: `500 - CumulativeTrackedUniquePrimaryIds`.

## Stop Condition

The materialization gate remains **FAIL** until `CumulativeTrackedUniquePrimaryIds >= 500` and the corresponding live/imported assets are independently audited as script-safe, tagged, and release-ready. This plan alone does not satisfy the release import requirement.
