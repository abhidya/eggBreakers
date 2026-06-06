# Current Game Asset Inventory and Placement Storyboard

Generated: 2026-06-05

Scope: `eggBreakers3` live Studio session, runtime map after temporary simulation, Rojo-accepted source, custom asset-search MCP cache. This is an inventory/storyboard review; player-angle follow-up evidence was captured in `docs/assets/player-view-e2e-review.md` and did not pass signoff.

Implementation update, 2026-06-05:

- Added `StoryAssetPlacements` plus a `MapLayoutService:EnsureStoryAssetPlacements()` build pass.
- Live Studio verification after Rojo sync reported 15 tagged story placements, 15 imported-template placements, 0 fallback proxies, and 16 unique story source IDs.
- Runtime `Workspace.Map.Storyboards` now includes `Beat0_NurseryHatch`, `Beat1_FirstFoodWater`, `Beat4_JungleAmbush`, `Beat5_SwampDeltaLiveAssets`, `Beat6_RedstoneFossils`, `Beat7_ApocalypticCityMystery`, `Beat8_MountainNesting`, and the original `SwampDeltaOxygenFish`.
- All new placements remain marked `placed_pending_player_angle_review` / `NeedsPlayerAngleScreenshot=true`; this is placement proof, not final visual signoff.
- The open Studio save landed on `eggBreakers4.rbxl`; that saved placed state was mirrored into the requested target `eggBreakers3.rbxl` after a temp backup at `/tmp/eggBreakers3.before-story-assets.rbxl`.
- Disk audit of `eggBreakers3.rbxl` now reports `Workspace.Map` present, `placedTaggedRecords=3723`, and `storyboardRecords=42`.

## Evidence Summary

- Edit mode `Workspace` is intentionally sparse: only `Camera` and `Terrain` before simulation.
- Runtime `Workspace.Map` builds correctly with 14 folders: `BiomeDressing`, `FoodSources`, `WaterSources`, `NPCSpawns`, `Storyboards`, routes, spawns, zones, and boundary ring.
- Runtime `Workspace.Map` has 64 tagged visual roots, 63 visible, but only 23 have a `SourceAssetId`.
- Runtime `Workspace.Map` has only 1 unique live map `SourceAssetId`: `9634849118`. It is reused across all visible plant-patch imports.
- `ReplicatedStorage.ImportedAssetLibrary` has 104 tagged/library roots, 92 visible templates, and 60 unique `SourceAssetId`s. Most real inventory is therefore in the library, not placed in the current game map.
- Runtime `NPCs` has 12 visible NPC roots, with 2 unique source IDs: `412719275`, `646098924`.
- Staged dino library has 67 species folders, but 0 source-tagged roots in the audit.
- Runtime `Storyboards` has one storyboard: `SwampDeltaOxygenFish`. It is cache-only, proxy-based, and intentionally clears release-credit attributes.

## Missing From The Game Map

| Area / beat | Runtime status | Missing assets to place or swap in |
| --- | --- | --- |
| Beat 0 egg wakeup / NurseryGrove | `Workspace.Map.Nests` is empty; Nursery has food/meat visuals only. | Egg/nest visuals from library: `Imported_Egg_Nest`, `Imported_Nursery_Nest`, source IDs `240666886`, `104497410410577`. |
| Beat 1 food/water lesson | Food exists, but mostly repeated `9634849118` plant patch and source-less carcass templates. | Distinct starter fern `7979002756`; carnivore carcass/bones `6934081776`, `8846376590`, or asset-search candidate `2915304314`; water-edge lily/shoreline visuals. |
| Beat 2 FernPlains predator/prey | NPCs spawn, but FernPlains map dressing still has only one unique plant source. | Herd silhouettes and varied grass/tree/cover assets; wire staged Gallimimus/Triceratops/Velociraptor visuals to spawn beat. |
| Beat 3 growth reveal | No distinct growth asset found in map. | Growth sparkle/aura VFX candidate still needed; existing `CombatHitVFXTemplate` is combat-specific, not growth-specific. |
| Beat 4 JungleBasin ambush | JungleBasin has 6 visible roots, only `9634849118` as a unique source. | Vines/cover/ruins: cache candidate `11333953219`; library `G014B4_JungleBush`, `G014B6_JungleLog`, `G015_Import_ancient_jungle_ruins`, `G030_JungleFernPlant_14703400302`. |
| Beat 5 SwampDelta oxygen/fish | Storyboard exists, but all four intended source IDs are missing from live map. | Exact storyboard IDs missing: `543827347` Dead Swamp Tree, `708797531` Water Lily, `1725227984` Fish, `5434115710` Spinosaurus. Library alternates: `12598461005` Swamp Trees, `2523657735` Lily Pads, `4577166615` Fish School, playable/staged Spinosaurus. |
| Beat 6 RedstoneCanyon fossils | Redstone has 5 visible roots, only `9634849118` as a unique source. | Redstone arch/rock/fossil: `11239705094`, `12809476227`, `5663348866`, `705724826`, `G014B6_CanyonArch`. |
| Beat 7 ApocalypticCity | City has 3 visible roots and 0 unique source IDs in the map. | City ruin/wreck story assets: `509728826`, `10094924130`, `9213436305`, `18905581868`, `G014B6_BrokenConcreteWall`, `G014B3_OldRoadSign`. |
| MountainNestingCliffs / nest loop | No live tagged by-biome inventory showed for MountainNestingCliffs. | Cliff eggs/cave/nest assets: `13302250925`, `1903954980`, egg/nest IDs above. |

## Placement Storyboard

1. **Beat 0: Hatch At NurseryGrove**
   - Place `Imported_Nursery_Nest` / `Imported_Egg_Nest` in `Workspace.Map.Nests` near the Nursery spawn cluster around `NurseryGrove`.
   - Use `240666886` as the egg close-up prop and `104497410410577` as the wider nest/home prop.
   - Frame the first camera/player path from egg -> starter fern -> drinkable water.

2. **Beat 1: First Food And Water**
   - Replace source-less `FoodVisual_StarterPlant` clones at `NurseryStarterFern_*` with `Imported_Starter_Fern` (`7979002756`) or another distinct fern per cluster.
   - Replace source-less meat/cache parts with carcass/bone visuals: library `Imported_CarcassBones_6934081776`, `G031_CarnivoreMeatFood` (`8846376590`), or cache candidate `2915304314`.
   - Add lily/shoreline assets near `FernPlainsPond` and the Nursery edge so water reads before UI prompts.

3. **Beat 2: FernPlains Predator/Prey Choice**
   - Keep live NPC spawn logic, but stage visual beats around `FernPrey_*`, `FernPredator_01`, and `VelociraptorFernSpawn_01`.
   - Place plains tree/grass anchors from the library, then reserve a visible predator silhouette line from the treeline toward the carcass.
   - Do not count cloned grass duplicates as new release assets; diversify sources before release-gate claims.

4. **Beat 4: JungleBasin Ambush**
   - Place vines above the Jungle entry corridor and near `JunglePredator_01`.
   - Use `G014B6_JungleLog` and `G014B4_JungleBush` as cover, with `G015_Import_ancient_jungle_ruins` as the landmark.
   - Asset-search candidate `11333953219` is the cleanest new vine candidate from this pass.

5. **Beat 5: SwampDelta Oxygen/Fish**
   - Current `SwampDeltaOxygenFish` storyboard proxies should be swapped or overlaid with real assets after inspection.
   - Safe nodes: place lily pads at `SwampDelta_LilySafeNode_A/B/C`. Prefer exact `708797531`; library fallback `2523657735`.
   - Fish: place fish source visuals at `SwampDelta_FishCache_A/B/C`. Prefer exact `1725227984`; library fallback `4577166615`.
   - Apex warning: replace the slate proxy with `5434115710` after script/scale review, or use the staged/playable Spinosaurus if it is cleaner.
   - Swamp dressing: add `543827347` exact Dead Swamp Tree or library `12598461005` around the channel bends.

6. **Beat 6: RedstoneCanyon Trial**
   - Place `Imported_Redstone_Rock_Arch` (`11239705094`) at the Redstone gateway / `RedstoneArch` beat.
   - Place fossil/bone visuals near `RedstonePreyCarcass_*` and the canyon path: `5663348866`, `705724826`, or `2915304314`.
   - Use `12809476227` or `G014B6_CanyonArch` as larger canyon silhouettes after scale review.

7. **Beat 7: ApocalypticCity Mystery**
   - Place `G031_CityRuinsStructure` / `509728826` as the Old Eden approach landmark.
   - Place `Imported_Wrecked_Car` (`9213436305`) and rubble (`18905581868`) along `SwampDeltaCausewayToCity` and city street crossings.
   - Add road sign / concrete wall assets as navigation and danger framing, not just clutter.

8. **Beat 8: Mountain Nesting / Lineage**
   - Place `Imported_Cliff_Eggs` (`13302250925`) and `Imported_Mountain_Cave` (`1903954980`) in `MountainNestingCliffs`.
   - Tie cliff nest props to adult nesting UI and aerial/flying prey spawns.

## Priority Calls

1. First priority: move already-library assets into `Workspace.Map` so story beats stop relying on repeated `9634849118`.
2. Second priority: decide whether SwampDelta should keep the exact cached IDs or switch its source module to library-backed equivalents.
3. Third priority: create runtime storyboard roots for Beat 0, Beat 1, Beat 4, Beat 6, Beat 7, and MountainNestingCliffs; currently only Beat 5 has a runtime storyboard folder.
4. Fourth priority: run player-height screenshot review after placement. Until then, none of these assets should be called release-ready.
