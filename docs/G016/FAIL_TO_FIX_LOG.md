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
