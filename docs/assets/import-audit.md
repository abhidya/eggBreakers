# Import Audit

Generated source of truth: `ServerScriptService/Services/AssetImportAuditService.lua`.

## Asset states are separate

| State | Meaning |
| --- | --- |
| Cataloged SourceAssetIds | Unique numeric Creator Store IDs in `AssetManifest.SourceAssets` / manifest entries. Cataloged is not imported. |
| Actually Imported Assets | Unique SourceAssetIds found on live instances under `ReplicatedStorage.ImportedAssetLibrary` or `Workspace.Map.ImportedAssets`. |
| Audited Imported Assets | Imported assets whose script state is audited, sandboxed, review-queued, or quarantined. |
| Tagged Imported Assets | Imported instances carrying SourceAssetId, AssetManifestId, and CreatorStoreOnly metadata. |
| Placed Visible Assets | Imported assets present in the Workspace map or visibly marked as ImportedVisibleAsset. |
| Release Ready Visible Assets | Tagged, placed/visible imported assets with no unreviewed imported scripts. Reviewed, adapted, and stamped scripts may remain attached. |

## Current blocker

Catalog evidence alone must never satisfy the 500-asset requirement. Release validation must compare the live imported/release-ready count against 500 and fail while the live count is below target.

## Studio-side audit workflow

1. Run `AssetImportAuditService:AuditAndRepair({ mutate = true })` from a trusted Studio command context.
2. The service scans `ReplicatedStorage.ImportedAssetLibrary` and `Workspace.Map.ImportedAssets`.
3. It tags assets from manifest metadata where possible.
4. It preserves raw executable imports in a disabled review queue when the asset/root is explicitly marked `RawImportedScriptPreserved=true` or `ScriptReviewStatus="raw_preserved_pending_adaptation"`. Runtime `Script`/`LocalScript` objects are preserved with imported assets only when they are reviewed, adapted into eggBreakers-owned behavior, and stamped. Everything else is disabled/quarantined into `ReplicatedStorage.ImportedScriptQuarantine`.
5. It reports separate cataloged/imported/audited/tagged/placed/release-ready counts.

## Imported script preservation rule

Imported Roblox scripts are raw material, not default deletion targets. A runtime `Script` or `LocalScript` may stay with an imported asset only when it carries review metadata, adaptation metadata, and a stamp:

- review: `ImportedScriptAudited=true` or `ReviewedImportedScript=true`
- adaptation: `ImportedScriptAdapted=true`, `AdaptedIntoEggBreakers=true`, or `ScriptAdaptedTo="<owned service/controller>"`
- stamp: `ImportedScriptStamped=true`, or all of `ScriptAuditPurpose`, `ScriptSandboxStatus`, and `ImportedScriptOwner`

Unreviewed, unadapted, or unstamped executable scripts are either kept disabled in the raw-script review queue or quarantined. Imported `ModuleScript` objects also need the same review/adaptation/stamp fields plus `Sandboxed=true` before they are preserved. Reviewed/adapted/stamped scripts still need focused tests around their owned behavior before they can be treated as release-safe.

Known MCP limitation: the current external Studio MCP can import assets and return primary IDs, but does not expose a general instance attribute setter or model-tree/script inspector. The in-place Studio service above is required for authoritative tagging and script quarantine.
