# G016 Active Work Queue

Rule: FAIL creates repair work. No PASS claim until live play E2E plus source tests prove story.
Rule: Current owner reports outrank older PASS notes: eggs sometimes do not hatch, NPCs are static/no behavior, only Gallimimus appears, dino faces backward/static, food/water/biomes/weather are weak, no trees are visible, action movement is not visible, at least 10 dinosaurs including carnivores must be visible, and hatchlings must grow bigger from food+water/stat increases.
Rule: Workers must run targeted tests before and after fixes. No docs-only closure.

## L001 — US01 live hatch must be deterministic, no restart needed
Task ID: L001
Story ID: US01, US13
Failing test: owner live play report, must reproduce with Studio Play E2E.
Failure message: tapping/clicking shell is flaky; sometimes egg never completes hatch until game restart.
Root cause: unknown until live E2E; suspected client input binding/rate-limit/state reset/desync between RequestHatch and UI.
Fix strategy: first write/run live hatch E2E that fires touch/click/keyboard inputs, asserts server HatchProgress reaches 100/Hatched=true without restart, then patch server/client until green. Tap should also trigger egg hop/jump feedback.
Files/Studio Objects: ServerMain.server.lua, SurvivalService.lua, CharacterVisualBootstrap.client.lua, Hatch UI/client input code, live test runner.
Test To Run First: fresh Studio Play hatch E2E: 5 deliberate taps at 0.09-0.15s, assert progress increments each tap and completes.
Full Gate To Run After: US01_HatchFromEgg_E2E + US13 client/mobile hatch proof + Rojo build.
Status: TODO
Owner Agent: worker-1

## L002 — US08 NPCs must be active CPU creatures, not statues
Task ID: L002
Story ID: US08, US04, US11
Failing test: owner live play report.
Failure message: no real NPC behavior; NPCs should hatch at nesting sites, wander, eat, drink, hide/flee, attack/die, leave carcasses.
Root cause: current NPCService mostly registers/spawns and simple flee state; no active hunger/thirst/health/action brain.
Fix strategy: design minimal NPC brain with ticked needs + state machine: HatchAtNest -> Wander -> SeekFood/SeekWater -> Eat/Drink -> Hide/Flee/Chase/Attack -> Dead/Carcass. Ensure live world has at least 10 visible dinosaurs with both prey/herbivores and predator/carnivores. Use visible imported models or honest fallback only in tests, not release count.
Files/Studio Objects: NPCService.lua, NPCSpawnService.lua, MapLayoutService.lua nests/food/water/spawns, NPC tests.
Test To Run First: NPC brain unit/integration test advances ticks and proves state transitions plus movement target/action attributes; live count probe proves >=10 NPC/dinosaur instances and >=2 carnivores/predators.
Full Gate To Run After: US08_NPCEcosystem_E2E + US04 carcass E2E + placement/performance NPC cap.
Status: TODO
Owner Agent: worker-2

## L003 — US02 random starter species + forward-facing animated dino
Task ID: L003
Story ID: US02, US13
Failing test: owner live play report.
Failure message: player only hatches as Gallimimus; Gallimimus model is static and facing backward; need random Carnivore/Herbivore starters, visible action motion, growth that makes hatchlings bigger, and more dinosaurs.
Root cause: starter selection was deterministic/first unlocked; imported visual attach orientation wrong; animations/action poses incomplete.
Fix strategy: create tested starter species service with all 4 species eligible, no immediate repeat when possible, diet HUD proof, dinosaur forward correction, visible eat/drink/attack motion, and growth-stage scale-up proof after food+water increases stats.
Files/Studio Objects: StarterSpeciesService.lua, PlayerDataService.lua, ServerMain.server.lua, CharacterVisualService.lua, Species/HUD/client tests.
Test To Run First: unit test can select gallimimus/triceratops/velociraptor/carnotaurus and avoids repeat; Studio hatch proof shows SpeciesId/Diet and ForwardCorrectionDegrees.
Full Gate To Run After: US02 DinosaurIdentity E2E + CharacterVisualService integration + Rojo build.
Status: IN_PROGRESS
Owner Agent: worker-3

## L004 — US03/US05/US09 biomes need visible food, water, weather, dressing
Task ID: L004
Story ID: US03, US05, US09, US14
Failing test: owner live play report.
Failure message: no obvious food/water on map; no trees; biomes lacking; weather weak/invisible; growth from eating/drinking is not readable.
Root cause: map placement and visibility are too sparse; tags may exist but play affordances are not readable.
Fix strategy: add/verify clear biome starter loops: Nursery safe food+water, Fern plains plants/water, carnivore carcass path, visible trees/biome props, visible weather volume, and growth-stat feedback. Tests must count nearby interactables/trees and prove Eat/Drink changes hunger/thirst/growth and eventually bigger visual scale.
Files/Studio Objects: MapLayoutService.lua, FoodWaterService.lua, WeatherBiomeService.lua, placement tests, live E2E probes.
Test To Run First: placement test + live probe counts FoodSource/WaterSource/tree props within tutorial radius and verifies Eat/Drink stat + growth/scale deltas.
Full Gate To Run After: US03/US05/US09 E2E + placement audit + Rojo build.
Status: TODO
Owner Agent: worker-4

## L005 — QA leader lane: run gates, collect evidence, block fake PASS
Task ID: L005
Story ID: US01-US15
Failing test: release gate not credible until live tests pass.
Failure message: unit tests and reports are not enough; owner is finding broken live play.
Root cause: missing live Play E2E gate and stale team state.
Fix strategy: run syntax/build first, then targeted live Studio probes after each worker fix; update FAIL_TO_FIX_LOG with evidence and keep final PASS blocked until live hatch/NPC/species/food-water gates pass.
Files/Studio Objects: docs/G016/FAIL_TO_FIX_LOG.md, TEST_RESULTS.md, G016 final gate tests.
Test To Run First: luac + rojo build + current failing live hatch probe.
Full Gate To Run After: fresh all-category TestRunner and RBXL persistence when core loop green.
Status: TODO
Owner Agent: worker-5

## T001 — US01/US02 Visible readable dinosaur after hatch
Task ID: T001
Story ID: US01, US02, US13
Failing test: live player report + live screenshot
Failure message: hatched dinosaur is invisible/tiny/block-like concrete; player cannot identify species/diet.
Root cause: imported visual parts were hidden by avatar hider; source fixed visibility, but scale/readability and HUD guidance still weak.
Fix strategy: normalize imported dinosaur model scale, force visible safe parts, add diet/species play guidance to HUD/tutorial.
Files to edit: CharacterVisualService.lua, HUDController.lua, ClientBootstrap.client.lua, client tests, live E2E proof.
Studio/place actions: reapply visual in Play mode, capture readable dino proof.
Smallest retest: live post-hatch probe asserts visible parts > 0 and bounding box readable.
Full retest: US01/US02/US13 E2E + fresh Studio TestRunner.
Status: TODO
Owner Agent: worker-1

## T002 — US03/US05 Food and water visible + usable on map
Task ID: T002
Story ID: US03, US05, US13
Failing test: owner live play report
Failure message: no visible food or water on map; eat/drink button appears no-op.
Root cause: food parts are low/unclear; water markers are folders/terrain without WaterSource-tagged interactable part; mobile button uses impossible Player attribute Instance.
Fix strategy: add clear tutorial food, water source parts, billboards/labels, valid tags/attributes, and nearest-target client selection.
Files to edit: MapLayoutService.lua, ClientBootstrap.client.lua, placement tests, live E2E proof.
Studio/place actions: spawn/update tutorial food/water near Nursery; prove EatDrink raises hunger/thirst.
Smallest retest: live probe counts nearby FoodSource and WaterSource and button activates RequestEat/RequestDrink.
Full retest: US03/US05/US13 E2E + placement tests.
Status: TODO
Owner Agent: worker-2

## T003 — US07/US12 Attack, death, and health-0 behavior
Task ID: T003
Story ID: US07, US12, US13
Failing test: owner live play report
Failure message: dinosaur health reaches 0 and does not die; attack button does nothing.
Root cause: player death state may not drive humanoid/death UI/respawn; attack button sends wrong default attack and nil target; no nearby Damageable practice target.
Fix strategy: create server death transition that kills humanoid/locks controls/notifies; add practice target near spawn; choose species-correct attack and nearest target on client.
Files to edit: SurvivalService.lua, CombatService.lua, ServerMain.server.lua, MapLayoutService.lua, ClientBootstrap.client.lua, Death/Combat E2E.
Studio/place actions: live damage player to 0 and verify Dead=true + UI/respawn; attack target health decreases.
Smallest retest: ApplyDamage to 0 asserts Dead and DeathCause; live attack button reduces Damageable health.
Full retest: US07/US12/US13 E2E + fresh Studio TestRunner.
Status: TODO
Owner Agent: worker-3

## T004 — US10/US13 Sprint, call, hide buttons do visible actions
Task ID: T004
Story ID: US10, US13
Failing test: owner live play report
Failure message: sprint, call, hide buttons do nothing.
Root cause: sprint/rest-hide not wired; call marker invisible; no clear client feedback.
Fix strategy: wire buttons to local speed/hidden state and visible call pulse/notification; add live button activation tests.
Files to edit: ClientBootstrap.client.lua, CallService.lua, MobileControlsController.lua, client tests.
Studio/place actions: activate each button in Play mode; verify speed/attributes/visible effect.
Smallest retest: client live probe calls GuiButton:Activate and checks observable state/effect.
Full retest: US10/US13 client/E2E.
Status: TODO
Owner Agent: worker-4

## T005 — G016 self-validating user-story harness
Task ID: T005
Story ID: US01-US15
Failing test: G015 matrix/report still FAIL/BLOCKED, client category missing.
Failure message: tests do not prove live playability; reports can pass without user-story proof.
Root cause: final gates depend on docs/partial source suites and lack live client/mobile proof.
Fix strategy: add UserStoryTestRegistry, StoryAssertions, G016FinalGateSuite, coverage matrix, fail-to-fix log; ensure gate fails until live proof exists.
Files to edit: docs/G016/*, src/ServerScriptService/Tests/G016/*, client tests.
Studio/place actions: run fresh Studio TestRunner after fixes.
Smallest retest: require G016FinalGateSuite and verify it enumerates US01-US15.
Full retest: full TestRunner all categories non-empty.
Status: TODO
Owner Agent: worker-5

## T006 — US14 Asset gate remains separate release blocker
Task ID: T006
Story ID: US14
Failing test: G015/G016 asset gate
Failure message: 58/500 release-ready assets per latest persisted-place evidence.
Root cause: actual imported audited placed assets below release threshold.
Fix strategy: continue Creator Store import/audit/place batches after core playability loop is green; do not fake with docs or generated clones. Use `eggBreakers5.rbxl` as the current cleaned persisted baseline and keep removing validation-only leftovers before release audits.
Files to edit: UniqueImportPilotReport.lua, docs/G016/ASSET_GATE_REPORT.md, `tools/g016_place_gate_audit.luau`, `tools/g016_clean_place_candidate.luau`, place assets through Studio MCP or an authenticated headless asset-delivery lane.
Studio/place actions: import/audit/place until >=500 or continue retry queue.
Smallest retest: AssetImportAuditService ValidateReleaseCounts(500).
Full retest: G016FinalGateSuite.
Status: TODO
Owner Agent: worker-6 or later batch lane
