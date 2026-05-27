# G016 Fail To Fix Log

## Run G016-R001 — 2026-05-27

Tests run: live owner playtest + repo inspection.
Passed: hatch now completes.
Failed: readable dino, food/water visibility/use, sprint/call/hide/attack buttons, health-0 death.
Top failing story: US13 Client UI/mobile controls.
Failure: controls visible but core actions do not create observable gameplay changes.
Root cause: client button wiring incomplete; target selection impossible via Player attribute Instance; map lacks obvious tagged interactables near player; death transition incomplete.
Patch applied: pending T001-T004.
Retest result: pending.
Next action: team lanes T001-T004 repair playability, then T005 gate must require live evidence before PASS.

## Run G016-R002 — T005 harness checkpoint

Tests run: source inspection + G015 evidence carry-forward.
Failed gate: G016 self-validation did not exist in source before T005.
Root cause: no `src/ServerScriptService/Tests/G016` registry/suite and no client proof test that forced live/mobile evidence.
Patch applied: added `UserStoryTestRegistry`, `StoryAssertions`, `G016FinalGateSuite`, `G016FinalGate.server`, and client proof test.
Retest expectation: gate should enumerate US01-US15 and then fail honestly until fresh `G016FinalGateProof` / `G016ClientProof` attributes and 500 imported visible assets exist.
Next action: run source syntax/build checks now; after T001-T004/T006 land, run fresh Studio TestRunner and live E2E probes.

G016 CHECKPOINT — NOT DONE
Reason: self-validating harness exists, but live proof attributes, mobile/controller proof, RBXL persistence proof, and 500-asset gate are still not satisfied.

Run ID: G016-R002
Timestamp: 2026-05-27
Tests run: source syntax, Rojo build, Studio live probes
Passed: hatch 5 taps at 0.09s reached 100% and hatched; live NPC folder had 25 children; WeatherEffects folder/rain existed; visible dino proof from worker-1; food/drink/attack source fixes built.
Failed: final release still below 500 assets; full mobile/controller physical proof and save/reopen proof still pending.
Top failing story: US08/US13 playability gaps
Failure: owner reported no NPCs and flaky tap hatch; eat/drink/attack needed motion.
Root cause: no authored NPC spawn markers in MapLayout; hatch server cooldown too high for rapid taps; client actions sent remotes without body motion.
Patch applied: added NPC spawn markers, visible weather loop, lowered hatch cooldown to 0.08s, added egg hop on tap, added eat/drink/attack/call/hide body motion hooks.
Retest result: PASS for focused live probes: hatch=true progress=100; npcs=25; weatherFolder=true; rain=true.
Next action: commit focused playability fixes, reconcile/shutdown G016 live team, then continue asset/import + save/reopen gates.

G016 CHECKPOINT — NOT DONE
Next automatic action: commit playability fixes and continue US14 asset gate / RBXL persistence proof.

Run ID: G016-R003
Timestamp: 2026-05-27
Tests run: source syntax, Rojo build, Studio live restart probe
Passed: tap hatch stability improved; egg tap now has hop motion in client; NPC ecosystem visible in live Workspace; weather effects exist; mobile feedback label exists.
Failed: biome dressing still needs imported asset batches; final release asset gate still below 500.
Top failing story: US08/US13/US14
Failure: owner reported no NPCs, flaky tap hatch, no weather, lacking biomes.
Root cause: authored NPC spawn markers were incomplete/old place did not surface NPC presence; hatch throttle was too slow for rapid tapping; no weather loop; action buttons lacked movement animation.
Patch applied: added hatch tap cooldown 0.08 and egg hop; added NPC spawn markers and spawn kind use; added WeatherBiomeService; added eat/drink/attack/call/hide body motion hooks.
Retest result: PASS focused live restart probe: hatched=true progress=100 after five 0.09s taps; npcs=22; weatherFolder=true; rain=true; visibleParts=104/104; mobile feedback=true.
Next action: asset/biome dressing batches and full TestRunner/mobile/RBXL persistence gates.

G016 CHECKPOINT — NOT DONE
Next automatic action: continue ASSET003 biome dressing and US08 NPC ecosystem behavior proof.
## Run G016-R004 — 2026-05-27T12:05:13Z

Tests run: team state/mailbox lookup, git status, owner live reports triage.
Passed: old injected team state is not active (`omx team status g016-eggbreakers-live-df77b17a` => no team state found); active work queue now has leader-owned live failures L001-L005.
Failed: live hatch reliability, active NPC CPU behavior, random species/diet variety, dinosaur orientation/animation, biome readability remain unproven.
Top failing story: US01 Hatch reliability.
Failure: owner reports eggs still do not hatch reliably; no worker may claim PASS until fresh Studio Play E2E reproduces and fixes it.
Root cause: not accepted by leader yet; must be proven by live E2E, not guessed.
Patch applied: no gameplay patch in this run; orchestration reset and concrete worker queue written.
Retest result: pending team run.
Next action: launch fresh OMX team with 5 lanes: hatch E2E, NPC brain, species/orientation, biome food-water-weather, QA gate.

G016 CHECKPOINT — NOT DONE
Next automatic action: start team and assign L001-L005, then run luac/rojo/live probes as gates.
## Run G016-R005 — 2026-05-27T12:06:06Z

Tests run: owner live play report triage.
Passed: none claimed.
Failed: no visible trees, no visible action movement, fewer than expected visible dinosaurs/carnivores, hatchling growth from food+water not readable.
Top failing story: US06 Survival growth + US08 NPC ecosystem + US13 visible controls.
Failure: game does not yet read as dinosaur survival; world lacks visible ecology and growth feedback.
Root cause: active team needs explicit tasks for >=10 visible dinos/carnivores, tree/biome dressing, action motion, and food+water growth scaling.
Patch applied: active work queue updated before team launch.
Retest result: pending team lanes.
Next action: commit clean preflight, launch team, assign L001-L005 with new owner deltas.

G016 CHECKPOINT — NOT DONE
Next automatic action: launch fresh OMX team after clean commit, then run live probes for hatch/growth/NPC/biome/action motion.

## Run G016-R006 — L005 QA gate tightening — 2026-05-27T12:16:00Z

Tests run: targeted failing evidence probe, source syntax/build checks pending in this lane.
Passed: none claimed for final release.
Failed: no fresh proof attributes yet for hatch live proof, >=10 visible dinosaurs, >=2 visible carnivores, NPC active state transitions, visible trees/food/water, visible action motion, and growth scale from food+water.
Top failing story: US15 Fresh full QA gate proves all stories.
Failure: final gate could require generic live proof while not naming every owner-reported playability failure as an explicit gate.
Root cause: L005 required owner-failure probes were documented in the queue but not represented as a single explicit final-gate test.
Patch applied: `G016FinalGateSuite` now has an `L005 live playability probes cover owner failure gates` test that fails until the exact fresh proof attributes and run id are attached.
Retest result: expected FAIL until Studio live probes produce real attributes; no final PASS claimed.
Next action: after worker lanes merge, run luac, Rojo build, all-category Studio TestRunner, and live hatch/NPC/biome/action/growth probes.

G016 CHECKPOINT — NOT DONE
Next automatic action: keep collecting exact failing tests/probes; do not mark PASS from docs/source-only evidence.

## Run G016-R007 — L005 latest live-proof reverify — 2026-05-27T12:24:00Z

Tests run: all-source Lua syntax, Rojo build, Studio/MCP read-only live probe for L005 attributes.
Passed: source syntax passed; Rojo build produced `/tmp/eggBreakers-worker5-l005-reverify.rbxl`; Studio/MCP counted visible dinosaurs `25`, visible carnivores `8`, food `15`, water `5`, trees `9`.
Failed: `ReplicatedStorage.G016FinalGateProof` does not exist, so the required proof attributes are absent: `HatchLiveProofPassed`, `NPCActiveStateTransitionsPassed`, `ActionMotionProofPassed`, `GrowthScaleFromFoodWaterPassed`, and `L005LiveProbeRunId`.
Top failing story: US15 Fresh full QA gate proves all stories.
Failure: live world has promising population/food/water/tree counts, but no attached fresh proof artifact for hatch, NPC state transitions, action motion, or growth-scale delta.
Root cause: verification probes are still observational and have not produced the final proof folder/metadata required by the G016 gate.
Patch applied: documentation updated with exact reverify evidence and gaps; no gameplay or proof-attribute patch was made.
Retest result: NOT DONE / expected gate FAIL until fresh live proof attributes are produced by an authorized Studio/live run.
Next action: run the live proof harness that creates `G016FinalGateProof` only after verifying hatch, NPC transitions, action motion, and growth-scale delta.

G016 CHECKPOINT — NOT DONE
Next automatic action: continue live proof capture; do not mark PASS from source/build or counts alone.

## Run G016-R008 — L005 current-head reverify after reassignment — 2026-05-27T12:29:00Z

Tests run: worker-3 coordination message, all-source Lua syntax, Rojo build, Studio/MCP read-only current-head L005 probe.
Passed: current HEAD `55e30b6`; source syntax passed; Rojo build produced `/tmp/eggBreakers-worker5-l005-current-head.rbxl`; Studio/MCP counted visible dinosaurs/NPCs `40`, visible carnivores/predators `9`, visible tree/natural props `100+`.
Failed: `ReplicatedStorage.G016FinalGateProof` does not exist; all requested L005 proof attrs are absent; tagged food count `0`; tagged water count `0`; no NPC records showed non-idle action/state proof beyond standard attributes.
Top failing story: US15 Fresh full QA gate proves all stories.
Failure: latest live probe still cannot prove hatch, tagged food/water, active NPC transitions, action motion, or growth scale; it only proves source/build health and partial visible NPC/tree counts.
Root cause: final proof harness has not produced proof attributes, and live place/tag state is inconsistent with earlier food/water counts.
Patch applied: documentation updated with current-head evidence and exact gaps; no final PASS claimed.
Retest result: NOT DONE / expected gate FAIL.
Next action: run or create an authorized live proof harness that verifies and writes `G016FinalGateProof` only after hatch, food/water tags, NPC transitions, action motion, and growth-scale delta pass.

G016 CHECKPOINT — NOT DONE
Next automatic action: resolve missing live food/water tags and active-state proof before any PASS claim.

## Run G016-R009 — worker-3 coordination addendum — 2026-05-27T12:33:00Z

Tests run: mailbox coordination review plus source grep for worker-3 reported L002/L003 gaps.
Passed: L003 source/test hooks remain present for starter species variety, no-repeat starter selection, forward visual correction, growth visual scaling, and visible action motion wiring.
Failed: worker-3 reports and source grep confirms likely active NPC proof mismatch: `NPCSpawnValidation.lua` asserts `prey:GetAttribute("ActiveNPCBrain") == true`, but current `NPCService.lua` stamps `LastBrainAction`, `BrainTarget`, and `LastBrainMovedAt` without stamping `ActiveNPCBrain`; Studio proof folder still absent.
Top failing story: US08 NPC ecosystem + US15 Fresh full QA gate.
Failure: active NPC brain behavior is partially implemented but lacks the explicit live/source proof marker expected by the validation test and final QA lane.
Root cause: movement/action attributes and proof attributes are not aligned with the validation contract.
Patch applied: documentation updated with worker-3 coordination evidence only; no gameplay patch made from QA lane.
Retest result: NOT DONE / expected gate FAIL until `ActiveNPCBrain` proof and final live proof attrs exist.
Next action: owner lane for NPC service should align attribute stamping with `NPCSpawnValidation` and then rerun L005 proof harness.

G016 CHECKPOINT — NOT DONE
Next automatic action: fix or reassign the `ActiveNPCBrain` proof marker gap before final QA.

## Run G016-R010 — core integration source repairs — 2026-05-27T12:38Z

Tests run: `luac` all source, `rojo build default.project.json --output /tmp/eggBreakers-g016-core-fixes.rbxl`, `git diff --check`, Studio Integration TestRunner.
Passed: source syntax/build/diff checks passed.
Failed: Studio Integration runner still reports 44/49 because current Studio service modules appear require-cached/stale for some patched services; no final PASS claimed.
Top failing story: US05 Water, US07 Combat/death, US12/Progression persistence, US15 fresh QA.
Failure: source-level defects found in water growth grant, default Damageable health, and DNA grants without preloaded profile.
Root cause: live playability work left some server functions using legacy constants/defaults and assuming profiles were preloaded.
Patch applied: `FoodWaterService:RequestDrink` now uses `WaterGrowthGrant`; `CombatService:ApplyDamage` defaults uninitialized Damageable targets to 25 health so attacks visibly reduce/kill practice targets; `PlayerDataService:GrantDNA/GrantFossils` now initialize profiles through `Get`; `NPCService:Eat` now stamps visible Eat action attributes and depletes nearby matching food sources so active NPC eating is observable.
Retest result: source checks PASS; Studio runner requires fresh reload before patched services can be trusted.
Next action: run fresh Studio reload/live proof harness, then handle remaining weather coverage failure if it reproduces without require-cache staleness.

G016 CHECKPOINT — NOT DONE
Next automatic action: continue repairing Integration failures and produce fresh live proof attributes; do not claim PASS from source/build only.
