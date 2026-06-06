# Player-View E2E Review

Generated: 2026-06-05

Scope: `eggBreakers3` / open Studio session for `eggBreakers4.rbxl`, after story asset placement source was synced and saved/mirrored into `eggBreakers3.rbxl`.

Verdict: `not signed off`

Validator result: `validate_playable_space_review` returned `passed=false`, `verdict=not_signed_off`, with 6 spaces reviewed, 9 screenshots, and 7 unresolved blocker findings.

## What Was Played

- Started Studio Play mode through Studio MCP after clearing a stuck visual `Stop` state.
- Manually clicked the hatch prompt in the live viewport.
- Confirmed the hatch overlay cleared and the live HUD switched to a playable dinosaur state.
- Installed a temporary Studio-only MCP server runner, used it for safe built-in teleports, then removed `ServerScriptService.MCPServerCodeRunner` before ending.

## Screenshot Evidence

| Capture | Path | Result |
| --- | --- | --- |
| Live hatch prompt | `docs/assets/player-view-screenshots/eggBreakers_live_play_spawn_prompt.png` | Play mode visible with hatch prompt and HUD. |
| Manual hatch input | `docs/assets/player-view-screenshots/eggBreakers_live_after_manual_hatch_taps.png` | Hatch meter responds to real viewport clicks. |
| Hatched state | `docs/assets/player-view-screenshots/eggBreakers_live_e2e_hatched_restart.png` | Overlay clears; playable dinosaur/HUD visible. |
| Hatched pivot restart | `docs/assets/player-view-screenshots/eggBreakers_live_e2e_hatched_pivot.png` | Valid live state, but camera is clipped into dinosaur body. |
| Nursery Grove | `docs/assets/player-view-screenshots/eggBreakers_nursery_grove_player_nest_pivot.png` | Player-height view captured, but dinosaur body and default helper/proxy block occlude the intended nest/food beat. |
| Jungle Basin | `docs/assets/player-view-screenshots/eggBreakers_jungle_basin_player_ruins_pivot.png` | Does not show Jungle ruins/log beat; view remains nursery-like with a large black occluder. |
| Swamp Delta | `docs/assets/player-view-screenshots/eggBreakers_swamp_delta_player_spinosaurus_pivot.png` | Teleport reaches a wet/flat area, but lily/log/Spinosaurus assets are not readable. |
| Redstone Canyon | `docs/assets/player-view-screenshots/eggBreakers_redstone_canyon_player_fossils_pivot.png` | Does not read as Redstone Canyon; fossils/arch are absent from the player angle. |
| Old Eden / City | `docs/assets/player-view-screenshots/eggBreakers_old_eden_player_city_pivot.png` | Does not show city ruin/car/sign beat; view snaps back to the nursery-like corridor. |
| Mountain Nesting | `docs/assets/player-view-screenshots/eggBreakers_mountain_nesting_player_cliff_pivot.png` | Does not show mountain cave/nest beat; view snaps back to the same corridor. |

## Findings

- **Blocker: storyboard spaces are not player-angle signed off.** Live Play proves hatching works, but the placed story assets are not consistently visible/readable from the player camera.
- **Blocker: camera/body occlusion.** The playable dinosaur frequently fills the camera, and a large dark/black block plus blue helper/proxy geometry occludes the scene.
- **Blocker: route teleport/camera validation is unreliable.** Server-side teleports returned success for Jungle, City, and Mountain, but the player camera did not show those spaces.
- **Blocker: several target beats remain visually absent from player height.** Swamp, Redstone, City, and Mountain captures do not show the intended placed assets well enough for acceptance.
- **Risk: prior release-gate logs remain noisy.** Existing final-gate checks still report 500-asset proof gaps, placeholder/helper warnings, and older placement-test fixture failures unrelated to the new placement layer.

## Next Fix Pass

1. Fix third-person camera distance/collision around imported dinosaur visuals.
2. Remove or hide visible helper/proxy blocks from player routes.
3. Add a supported debug travel/waypoint command for live play validation instead of temporary runner teleports.
4. Reposition or rescale each story placement until it is visible from a normal player path.
5. Recapture the same six spaces and keep verdict at `not signed off` until every beat is readable from player height.
