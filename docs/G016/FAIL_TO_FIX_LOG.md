# G016 Fail To Fix Log

Run ID: G016-R001
Timestamp: 2026-05-27
Tests run: live owner playtest + repo inspection
Passed: hatch now completes
Failed: readable dino, food/water visibility/use, sprint/call/hide/attack buttons, health-0 death
Top failing story: US13 Client UI/mobile controls
Failure: controls visible but core actions do not create observable gameplay changes
Root cause: client button wiring incomplete; target selection impossible via Player attribute Instance; map lacks obvious tagged interactables near player; death transition incomplete.
Patch applied: pending
Retest result: pending
Next action: team lanes T001-T005 implement and live-retest.

G016 CHECKPOINT — NOT DONE
Next automatic action: launch team to repair T001-T005, then run live E2E probes.
