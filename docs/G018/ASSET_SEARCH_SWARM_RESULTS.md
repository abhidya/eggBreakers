# G018 Asset Search Swarm Results

Date: 2026-05-31

Status: SEARCH COMPLETE / RAW INSERTION BLOCKED / AUTHORIZED STUDIO SEARCH BRIDGE VERIFIED

This pass used the Rust Roblox search MCP directly through `tools/roblox_search_direct.js`, which calls Creator Store Toolbox Service v2 via `search_assets`. Search is parallel-safe; the batch below was run as independent concurrent queries rather than serial Studio search.

Insertion attempt: a small script-free candidate batch was attempted in the active `eggBreakers3.rbxl` Studio session with `InsertService:LoadAsset`. Every selected asset returned `User is not authorized to access Asset.` The empty batch marker was removed immediately and `AssetImportAuditService:AuditAndRepair({ mutate = true })` reported the live release-ready count back at `24`, so no fake import count was kept.

Follow-up diagnosis on 2026-05-31 verified the practical workaround: do not use raw `InsertService:LoadAsset`. Re-query accepted `Roblox_Search` candidates through `Roblox_Studio.search_creator_store` with the exact string `<asset name> <asset id>`, then insert from the returned Studio `searchId` using `Roblox_Studio.insert_from_creator_store`. See `docs/assets/authorized-creator-store-import.md`.

## Commands Run

```sh
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"rigged dinosaur models raptor triceratops tyrannosaurus","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"low poly fish school aquatic fish water","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"dinosaur nest eggs fossil bones prehistoric","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"apocalypse city ruins wrecked car rubble low poly","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"low poly fern bush plant food mesh","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"animal carcass meat bone raw food mesh","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"dinosaur roar monster roar sound effect","limit":8}'
ROBLOX_SEARCH_MCP_BIN=/Users/abdulrehmanbhidya/PycharmProjects/roblox-studio-rust-mcp-server/target/release/rbx-studio-mcp node tools/roblox_search_direct.js search_assets '{"query":"survival ui icon pack compass marker waypoint","limit":8}'
```

## Accepted Insertion Queue

| Priority | Asset | Search result | Intended use | Script review | Notes |
| --- | --- | --- | --- | --- | --- |
| P0 | `Raptor Character!` `9371720275` | Model, 129 MeshParts, 24 animations, 8 scripts | Best candidate to close raptor animation/player/NPC readability if review passes | Required | High-value because it includes animations and executable behavior. Review the scripts first, then rework useful movement/animation/roar logic so it matches eggBreakers storyboard beats and server authority. |
| P0 | `VelociRaptor Blue` `8585959958` | Model, 1 MeshPart, 0 scripts | Low-risk static raptor visual fallback | No executable scripts reported | Good fallback for visual silhouettes, but likely IP-themed and not animation-ready. |
| P0 | `Mulet fish Mesh` `6923368893` | MeshPart, 0 scripts | Fish school source mesh for `FishService`/water Beat 5 | No executable scripts reported | Best low-risk fish mesh from the batch. |
| P0 | `Broken Car` `4675550604` | MeshPart, 0 scripts | Old Eden / ApocalypticCity ruin dressing | No executable scripts reported | Small city identity prop; pair with existing rubble/wreck manifest entries. |
| P1 | `Golden Egg of the Wise` `479864923` | MeshPart, 0 scripts | Egg/nest visual candidate | No executable scripts reported | Not dinosaur-specific, but readable as egg in hatch/nest beats. |
| P1 | `wood pick up (branch)` `1679857865` | Model, 0 scripts | Nest material / branch clutter | No executable scripts reported | Works as nest scatter if scaled and grouped with egg. |
| P1 | `Old Roblox-Styled Character Sounds Pack` `15587274275` | Model, 200 votes, 94 percent up, 2 scripts | Possible owned sound-pack source for action/roar placeholders | Required | Strong rating signal. Review the scripts and rework any useful sound-routing behavior into `SoundLibrary`/client SFX instead of loose autoplay behavior. |
| P2 | `Mesh Ai System` `11882451647` | Model, 45 animations, 5 audio, 1 script | Reference implementation for creature AI/animation patterns | Required | Review as candidate source code. If useful, adapt parts into eggBreakers-owned NPC/animation services with tests, rather than treating it as forbidden just because it is executable. |

## Rejected / Deferred Results

| Result | Reason |
| --- | --- |
| Jurassic Park/World named MeshParts such as `981164890`, `984698485`, `492443960` | Potential IP risk; static mesh-only in this result format; use only for private prototype fallback. |
| Most `animal carcass meat bone raw food mesh` results | Search was noisy: humanoid body parts, decals, unrelated SFX. No clean carcass model emerged in this batch. |
| `low poly fern bush plant food mesh` top results | Search was noisy: audio, hair mesh, decals, and an old generic `Plants` model. Existing candidate doc still has stronger foliage candidates. |
| `survival ui icon pack compass marker waypoint` results | Search was noisy and mostly unrelated mesh/decals/audio. Use repo-owned HUD cue work or the previously identified Location Marker System as reference instead. |
| `Pack poly by me` `4596418748` | Huge 643 MeshParts, 14 scripts. Deferred only because it is too broad for a quick insertion; scripts should be reviewed and mined for useful behavior before any disable/quarantine decision. |

## Insertion Blocker

`InsertService:LoadAsset` in the active Studio session failed for all attempted script-free IDs:

- `8585959958`
- `6923368893`
- `4675550604`
- `1679857865`
- `479864923`

All returned `User is not authorized to access Asset.`

Next insertion path should use the Roblox Studio Creator Store insertion/plugin path that has user authority. Exact candidate searches verified as Studio-resolvable:

| Candidate | Studio search query | Studio object types |
| --- | --- | --- |
| `Broken Car` `4675550604` | `Broken Car 4675550604` | `car`, `vehicle` |
| `Mulet fish Mesh` `6923368893` | `Mulet fish Mesh 6923368893` | `fish`, `animal`, `sea creature` first; ignore unrelated returned types unless insertion proves otherwise |
| `VelociRaptor Blue` `8585959958` | `VelociRaptor Blue 8585959958` | `dinosaur`, `creature` first |

Then immediately run:

1. Move accepted roots under `Workspace.Map.ImportedAssets/G018SearchBatchNNN` or `ReplicatedStorage.ImportedAssetLibrary`.
2. Stamp `SourceAssetId`, `AssetManifestId`, `CreatorStoreOnly`, `ImportedVisibleAsset`, `ScriptsAudited`, and `PlacementRole`.
3. Review executable scripts, identify useful behavior, and rework/adapt it under eggBreakers services/controllers; disable or quarantine only code that conflicts with the game design, authority model, performance budget, or safety tests.
4. Run `AssetImportAuditService:AuditAndRepair({ mutate = true })`.
5. Run `AssetImportAuditService:ValidateReleaseCounts(500)` and record the honest remaining count.

## Systems To Wire After Insertion

| System | Asset hook |
| --- | --- |
| `StagedMeshLibrary` / character visuals | Raptor rig/mesh candidate roots by species folder name. |
| `FishService` | Fish mesh template for generated fish schools inside valid `SwimWater`. |
| `MapLayoutService` / `WorldDressingService` | Broken car, rubble, branch, egg/nest visual roots placed by biome and grounded against live terrain. |
| `SoundLibrary` / client SFX | Reviewed roar/action sounds and any useful imported sound scripts reworked into repo-owned sound categories. |
| `HUDController` | Keep current repo-owned story cue; external marker UI is reference-only unless a clean Creator Store module appears. |
