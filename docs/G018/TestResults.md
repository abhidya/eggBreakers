# G018 Test Results

Current starter-note correction (2026-05-31): the hatch UI source now defines the first-session starter set as Coelophysis, Parasaurolophus, Utahraptor, and Citipati. Older result rows below that name Gallimimus/Triceratops/Velociraptor/Carnotaurus are preserved as historical test evidence, not the current starter contract.

## Worker-1 Source Verification — 2026-05-27

| Check | Result | Evidence |
| --- | --- | --- |
| Luau syntax | PASS | `find src -name '*.lua' -print0 \| xargs -0 -n1 luac -p` exited 0. |
| Diff hygiene | PASS | `git diff --check` exited 0. |
| Rojo build | PASS | `rojo build default.project.json --output /tmp/eggBreakers-g018-worker1.rbxl` built successfully. |
| Studio TestRunner All | NOT RUN | Roblox Studio runtime not available in this worker shell. |
| G018 final gate | EXPECTED FAIL until live proof | `G018FinalGateSuite` intentionally requires live proof attrs, RBXL persistence, publish scan proof attr, and 500 release-ready assets. |

## Current Status

Source checks pass for the worker slice, but G018 final QA remains blocked by live proof and asset gates.

## Story Beat Coverage Audit — 2026-05-31

| Check | Result | Evidence |
| --- | --- | --- |
| Beat 0-8 source coverage audit | UPDATED | `docs/G018/STORY_BEAT_COVERAGE_AUDIT.md` maps each storyboard beat to source tests and live-proof gaps. |
| Reviewed-script import policy | UPDATED | Coverage audit and G018 work queue now require source review, owner, sandbox/authority checks, tests, and integration proof for dynamic imported executable scripts. |
| Storyboard source syntax | PASS | `luac -p src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua` exited 0. |
| Whitespace/diff check | PASS | `git diff --check -- src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua docs/G018/STORY_BEAT_COVERAGE_AUDIT.md docs/G018/ACTIVE_WORK_QUEUE.md docs/G018/WAVE0_SWARM_TASKS.md docs/G018/USER_STORY_COVERAGE_MATRIX.md` exited 0. |
| Studio/live gates | NOT RUN | Worker was instructed not to run Studio MCP or broad validation; live proof remains blocked. |

## Test/Audit Gap Closure — 2026-05-31

| Check | Result | Evidence |
| --- | --- | --- |
| Beat 8 herding source assertion | ADDED | `StoryboardBeatValidation.server` now asserts authored `nestingHerd` markers resolve to herd-capable prey species, are stamped as `NestingHerd`, and remain `SpeciesRelevantSpawn` outside preferred biome. |
| Luau syntax | PASS | `luac -p src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua` exited 0. |
| Diff hygiene | PASS | `git diff --check -- src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua docs/G018/TestResults.md` exited 0. |
| Live/E2E proof | NOT RUN | Source-only lane; no claim of Studio/live E2E pass. Nesting herd coordination still needs live proof. |

## Hatch/Select Regression — 2026-05-31

| Check | Result | Evidence |
| --- | --- | --- |
| Play-mode hatch UI smoke | PASS | Fresh Play inspection found `HatchScreen.Enabled=true`, `SpeciesSelector`, and four starter buttons: Gallimimus, Triceratops, Velociraptor, Carnotaurus. `RequestSelectSpecies` remote existed in `ReplicatedStorage.Remotes`. |
| Studio E2E category | EXPECTED FAIL ON ASSET GATE ONLY | `TestRunner.runRegistered({ category = "E2E" })` ran 29 tests: 28 passed, 1 failed at `G013FinalGate.server` because release-ready live imported assets remain `24/500`. Hatch/select regression test passed inside the E2E category. |
| Source checks | PASS | `luac -p` on hatch/select client, server, and tests passed; `rojo build default.project.json --output /tmp/eggBreakers-hatch-select-proof.rbxl` passed; `git diff --check` passed. |
| Client clone harness | PARTIAL | Focused server-side client clone harness still hits require-cache/`LocalPlayer` limitations for some UI modules; live Play inspection is the authoritative selector smoke until a true client runner is used. |

## G027 E2E/Test Swarm — 2026-05-31

| Check | Result | Evidence |
| --- | --- | --- |
| Live Studio E2E before cache repair | FAIL | `TestRunner.run({ category = "E2E" })` reported `30/38` passing. Source contained `SetResting`, `DeathState`, and `GetMovementSurface`, but the open Studio require cache returned stale service tables. |
| Live Studio E2E after cache repair | EXPECTED FAIL ON ASSET GATE ONLY | After refreshing cached `SurvivalService`, `NPCService`, and `FoodWaterService` from their live ModuleScript source and disabling random crits for deterministic proof, E2E reported `36/38` passing. Remaining failures were only `release-ready live imported assets below 500: 26` and `releaseReadyVisibleAssets below 500: 26`. |
| Broad all-category audit | FAIL-HONEST | All-category Studio TestRunner reported `255/300` passing. Failures are release/proof gates, client category `0`, stale/open-Studio cache or source-sync issues, and live-world placeholder/import blockers; this is not a release PASS. |
| Four-starter client selector coverage | ADDED | `HatchUITests.client.lua` now asserts the default hatch selector renders exactly Coelophysis, Parasaurolophus, Utahraptor, and Citipati with species ids and readable names. |
| G027 asset regression coverage | ADDED | `AssetImportAuditStateTests.lua` now explicitly fixtures G027 nest (`8895193`), plant (`12630982706`), and UI icon (`110801640375836`) roots as tagged release-ready imports. |
| Deterministic combat gate | FIXED | `G014FinalGateSuite.lua` now forces `CombatService.CritChance = 0` around its exact damage assertion so crit RNG cannot fail the story gate. |
