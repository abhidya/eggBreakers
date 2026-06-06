# G020 Swamp Delta Storyboard Validation

Scope: Beat 5, `Swamp Delta Oxygen/Fish`.

## Built Slice

- Added `Workspace.Map.Storyboards.SwampDeltaOxygenFish` from source.
- Added three cache-backed lily oxygen safe-node proxies from asset `708797531`.
- Added three fish food sources in `SwampRiverFishRun` from asset `1725227984`.
- Added the Spinosaurus wake silhouette proxy from asset `5434115710`.
- Kept all storyboard proxies in `cache_only_pending_studio_asset_inspection`; they do not claim `ImportedVisibleAsset`.

## Asset Cache Updates

- Rejected asset `994374738`: oversized flat food visual panels blocked player-height swamp screenshots.
- Rejected asset `458900702`: Venusaur doll false positive for swamp flora/lily usage.
- Rejected asset `75850368020021`: Monet painting false positive for diegetic water-lily gameplay nodes.

## Source Fixes From Screenshot Review

- Oversized thin imported food panels are rejected before they can attach to food visuals.
- Failed imported food visuals fall back to generated readable foliage without claiming import credit.
- Procedural shallow water markers are now low-obstruction visible affordances and do not cast shadows.

## Studio Evidence

The active Studio scene did not Rojo-sync the latest source automatically, so the source build was verified with Rojo and the validation scene was assembled/probed through Studio MCP. Studio proof found:

- `safeCount = 3`
- `fishCount = 3`
- `fishInside = 3`
- `deferredCount = 5`
- `apexSource = 5434115710`
- `validationState = cache_only_pending_studio_asset_inspection`

## Screenshot Contract

The custom asset-search playable-space review passed with `signed_off_with_risks`.

Captured IDs:

- `eggbreakers_swamp_delta_oxygen_fish_overhead`
- `eggbreakers_swamp_delta_oxygen_fish_entry`
- `eggbreakers_swamp_delta_oxygen_fish_nw_player`
- `eggbreakers_swamp_delta_oxygen_fish_nw_reverse`
- `eggbreakers_swamp_delta_oxygen_fish_ne_player`
- `eggbreakers_swamp_delta_oxygen_fish_ne_reverse`
- `eggbreakers_swamp_delta_oxygen_fish_sw_player`
- `eggbreakers_swamp_delta_oxygen_fish_sw_reverse`
- `eggbreakers_swamp_delta_oxygen_fish_se_player`
- `eggbreakers_swamp_delta_oxygen_fish_se_reverse`

## Remaining Risks

- The beat is source-valid and player-angle reviewed, but the real Creator Store geometry/script insertion is still pending.
- Entry, NE reverse, and SE player views are still water-heavy and show overhead rock or rectangular terrain/water geometry. This is a visual-composition risk for a later polish pass, not a cache/storyboard blocker.
- Full in-Studio all-category TestRunner was not run in this pass.
