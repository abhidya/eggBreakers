# G016 Test Results

Current checkpoint: NOT DONE.
Known latest evidence from owner: hatch completes but post-hatch game loop fails visually and functionally.

| Gate | Status | Evidence | Next action |
|---|---|---|---|
| Hatch completion | PASS | owner says "hatch works now" | keep regression E2E |
| Readable dino | FAIL | owner sees concrete block / cannot identify dino | T001 |
| Food/water loop | FAIL | owner sees no food/water | T002 |
| Attack/combat/death | FAIL | attack no-op, health 0 no death | T003 |
| Sprint/call/hide | FAIL | buttons do nothing | T004 |
| Self-validating harness source | FIXING | T005 added G016 registry/suite/client proof files | run syntax/build/Studio gate |
| G016 live proof attributes | FAIL | no `G016FinalGateProof` / `G016ClientProof` fresh live attributes yet | live E2E after repairs |
| Fresh all-category TestRunner | FAIL | G015 carry-forward was 146 total, 129 passed, 17 failed | rerun after fixes |
| L005 owner-failure live probes | FAIL | required proof attrs absent: hatch live proof, >=10 visible dinos, >=2 carnivores, NPC active transitions, trees/food/water, action motion, growth scale | run fresh Studio live probes after worker lanes merge |
| Mobile/controller proof | BLOCKED | no fresh device/emulator/controller proof in this lane | live mobile/controller smoke |
| RBXL save/reopen persistence | BLOCKED | no fresh save/reopen proof | save/reopen audit |
| 500 asset gate | FAIL | latest evidence 34/500 release-ready visible imports | T006 |

## T005 Harness Status

- `src/ServerScriptService/Tests/G016/UserStoryTestRegistry.lua` enumerates US01-US15.
- `src/ServerScriptService/Tests/G016/StoryAssertions.lua` centralizes proof checks and requires per-story timestamp/source/milestone metadata.
- `src/ServerScriptService/Tests/G016/G016FinalGateSuite.lua` fails unless all stories have live PASS proof, fresh all-category proof, mobile/live E2E proof, RBXL persistence proof, and 500 release-ready imports.
- `src/StarterPlayer/StarterPlayerScripts/Tests/G016ClientStoryProofTests.client.lua` prevents US13/client control PASS without live mobile/controller proof.

Expected current result: FAIL until real live proof artifacts are attached. Do not override this with docs-only evidence.

## Fresh Studio G016 Gate Probe — 2026-05-27

Studio MCP read-only probe executed `G016FinalGateSuite` without creating proof attributes. Result: 7 total, 2 passed, 5 failed, 0 skipped, 1 suite. Passing checks: gate files present and UserStoryTestRegistry enumerates US01-US15. Expected failing checks: missing per-story live PASS proof, missing fresh all-category TestRunner proof, missing mobile/live E2E proof, missing RBXL persistence proof, and release asset count below 500.

## L005 Gate Tightening Probe — 2026-05-27

First failing probe before patch: current evidence still has `Fresh all-category TestRunner` FAIL and no explicit proof for the owner-reported gates (hatch live proof, >=10 visible dinosaurs with carnivores, NPC active transitions, tree/food/water visibility, action motion, and growth scale from food+water). Patch keeps the final gate failing until those fresh live proof attributes exist. No final PASS claimed.

## L005 Reverify Probe — 2026-05-27T12:24Z

Fresh worker-5 source/build checks passed on current worker HEAD, and Studio/MCP read-only probe found partial live-world evidence but no final proof folder. Evidence: `luac` all source PASS; `rojo build default.project.json --output /tmp/eggBreakers-worker5-l005-reverify.rbxl` PASS; Studio/MCP reported `ReplicatedStorage.G016FinalGateProof` missing, visible dinosaurs `25`, visible carnivores `8`, food `15`, water `5`, trees `9`. Exact remaining gaps: no `HatchLiveProofPassed`, no `NPCActiveStateTransitionsPassed`, no `ActionMotionProofPassed`, no `GrowthScaleFromFoodWaterPassed`, and no `L005LiveProbeRunId` proof attributes. No final PASS claimed.

## L005 Current-Head Reverify — 2026-05-27T12:29Z

Worker-5 coordinated with worker-3 and reran latest current-head checks at commit `55e30b6`. Source/build evidence: `luac` all source PASS; `rojo build default.project.json --output /tmp/eggBreakers-worker5-l005-current-head.rbxl` PASS. Studio/MCP read-only probe result: `ReplicatedStorage.G016FinalGateProof` missing, all requested L005 proof attrs absent (`HatchLiveProofPassed`, `VisibleDinosaurCount`, `VisibleCarnivoreCount`, `NPCActiveStateTransitionsPassed`, `TreesFoodWaterVisibilityPassed`, `ActionMotionProofPassed`, `GrowthScaleFromFoodWaterPassed`, `L005LiveProbeRunId`). Observational counts: visible dinosaurs/NPCs `40`, visible carnivores/predators `9`, tagged food `0`, tagged water `0`, visible tree/natural props `100+`. NPC non-idle action/state proof failed: no records showed non-idle action/state beyond standard attributes. Remaining exact gaps: final proof folder absent, hatch proof absent, active NPC transition proof absent, tagged food/water live probe failed, action motion proof absent, growth-scale proof absent. No final PASS claimed.

## Worker-3 Coordination Addendum — 2026-05-27T12:33Z

Worker-3 replied with source-level L002/L003 evidence and one likely failing test gap. L002 source has `NPCService:Tick`/`TickNPCs`, `RunPreyBrain`, `RunPredatorBrain`, `MoveRecordToward`, and `NPCSpawnService` loop coverage; `NPCSpawnValidation` asserts visible dinosaur/carnivore counts plus active brain movement. Exact gap: `NPCSpawnValidation.lua` asserts `prey:GetAttribute("ActiveNPCBrain") == true`, but current-head `NPCService.lua` only stamps `LastBrainAction`, `BrainTarget`, and `LastBrainMovedAt`; no `ActiveNPCBrain` stamp was found. L003 source checks remain present: 4-species starter pool, anti-repeat `LastStarterSpecies`, `ForwardCorrectionDegrees`, `GrowthVisualScale`, and `PlayActionMotion` for Eat/Drink/Attack/Call/Hide. Worker-3 also confirmed active Studio proof query has `{hasProofFolder=false}`. No final PASS claimed.

## Core Integration Probe — 2026-05-27T12:38Z

Current head after team shutdown: `40dcc25` plus local service fixes. Source checks passed: `luac` over all `src/**/*.lua`; `rojo build default.project.json --output /tmp/eggBreakers-g016-core-fixes.rbxl`; `git diff --check`. Studio Integration TestRunner remains stale/partially failing at 49 total, 44 passed, 5 failed: CombatService default Damageable health, FoodWaterService water growth, NPCService food depletion target, ProgressionService DNA grant without preloaded profile, WeatherBiomeService rain size cache/state. Local patches address the first, second, third, and fourth source causes; Studio require-cache still reported old values until a fresh Studio reload/TestRunner run.

Remaining proof gaps: fresh Studio reload, live Play proof attributes, mobile/controller proof, RBXL save/reopen, 500 asset gate.

## Fresh Clone Service Probe — 2026-05-27T12:42Z

Because active Studio still has cached required modules, a fresh cloned `ServerScriptService.Services` probe was run. It proves current source behavior independent of the old require cache: combat target health `25 -> 16` with server damage `9`; water drink growth `0 -> 4`; progression `GrantDNA(300)` then unlock leaves DNA `50`; NPC prey eating sets state `Eat`, depletes food, and stamps `FoodSourcesDepleted`; weather uses 9 rain volume tiles + 9 streak tiles with max tile size about `1566x1466`, coverage attrs `4700x4400`, avoiding Roblox's 2048-stud part clamp.

This is stronger source/runtime evidence, but still not final PASS because it is not a fresh Studio reload all-category TestRunner, not a Play-mode live proof artifact, and not mobile/RBXL/asset-gate proof.
