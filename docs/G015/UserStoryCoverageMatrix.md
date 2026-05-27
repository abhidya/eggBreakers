# G015 User Story Coverage Matrix

| Story ID | Story | Unit | Integration | E2E | Client | Security | Placement/Asset | Current Status | Evidence | Remaining Work |
| -------- | ----- | ---- | ----------- | --- | ------ | -------- | --------------- | -------------- | -------- | -------------- |
| US01 | Hatch from egg | PASS | PASS | PASS | PASS | PASS | PASS | FAIL | G014 hatch smoke passed; not rerun after save/reopen. | Rerun after persistence and full gate. |
| US02 | Dinosaur visual + diet identity | PASS | PASS | PASS | PASS | PASS | FAIL | FAIL | Imported visuals exist for smoke, but 500-asset gate blocks identity release. | Reach 500 and audit species placements. |
| US03 | Herbivore plant food | PASS | PASS | PASS | BLOCKED | PASS | FAIL | FAIL | Food placement failure in fresh TestRunner. | Fix placement metadata and import minimums. |
| US04 | Carnivore meat/carcass food | PASS | PASS | PASS | BLOCKED | PASS | FAIL | FAIL | Carcass release visuals not fully proven. | Import/place/audit carcass assets and run E2E. |
| US05 | Drink water | PASS | PASS | PASS | PASS | PASS | FAIL | FAIL | Logic exists; placement proof incomplete. | Full placement audit and fresh smoke. |
| US06 | Hunger/thirst/stamina/growth live loop | PASS | PASS | PASS | PASS | PASS | PASS | FAIL | Source tests exist; full fresh gate failed. | Fix all-category failures. |
| US07 | Combat real damage | PASS | FAIL | PASS | PASS | PASS | PASS | FAIL | Fresh TestRunner CombatServiceTests failed expected 16 got nil. | Debug combat damage test/runtime. |
| US08 | NPC ecosystem | PASS | PASS | BLOCKED | BLOCKED | PASS | FAIL | FAIL | NPC release asset proof incomplete. | Import NPC sets and run NPC tests. |
| US09 | Apocalyptic City / Old Eden | PASS | PASS | BLOCKED | PASS | PASS | FAIL | FAIL | City assets inserted but below minimum and placement issues remain. | Continue city imports and placement validation. |
| US10 | Group and calls | PASS | PASS | PASS | BLOCKED | PASS | PASS | FAIL | Server proof exists; client group proof incomplete. | Run client E2E. |
| US11 | Nesting | PASS | PASS | PASS | BLOCKED | PASS | FAIL | FAIL | Nest asset inserted; release placement/asset gate incomplete. | Import nest minimums and run E2E. |
| US12 | Death/respawn persistence | PASS | PASS | PASS | PASS | PASS | PASS | FAIL | Source tests exist; RBXL persistence not proven. | Save/reopen proof. |
| US13 | Client UI/mobile controls | PASS | PASS | BLOCKED | BLOCKED | PASS | PASS | BLOCKED | Mobile/controller runtime proof missing. | Physical/emulated mobile/controller run. |
| US14 | Asset materialization honesty | PASS | PASS | PASS | PASS | PASS | FAIL | FAIL | Live audit 34/500, gap 466. | Continue real imports. |
| US15 | Fresh full QA gate | PASS | PASS | FAIL | FAIL | PASS | FAIL | FAIL | Fresh all-category 146 total, 129 passed, 17 failed. | Fix failures and rerun fresh Play/client gates. |
