# G014 User Story Coverage Matrix

| Story ID | Story | Unit | Integration | E2E | Client | Security | Placement/Asset | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| US01 | Hatch from egg | PASS | PASS | PASS | PASS | PASS | PASS | PASS | Fresh Studio Play: Space input hatched player; imported egg before hatch; imported dinosaur after hatch; default avatar hidden. |
| US02 | Dinosaur identity | PASS | PASS | PASS | PASS | BLOCKED | BLOCKED | BLOCKED | Studio library now resolves egg and 4 species x 4 stages, but release-ready import audit is not 500. |
| US03 | Herbivore eats plants | PASS | PASS | PASS | BLOCKED | PASS | FAIL | FAIL | Logic exists; visible final plant food imported/release-ready placement not fully proven. |
| US04 | Carnivore eats meat/carcass | PASS | PASS | PASS | BLOCKED | PASS | FAIL | FAIL | Source now creates carcass from imported visual when available; release placement/import audit remains below 500. |
| US05 | Drink water | PASS | PASS | PASS | N/A | PASS | PASS | PASS | `FoodWaterService:RequestDrink` requires alive + hatched + nearby WaterSource. |
| US06 | Survival tick/growth | PASS | PASS | PASS | PASS | PASS | N/A | PASS | Needs loop, stamina regen, growth, and juvenile E2E tests exist. |
| US07 | Combat damage | PASS | PASS | PASS | N/A | PASS | N/A | PASS | Combat applies Health and LastServerDamage; PendingServerDamage remains telemetry only. |
| US08 | NPC ecosystem | PASS | PASS | BLOCKED | N/A | N/A | FAIL | FAIL | NPCs now resolve imported models when library exists; full release validation still blocked by import count. |
| US09 | Old Eden city/fossils | PASS | PASS | BLOCKED | PASS | PASS | FAIL | FAIL | Server rewards exist; imported city prop release-ready audit incomplete. |
| US10 | Group/calls | PASS | PASS | PASS | BLOCKED | PASS | N/A | BLOCKED | Server flow fixed; full client group panel E2E not proven. |
| US11 | Nesting | PASS | PASS | PASS | N/A | PASS | FAIL | FAIL | Nest outcome exists; imported nest release-ready audit incomplete. |
| US12 | Death/respawn | PASS | PASS | PASS | PASS | PASS | N/A | PASS | Server death/respawn/account persistence tests exist. |
| US13 | Client UI/mobile controls | PASS | PASS | BLOCKED | PASS | N/A | PASS | BLOCKED | `ClientBootstrap.client.lua` now loads controllers; fresh mobile device proof still needed. |
| US14 | Asset import honesty | PASS | PASS | N/A | N/A | PASS | FAIL | FAIL | Live materialized quality-approved unique primary imports are now 23/500 after quality quarantine; catalog rows are not counted. |
| US15 | Fresh full QA gate | PASS | PASS | FAIL | BLOCKED | PASS | FAIL | FAIL | Fresh Studio hatch smoke passed, but full all-category TestRunner and 500 release assets still fail. |


## G015 Follow-up Evidence — 2026-05-27

Current G014 continuation evidence supersedes stale G015-only counts: active `eggBreakers2.rbxl` now audits at 23/500 release-ready visible assets after quality quarantine with a 477 gap, not release PASS. Fresh edit-mode all-category TestRunner was previously 146 total, 129 passed, 17 failed; a newer fresh full reload/all-category TestRunner remains required. Mobile/controller proof and `.rbxl` save/reopen persistence remain BLOCKED. G014 remains honest FAIL.


## Source-only asset/map quality patch — 2026-05-30

- `AssetImportAuditService.lua` now quarantines non-required low-quality/mesh imported roots during mutate audits and reports `qualityAssetsQuarantined` separately.
- `MapLayoutService.lua` now uses exact half-scale source compaction, re-centers mismatched food/carcass placements into their declared zones, keeps procedural food/tree visuals hidden, and tags NPC spawns as potential food when defeated.
- No client UI or combat files were changed in this patch. Live G014 release count remains an honest 23/500 until Studio is synced and rerun.
