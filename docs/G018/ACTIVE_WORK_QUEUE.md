# G018 Active Work Queue

Rule: no final PASS until live E2E, fresh all-category TestRunner, mobile/client proof, RBXL persistence, publish-blocker scan, and 500 release-ready imported visible assets pass.
Rule: G016 owner complaints and release blockers remain authoritative until fresh evidence supersedes them.
Rule: Creator Store / Creator Marketplace assets are primary; GenerationService remains authoring fallback only and never counts as release-ready imported assets by itself.
Rule: imported Creator Store scripts are allowed only when reviewed and owned for dynamic asset behavior; executable imports need source review, sandbox/authority checks, tests, and integration proof before release readiness.
Rule: use `Roblox_Studio` MCP for `eggBreakers2.rbxl` live place control/inspection/build/play; use `Roblox_Search` MCP only for the separate `place1` legacy plugin asset search/rating/preview lane. Do not use `Roblox_Studio.search_creator_store` for asset sourcing.

## W0A — Staged dino visual blocker
Status: SOURCE FIXED / LIVE PROVEN
Evidence: `CharacterVisualService` keeps rig helper parts (`RootPart`, `HumanoidRootPart`, hitbox/collision/bounds/helper names) invisible and non-colliding while preserving visible mesh body parts. Studio patch-only `CharacterVisualServiceTests.server` passed `11/11`. Live `eggBreakers2.rbxl` Play inspection found player visual folder present, `visibleParts=7`, `helperVisible=0`, `largeVisibleNonHelper=0`; screenshot `wave0_live_player_visual_after_helper_fix` showed no giant opaque helper box around the player dinosaur.
Next gate: keep this regression in the focused suite and re-run after any character/NPC visual sanitizer changes.

## W0B — Beats 0-2 next parallel lanes
Status: SOURCE IMPROVED / LIVE SMOKED
Evidence: Wave 0 swarm slices integrated. `MapLayoutService` now creates richer visible child affordance clusters for hidden food query parts, clamps Nursery/FernPlains fallback canopies away from oversized visible block silhouettes, and `FoodWaterService` dims/restores all affordance descendants. `NPCSpawnService` prunes parentless records and continues after one spawn failure. Mobile guidance now separates 80-stud sensed targets from 14-stud actionable Snack/Drink and removes the fake up-arrow cue. Source checks passed: scoped `luac`, `git diff --check`, and `rojo build default.project.json --output /tmp/eggBreakers-wave0-integrated.rbxl`. Fresh-clone Studio probes proved food depletion visuals, canopy/food readability, NPC spawn robustness, and mobile scent cue behavior. Live Play smoke found `food=62`, `affordances=186`, `foodAffordanceFailures=0`, `badCanopies=0`, `helperVisible=0`, `npcs=15`; screenshot `wave0_integrated_live_readability` shows no giant block canopy and no fake up-arrow target cue.
Continuation evidence: hatch UI prompt/meter moved above mobile controls; screenshot `wave0_hatch_ui_clears_mobile_controls` proves the bottom controls are no longer covered. `NPCSpawnService:PrepareNPCModel` now hides staged NPC helper roots/colliders with regression coverage. Remaining directional feedback arrows were removed from Eat/Drink and Swim fallback cues.
Non-search continuation evidence: `NPCService` now prunes parentless records inside `TickNPCs`, stamps locomotion mode, and recognizes staged `RootPart` + `AnimationController` rigs as bounded `KinematicRootStep` movers. Studio fresh-clone probe proved `movedX=8.0`, `teleported=false`, `staleBefore=2`, `staleAfter=1`, `rootT=1.0`, and `bodyVisible=true`. Staged MeshPart spawn proof now covers the `Apex` -> staged `Tyrannosaurus` path through a private test staging root with `resolvedPrivate=true`, `ok=true`, `meshCount=1`, `rootHidden=true`, `helperAttr=true`, `bodyVisible=true`, and `source=probe-staged-mesh`. Client action guidance now has direct module coverage and Studio proof for sensed-only far targets versus actionable nearby targets.
Worker C source assertions added `StoryboardBeatValidation.lua` for Beat 0-2 visual acceptance: staged baby dino MeshPart/no helper box, imported egg/nest marker when source exists, readable imported-or-approved-fallback starter food/carcass classification, and staged prey/predator MeshPart NPCs. Static syntax check passed with `luac -p src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua`.
Worker source continuation added Beat 3-8 acceptance assertions: growth stage/visual scale payload, JungleBasin predator/call source contract, fish schools only in valid swim water, apex event warning attributes, invisible Old Eden city discovery volumes, and adult nest egg/home state. Audit recorded in `docs/G018/STORY_BEAT_COVERAGE_AUDIT.md`.
Search/import contract: all asset sourcing must use `Roblox_Search.search_assets` and `preview_asset` in the separate `place1` session only. The Rust legacy fork is filtered to expose only those two tools. On any `Roblox_Search` failure, asset sourcing blocks and waits for manual `place1` plugin toggle. Accepted assets may then be inserted/probed in `eggBreakers2` through `Roblox_Studio`; `Roblox_Studio.search_creator_store` is forbidden for sourcing. Dynamic imported scripts may be kept only after explicit source review, ownership assignment, sandbox/authority checks, focused tests, and integration proof.
Next gate: prove `Roblox_Search` asset-lane health with `search_assets` or `preview_asset` only. Current provisional store candidates are `11611657675` for fern starter food, `8895193` for nest/egg, and `2915304314` for scaled bones/fossil dressing only. Do not replace procedural fallback affordances with rolled/generated release visuals; resume rated search for meat/carcass and scent/waypoint assets when `place1` responds, then import accepted candidates into `eggBreakers2` for visual proof before wiring.

## E001 — Shared profile/stat/UI plumbing
Status: SOURCE FIXING
Evidence: species category/profile/movement/oxygen payload and HUD oxygen/profile guidance added; needs fresh Studio TestRunner and client proof.
Next gate: `G018EcosystemProfileTests` plus live HUD/mobile proof.

## E002 — Fish schools and water integrity
Status: TODO
Evidence: no fish school service or live water-volume proof yet.
Next gate: add fish-school placement/runtime tests and live water integrity proof.

## E003 — Grazing/herding/apex events
Status: TODO
Evidence: metadata exists for grazing/herding/apex categories, but behavior/event systems are not live-proven.
Next gate: source tests + live E2E for coordinated herd motion and apex event gating.

## E004 — Final QA and publish blockers
Status: BLOCKED
Evidence: local scan found no `9922699889` matches in rbxl strings/manifest, but final gate still requires fresh Studio proof attributes and 500 release-ready assets.
Next gate: run Studio TestRunner, save/reopen audit, mobile/client proof, and asset count validation.
