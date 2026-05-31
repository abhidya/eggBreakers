# Authorized Creator Store Import Workflow

Date verified: 2026-05-31

## Diagnosis

`InsertService:LoadAsset(<assetId>)` is the wrong insertion path for the current Studio setup. The G018 insertion attempt proved that selected Creator Store IDs can be visible to search but still fail direct `LoadAsset` with `User is not authorized to access Asset`.

Use the Studio Creator Store plugin path instead:

1. `node tools/roblox_search_direct.js search_assets '{"query":"<query>","max_results":5}'` ranks candidates through the direct one-shot search route.
2. `Roblox_Studio.search_creator_store` re-resolves the accepted candidate in the live `eggBreakers2`/`eggBreakers3` Studio session.
3. `Roblox_Studio.insert_from_creator_store` inserts from the returned Studio `searchId`.

Do not call `InsertService:LoadAsset` for the next batch.

## Verified Bridge

The authorized Studio search path resolved exact G018 candidates without inserting anything:

| Candidate | Studio search query | Studio result |
| --- | --- | --- |
| `Broken Car` `4675550604` | `Broken Car 4675550604` | `searchId=f8fffa26-1e9f-408d-b385-af02c24e4310`, object types `car`, `vehicle` |
| `Mulet fish Mesh` `6923368893` | `Mulet fish Mesh 6923368893` | `searchId=65d57dce-9172-43da-a9ca-c3c815c67b21`, object types `fish`, `animal`, `sea creature`, `fence`, `structure`, `sandbag`, `object`, `helmet`, `headgear` |
| `VelociRaptor Blue` `8585959958` | `VelociRaptor Blue 8585959958` | `searchId=c13309ca-a981-4a4f-86bd-7aeb560c9346`, object types `dinosaur`, `creature`, `plush`, `character`, `pet` |

These `searchId` values are cache/session artifacts. Re-run `Roblox_Studio.search_creator_store` immediately before insertion instead of preserving old IDs as durable references.

## Next Batch Procedure

1. Stop play mode before inserting. Creator Store insertions must happen in edit mode.
2. Source candidates with the direct helper, not the Codex MCP wrapper:
   `node tools/roblox_search_direct.js search_assets '{"query":"survival ui icon pack","max_results":5}'`.
3. For each accepted candidate, re-query Studio with the exact string `<asset name> <numeric asset id>`.
4. Insert through `Roblox_Studio.insert_from_creator_store` using the fresh `searchId`, the narrowest matching `objectTypes`, and a unique `assetName` such as `G018_Imported_BrokenCar_4675550604`.
5. Snapshot-diff Workspace before and after insertion. If the inserted primary asset is not the accepted candidate or is not design-usable, remove it and do not count it.
6. Move accepted roots under `Workspace.Map.ImportedAssets/<batch>` for placed world assets or `ReplicatedStorage.ImportedAssetLibrary/<batch>` for library templates.
7. Stamp the accepted root and visible descendants with:
   - `SourceAssetId=<actual inserted numeric id>`
   - `AssetManifestId=<batch-local id>`
   - `CreatorStoreOnly=true`
   - `ImportedVisibleAsset=true`
   - `PlacementRole=<story/gameplay role>`
8. Review imported executable content before release readiness. Useful scripts, animations, sounds, and modules may be kept only after review and rework into eggBreakers-owned services/controllers. Quarantine or disable code that remains uncontrolled, unsafe, noisy, or incompatible.
9. Run `AssetImportAuditService:AuditAndRepair({ mutate = true })`.
10. Run `AssetImportAuditService:ValidateReleaseCounts(500)` and record the honest count. Duplicates, catalog-only IDs, rejected inserts, hidden/quarantined visuals, and generated stand-ins do not count.

## Minimal Audit Probe

Use this read-only Studio probe before and after a batch:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local result = AssetImportAuditService:ValidateReleaseCounts(500)
return {
    passed = result.passed,
    failures = result.failures,
    counts = result.counts,
}
```

The 2026-05-31 pre-G027 reproduction returned `actuallyImportedAssets=24` and `releaseReadyVisibleAssets=24`.

The 2026-05-31 G027 batch inserted three Creator Store primaries through the authorized Studio path:

| SourceAssetId | Inserted root | Placement |
| --- | --- | --- |
| `8895193` | `G027_DinosaurNestEggs` | `Workspace.Map.ImportedAssets.G027_AssetBackedStoryBatch` |
| `12630982706` | `G027_PreHistoricPlantPack` | `Workspace.Map.ImportedAssets.G027_AssetBackedStoryBatch` |
| `110801640375836` | `G027_UIIconPack` | `Workspace.Map.ImportedAssets.G027_AssetBackedStoryBatch` |

After tagging, anchoring, script audit, and the UI icon false-positive rename (`Baseball_Bat` → `Bat_Icon`), live Studio reported `actuallyImportedAssets=26` and `releaseReadyVisibleAssets=26`. The release gate still fails honestly until 500 unique release-ready live assets are imported and proven.
