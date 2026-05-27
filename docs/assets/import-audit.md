# Import Audit

Generated source of truth: `ServerScriptService/Services/AssetImportAuditService.lua`.

## Asset states are separate

| State | Meaning |
| --- | --- |
| Cataloged SourceAssetIds | Unique numeric Creator Store IDs in `AssetManifest.SourceAssets` / manifest entries. Cataloged is not imported. |
| Actually Imported Assets | Unique SourceAssetIds found on live instances under `ReplicatedStorage.ImportedAssetLibrary` or `Workspace.Map.ImportedAssets`. |
| Audited Imported Assets | Imported assets whose script state is audited/sandboxed/removed. |
| Tagged Imported Assets | Imported instances carrying SourceAssetId, AssetManifestId, and CreatorStoreOnly metadata. |
| Placed Visible Assets | Imported assets present in the Workspace map or visibly marked as ImportedVisibleAsset. |
| Release Ready Visible Assets | Tagged, placed/visible imported assets with no unquarantined imported scripts. |

## Current blocker

Catalog evidence alone must never satisfy the 500-asset requirement. Release validation must compare the live imported/release-ready count against 500 and fail while the live count is below target.

## Studio-side audit workflow

1. Run `AssetImportAuditService:AuditAndRepair({ mutate = true })` from a trusted Studio command context.
2. The service scans `ReplicatedStorage.ImportedAssetLibrary` and `Workspace.Map.ImportedAssets`.
3. It tags assets from manifest metadata where possible.
4. It disables/quarantines executable imported `Script`/`LocalScript` objects into `ReplicatedStorage.ImportedScriptQuarantine`.
5. It reports separate cataloged/imported/audited/tagged/placed/release-ready counts.

Known MCP limitation: the current external Studio MCP can import assets and return primary IDs, but does not expose a general instance attribute setter or model-tree/script inspector. The in-place Studio service above is required for authoritative tagging and script quarantine.
