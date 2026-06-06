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

## Story/Test Coverage Impact

- Beat 0 now has a live nest/egg source (`8895193`) that matches `StoryboardBeatValidation.server` imported egg expectations, but release proof still needs save/reopen persistence and starter-specific screenshots.
- Beat 1 now has a live first-forage plant source (`12630982706`), but herbivore food remains blocked until the placed gameplay target is proven with saved Studio state and mobile/client action proof.
- HUD icon source material (`110801640375836`) supports compact affordance work, but `ClientHUDTests.client.lua` remains the source-level proof; no G018 live-proof attribute is satisfied by this batch alone.
- `AssetImportAuditStateTests.lua` now includes a named G027 regression that fixtures the nest, plant, and UI roots with their actual SourceAssetIds and verifies each remains release-ready when correctly tagged.
- `HatchUITests.client.lua` now asserts the default hatch selector renders exactly the four curated starters that this batch is meant to support: Coelophysis, Parasaurolophus, Utahraptor, and Citipati.

## E2E Evidence

Live Studio E2E after refreshing stale open-Studio service caches reported `36/38` passing. The only remaining E2E failures were the honest release gates at `26/500`, not hatch/movement/eating/rest/age/dying regressions.

## Code Fix Captured

The UI icon pack originally quarantined because an imported child named `Baseball_Bat` matched the old low-quality substring heuristic for `ball`. Source now treats `ball` as a standalone token for glowing-ball quarantine, and a regression fixture proves `Baseball_Bat` stays release-eligible while `Glowing_Ball` is still excluded.

The live inserted icon child was renamed to `Bat_Icon` so the currently-open Studio require cache also reports the batch clean.
