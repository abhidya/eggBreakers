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
