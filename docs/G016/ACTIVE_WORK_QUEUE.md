# G016 Active Work Queue

Rule: FAIL creates repair work. No PASS claim until live play E2E plus source tests prove story.

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
Failure message: 34/500 release-ready assets per latest evidence.
Root cause: actual imported audited placed assets below release threshold.
Fix strategy: continue Creator Store import/audit/place batches after core playability loop is green; do not fake with docs or generated clones.
Files to edit: UniqueImportPilotReport.lua, docs/G016/ASSET_GATE_REPORT.md, place assets through Studio MCP.
Studio/place actions: import/audit/place until >=500 or continue retry queue.
Smallest retest: AssetImportAuditService ValidateReleaseCounts(500).
Full retest: G016FinalGateSuite.
Status: TODO
Owner Agent: worker-6 or later batch lane
