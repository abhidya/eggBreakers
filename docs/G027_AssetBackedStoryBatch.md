# G027 Asset-Backed Story Batch

Date: 2026-05-31

## Goal

Close a concrete slice of the storyboard implementation gap by inserting real Creator Store assets for hatch/nest, first forage, and HUD icon source material instead of leaving those beats as catalog-only candidates.

## Inserted Assets

| Beat | SourceAssetId | Root | Role | Result |
| --- | --- | --- | --- | --- |
| Beat 0 hatch/nest | `8895193` | `G027_DinosaurNestEggs` | Nest | Inserted, tagged, visible, script-free, release-ready |
| Beat 1 first forage | `12630982706` | `G027_PreHistoricPlantPack` | FoliageFoodSource | Inserted, tagged, visible, script-free, release-ready |
| HUD affordance source | `110801640375836` | `G027_UIIconPack` | UIIconSource | Inserted, tagged, visible, script-free, release-ready after rename |

All three roots live under `Workspace.Map.ImportedAssets.G027_AssetBackedStoryBatch` in the active Studio place. The MCP has no save-place operation, so this live placement must be saved manually in Studio to survive restart.

## Audit Evidence

Live `AssetImportAuditService:AuditAndRepair({ mutate = true })` after the batch:

| Count | Value |
| --- | ---: |
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 26 |
| Audited Imported Assets | 26 |
| Tagged Imported Assets | 26 |
| Placed Visible Assets | 26 |
| Release Ready Visible Assets | 26 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Quality Excluded Assets | 0 |

`ValidateReleaseCounts(500)` still fails, as intended, with:

- `actuallyImportedAssets=26; expected at least 500`
- `releaseReadyVisibleAssets=26; expected at least 500`

## Code Fix Captured

The UI icon pack originally quarantined because an imported child named `Baseball_Bat` matched the old low-quality substring heuristic for `ball`. Source now treats `ball` as a standalone token for glowing-ball quarantine, and a regression fixture proves `Baseball_Bat` stays release-eligible while `Glowing_Ball` is still excluded.

The live inserted icon child was renamed to `Bat_Icon` so the currently-open Studio require cache also reports the batch clean.
