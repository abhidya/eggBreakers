# Wave 0 Swarm Tasks

Coordination rules:
- Leader owns `Roblox_Studio` MCP for `eggBreakers2.rbxl` live play/inspection/screenshots.
- Leader owns `Roblox_Search` MCP for `place1` legacy rated asset search/preview only.
- Workers must not use `Roblox_Studio.search_creator_store`.
- If `Roblox_Search.search_assets` or `preview_asset` flakes, leader blocks the asset-search lane and asks user to toggle the `place1` plugin.
- Creator Store imports are primary. Procedural/generated visuals are temporary gameplay fallbacks only when no searched/importable asset is available and validated.
- Workers run in worktrees and return patches/reports; leader integrates only reviewed work.

Search recovery:
- If the Codex `mcp__Roblox_Search` tool reports `Transport closed` but the `place1` plugin is still polling, use `node tools/roblox_search_direct.js <tool> '<json>'`.
- This helper launches the same `rbx-studio-mcp --stdio` binary and preserves the same rated `Roblox_Search.search_assets` / `preview_asset` source; it is not Studio creator-store search.
- The Rust legacy fork is intentionally filtered to expose only `search_assets` and `preview_asset`; no run-code, screenshot, write-script, or health-state tools are enabled through the `Roblox_Search` MCP profile.
- The helper must run outside the sandbox because the Rust MCP binary can panic inside sandbox network config lookup.

## Current Proven Fix

`W0A` staged dino visual blocker:
- Source fix in `CharacterVisualService`: rig helper parts remain invisible/non-colliding.
- Regression in `CharacterVisualServiceTests`: huge `RootPart` stays invisible, renderable body stays visible.
- Studio test proof: `CharacterVisualServiceTests.server total=11 passed=11 failed=0`.
- Live Play proof: player visual folder present, `visibleParts=7`, `helperVisible=0`, `largeVisibleNonHelper=0`.

## Open Swarm Queue

### T001 — Nursery/FernPlains Readability Audit
Owner: worker
Status: INTEGRATED
Scope: read-only first; propose narrowly-scoped edits only if obvious.
Files: `WorldDressingService.lua`, `WorldTerrainBuilder.lua`, `MapLayoutService.lua`, `docs/StoryModeStoryboard.md`.
Goal: identify why live screenshot still reads as flat/underdressed with oversized/simple tree blocks and weak food readability.
Deliverable: ranked fixes with exact files/functions/tests.
Findings:
- `WorldDressingService` is ready but not wired by default; imported dressing must be invoked for Nursery/FernPlains.
- Procedural fallback trees use visible block canopies and produce the oversized/simple silhouette problem.
- Food query helpers stay invisible, but visible children are too primitive to read as fern/meat.
- Existing tests count tags/attributes but do not enforce screenshot readability.
Next implementation slice:
- Integrated readability test rejecting oversized visible block fallback canopies in Nursery/FernPlains.
- Integrated fallback fix: Nursery/FernPlains procedural canopies are now smaller non-block silhouettes until imported dressing replaces them.

### T002 — Food/Water Interaction Quality Plan
Owner: worker
Status: INTEGRATED
Scope: read-only; no asset search.
Files: `MapLayoutService.lua`, `FoodWaterService.lua`, `WaterService.lua`, `SenseGuideController.lua`, `MobileControlsController.lua`.
Goal: map current food/water targets, tags, restore/deplete flow, UI affordances, and what must change so food/water are obvious in Beats 0-1.
Deliverable: implementation plan + test targets.
Findings:
- Hidden query part plus visible child split is correct, but visible child needs richer affordance parts.
- Depletion should dim/restore all visible affordance descendants, not a single part.
- `RequestDrink` should validate through `WaterService:IsValidDrinkableWater`.
- SenseGuide should highlight visible affordance descendants, not invisible query helpers.
Next implementation slice:
- Integrated richer fern/carcass child affordance clusters.
- Integrated `FoodWaterService` depletion/restore across all marked visible affordance descendants.
- Integrated placement/integration regressions for visible non-`FoodSource` affordance children.

### T003 — NPC Visual/Locomotion Gap
Owner: worker
Status: INTEGRATED
Scope: read-only; no Studio MCP.
Files: `NPCSpawnService.lua`, `NPCService.lua`, `NPCAnimationService.lua`, `StagedMeshLibrary.lua`, `SpeciesConfig.lua`.
Goal: explain why live `NPCs` folder showed no child models after Play inspection despite runtime NPC assets/tag counts, and what must be verified for real mesh NPCs + non-teleport locomotion.
Deliverable: failure hypotheses + focused probes/tests.
Findings:
- NPC spawn can break on the first missing imported/staged model and leave the folder underpopulated.
- `NPCService.NPCs` can retain stale/destroyed/parentless records and mask an empty `Workspace.NPCs`.
- Spawn prep anchors all parts; locomotion uses `Humanoid:MoveTo` only with `HumanoidRootPart`, while staged rigs likely have `RootPart` plus `AnimationController`, so they fall back to `PivotTo`.
- Current tests use Part-only mocks and do not prove MeshParts, humanoid/root wiring, animation readiness, or non-teleport movement.
Next implementation slice:
- Integrated stale parentless record pruning before active counts.
- Integrated spawn loop continuation after one failed model/spawn and regression probes.

### T004 — HUD/Sense Guide UX Audit
Owner: worker
Status: INTEGRATED
Scope: read-only; no asset search.
Files: `SenseGuideController.lua`, `HUDController.lua`, `MobileControlsController.lua`, `ClientBootstrap.client.lua`, `docs/StoryModeStoryboard.md`.
Goal: evaluate misleading arrow/distance/target affordance and propose diet-aware scent/sense pulse improvements without popups.
Deliverable: UI changes + client tests.
Findings:
- Mobile target text uses `⬆`, which reads as direction even though it is only a generic target hint.
- Client scans 80 studs but action works at 14 studs, so `Snack/Drink` can appear actionable too early.
- Icon vocabulary diverges across SenseGuide/HUD/ClientBootstrap and can show carnivore food as apple.
- Mobile guidance does not reuse SenseGuide's dominant hunger/thirst preference.
Next implementation slice:
- Integrated no-arrow scent cue, sensed-vs-actionable mobile state split, diet-aware icons, and client tests.

### Integrated Verification
- Static: scoped `luac -p` passed for touched Lua files.
- Static: `git diff --check` passed.
- Build: `rojo build default.project.json --output /tmp/eggBreakers-wave0-integrated.rbxl` passed.
- Studio edit-mode TestRunner caveat: existing service require cache was stale, so focused cloned test modules loaded but cached old service modules and produced false failures for newly changed services.
- Fresh-clone Studio probes: `FoodWaterService` dim/restore passed (`leaf=0.75`, `frond=0.75`, restored `0.10/0.25`); `MapLayoutService` readability passed (`canopies=6`, `badCanopies=0`, `food=63`, `affordanceFailures=0`); `NPCSpawnService` robustness passed (`pruned=1`, `active=2`, `calls=3`, `failures=1`); mobile scent cue passed (`food=✨ 🌿 12m`, `distant=〰 🍖 42m`, `arrowFree=true`).
- Live Play smoke: `food=62`, `affordances=186`, `foodAffordanceFailures=0`, `badCanopies=0`, `helperVisible=0`, `npcs=15`.
- Live screenshot: `wave0_integrated_live_readability`.
- Continuation live proof: screenshot `wave0_hatch_ui_clears_mobile_controls` shows hatch prompt/meter now clear the bottom mobile controls.
- Follow-up probes: `NPCSpawnService:PrepareNPCModel` hides staged NPC `RootPart` helper while preserving visible `MeshPart` body; client source no longer contains `↗ 🍎 💧` or `↗ 💧`, and `UpdateWaypoint` API docs include the `diet` parameter.

### T006 — Mobile/Sense Regression Review
Owner: worker
Status: REPORTED / PATCHED
Findings:
- Eat/Drink no-target feedback still used a diagonal arrow.
- Swim no-water feedback still used a diagonal arrow.
- `UpdateWaypoint` API comment omitted the new `diet` parameter.
- Coverage still needs a direct `ClientBootstrap:UpdateActionGuidance` client test for sensed-vs-actionable behavior.
Leader action:
- Replaced no-target feedback with non-directional `◌` cues.
- Updated API comment.
- Added hatch prompt/mobile clearance regression and verified screenshot.

### T007 — NPC Visual Persistence Review
Owner: worker
Status: REPORTED / PARTIAL PATCHED
Findings:
- NPC staged clones did not share the player helper transparency rule, so visible `RootPart`/hitbox helpers could reintroduce the giant-box bug for NPCs.
- Live population tests still do not prove MeshPart dinosaurs when staged assets are available.
- Non-teleport locomotion for `RootPart` + `AnimationController` rigs remains unproven.
Leader action:
- `NPCSpawnService:PrepareNPCModel` now hides helper/root/collider parts and marks them `NPCInvisibleRigHelper`.
- Added placement regression for staged NPC helper root invisibility.
Remaining gate:
- Add staged MeshPart population proof and locomotion mode proof.

### T008 — Asset Replacement Plan
Owner: worker
Status: REPORTED / SEARCH PARTIALLY VALIDATED / BLOCKED AGAIN
Rated-search queues:
- Fern/vegetation: `low poly plants pack`, `fern low poly`, `prehistoric fern`, `jungle fern plant`, `low poly bush`.
- Meat/carcass: `animal carcass dead deer ribcage carrion meat`, `raw meat haunch leg bone drumstick`, `raw meat steak food pack meshes`, `animal carcass bones remains`.
- Scent/UX: `scent trail particles`, `survival ui icon pack`, `food smell particle`, `location marker offscreen indicator arrow`.
- Nursery dressing: `dinosaur egg nest model`, `egg nest`, `low poly forest pack`, `prehistoric plants fern`.
- NPC substitutions: prefer existing `Workspace.dinosaur` staged mesh mappings first; search only if a required role/species has no acceptable staged substitute.
Current candidate decisions:
- Fern/foliage: provisional accept `11611657675` (`Fern`), Model with one MeshPart, preview size `17.6 x 8.5 x 17.3`; best current real fern candidate, needs eggBreakers2 visual import proof before replacing procedural starter food.
- Fern/foliage: weak/reject `124212560862962` (`Fern clusters`), score `9.1`, preview size `0.3 x 0.3 x 0.3`; too tiny unless scaled, not first choice.
- Nest: provisional accept `8895193` (`Dinosaur eggs in a nest`), Model with 8 descendants, preview size `7.0 x 2.4 x 7.0`; plausible Beat 0 nest/egg object despite weak score.
- Bones/fossil dressing: conditional accept `2915304314` (`Low Poly Bones Pack`), score `30.9`, 22 favorites, preview size `172.9 x 40.6 x 197.5`; usable only if scaled/split as bones/fossil dressing, not edible meat.
- Bones/carcass dressing: provisional accept `6934081776` (`Synty Dungeon Pack: Skeletons & Bones`), Creator Roblox, score `60.2`, 410 favorites, preview size `97.4 x 13.9 x 111.3`, 50 MeshParts; strong rated candidate for scaled bone/carcass dressing, not yet accepted as edible meat until eggBreakers2 visual proof.
- Meat/carcass: no accepted candidate yet. `99997340604947` (`Frozen Meat Pack`) is huge (`82.1 x 19.0 x 108.0`); `186499985` (`Butchered Pig`) is primitive/weak. Keep searching before rolling a release visual.
- Scent/waypoint UX: no accepted asset yet. `122873943814595` is a zero-size GUI/system preview with no useful rating signal and script-risk; current custom no-arrow scent cue remains safer until a validated UI asset exists.
Acceptance criteria:
- MeshPart/model geometry, readable in-world at gameplay distance, sane scale, no uncontrolled scripts/autoplay audio after review/sanitization, and usable rating/favorite/creator signal from `Roblox_Search`.
Reject criteria:
- Primitive/CSG/blocky props, glowing balls, flat texture-only food, fossil exhibits pretending to be edible carcasses, oversized nests, false-direction UI arrows, or any model whose helper root/collider is visible/collidable.

### T005 — Leader Asset Search Lane
Owner: leader only
Status: BLOCKED ON SEARCH MCP TIMEOUT
Scope: `Roblox_Search` MCP on `place1`.
Queries:
- `dinosaur nest egg`
- `fern prehistoric plant`
- `dinosaur carcass bones`
- `meat carcass dinosaur`
- `waypoint compass arrow gui`
- `scent trail particles`
Goal: ranked asset candidates with rating/favorites and preview notes.
Deliverable: candidate table; block on any Search MCP failure.
Results after `place1` plugin toggle:
- `dinosaur nest egg`: best result `116137899907258`, score `13.7`, 0 favorites; preview succeeded, huge `36.3 x 41.5 x 78.0`, 6 descendants. Needs visual screenshot before accepting.
- `fern prehistoric plant`: best result `575642906`, score `16.1`, 5 favorites; preview succeeded, `8.1 x 6.4 x 7.6`, 168 descendants. Plausible but named `Potted Palm`, not fern; likely not final prehistoric food.
- `dinosaur carcass bones`: best result `5663348866`, score `0`, 0 favorites; preview succeeded, `28.4 x 20.9 x 29.8`, 1228 descendants. Likely heavy fossil exhibit, not edible carcass.
- `meat carcass dinosaur`: all results poor/noisy; no preview accepted.
- `waypoint compass arrow gui`: best result `137169350986962`, score `0`, 0 favorites; preview succeeded, one MeshPart, `12 x 2 x 12`; probably decor compass, not a working UX waypoint.
- `scent trail particles`: results poor/noisy; no preview accepted.
Additional rated-search results before the latest timeout:
- `low poly fern plant`: top `Fern clusters` `124212560862962`, score `9.1`, 0 favorites; preview was tiny (`0.3 x 0.3 x 0.3`), weak candidate.
- `prehistoric fern`: `Fern` `11611657675`, preview `17.6 x 8.5 x 17.3`, one MeshPart; best current fern candidate.
- `dinosaur carcass bones`: `Low Poly Bones Pack` `2915304314`, score `30.9`, 22 favorites, preview `172.9 x 40.6 x 197.5`; scale/split-only candidate.
- `dinosaur nest egg`: `Dinosaur eggs in a nest` `8895193`, preview `7.0 x 2.4 x 7.0`; plausible nest candidate.
- Meat/carcass and scent/waypoint queues remain unfilled by acceptable assets.
Search screenshot caveat:
- `Roblox_Search.capture_screenshot` failed with `Roblox Studio window not found` even though `search_assets` and `preview_asset` worked. Screenshot access is now intentionally disabled on the legacy Search profile; use `preview_asset` metadata only, then import accepted IDs into eggBreakers2 for visual proof.
Current blocker:
- Later `Roblox_Search.search_assets("low poly fern plant")` timed out.
- Earlier health-state probes timed out after 30s. Health-state access is now intentionally disabled on the Search profile, so asset-lane health is proven by `search_assets` / `preview_asset` only.
Resolution:
- Direct stdio helper `tools/roblox_search_direct.js` restored access: `search_assets("animal carcass bones remains")` returned rated results, and `preview_asset(6934081776)` succeeded.
- Codex's built-in `mcp__Roblox_Search` handle can remain stale after `Transport closed`; use the helper until the app refreshes the MCP transport.

### T009 — Store-First Import Integration Plan
Owner: leader / next executor
Status: READY WHEN SEARCH RESPONDS
Scope: `Roblox_Search` validates in `place1`; `Roblox_Studio` imports/probes in `eggBreakers2`.
Goal: replace temporary procedural food/nest affordance visuals only with accepted Creator Store assets.
Import candidates:
- `11611657675` for starter fern/herbivore food visual.
- `8895193` for hatch/nest visual.
- `2915304314` for scaled bones/fossil/carrion dressing only, not edible meat until visual proof says it reads as food.
Required import probe:
- Insert into `ReplicatedStorage.ImportedAssetLibrary` or a temporary `Workspace.AssetProbe` in `eggBreakers2`.
- Review scripts/autoplay audio before marking candidate usable; adapt useful dynamic scripts under eggBreakers authority and quarantine unsafe/unowned behavior.
- Stamp `SourceAssetId`, `CreatorStoreOnly`, and `ImportedVisibleAsset` on accepted roots.
- Capture eggBreakers2 screenshot from gameplay distance with UI hidden.
- Only then wire MapLayout/FoodWater/Nest visuals to imported assets; keep procedural clusters as non-release fallback.

### T010 — Non-Search Work While Asset Lane Blocked
Owner: leader / worker
Status: SOURCE FIXED / FRESH PROBED
Goal: keep Wave 0 moving without violating asset-search rule.
Tasks:
- Integrated staged MeshPart NPC population proof for the `Apex` -> staged `Tyrannosaurus` path.
- Integrated `RootPart` + `AnimationController` locomotion mode regression so staged rigs do not silently use full-target `PivotTo` teleports.
- `NPCService` now prunes parentless records inside `TickNPCs`, stamps `LocomotionMode`, and identifies staged `RootPart` rigs as `KinematicRootStep`.
- `ClientBootstrap` action guidance now routes through require-able `ActionGuidanceController`, with direct client tests for sensed-vs-actionable behavior.
- Keep docs updated with candidate accept/reject decisions and do not claim final release asset replacement until store import proof exists.
Evidence:
- Static: `luac -p`, `git diff --check`, and `rojo build default.project.json --output /tmp/eggBreakers-wave0-orchestrated2.rbxl` passed.
- Studio fresh-clone NPC probe: `mode=KinematicRootStep`, `movedX=8.0`, `teleported=false`, `staleBefore=2`, `staleAfter=1`, `rootT=1.0`, `bodyVisible=true`.
- Studio staged MeshPart spawn probe: private test staging root, `resolvedPrivate=true`, `ok=true`, `meshCount=1`, `rootHidden=true`, `helperAttr=true`, `bodyVisible=true`, `source=probe-staged-mesh`.
- Studio action guidance probe: far sensed target `farActionable=false`, `farContext=Sensed`, `farActive=false`, `farText=〰 🍖 42m`; near target `nearActionable=true`, `nearContext=Nearby`, `nearActive=true`, `verb=EAT`.

### T011 — Worker C Storyboard Beat 0-2 Source Assertions
Owner: Worker C
Status: PATCHED / SYNTAX CHECKED
Scope: `src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua`, docs only.
Goal: convert Beat 0-2 visual acceptance into placement assertions that reject primitive/generic placeholders where staged/imported source assets should be used.
Assertions added:
- Beat 0 hatched baby dinosaur prefers a staged MeshPart source, stamps imported/staged visual metadata, and hides visible `RootPart`/helper boxes.
- Beat 0 egg/nest visual uses an imported source when present, stamps `ImportedEgg`/`ImportedVisual`/`SourcePath`, and exposes MeshPart geometry.
- Beats 1-2 Nursery/FernPlains starter food query parts stay invisible while every visible food affordance is either imported with source metadata or an approved procedural fallback with explicit fern/frond or carcass/bone classification.
- Beats 1-2 prey and predator NPCs spawn with MeshPart bodies when staged prey/predator sources exist, preserving source metadata and hiding helper boxes.
Evidence:
- Static: `luac -p src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua` passed.
