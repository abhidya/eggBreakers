# G016 User Story Coverage Matrix

| Story ID | Story | Unit | Integration | E2E | Client | Security | Placement/Asset | Release Critical | Current Status | Evidence | Next Failing Test |
| -------- | ----- | ---- | ----------- | --- | ------ | -------- | --------------- | ---------------- | -------------- | -------- | ----------------- |
| US01 | Hatch from egg | PASS | PASS | FIXING | FIXING | PASS | FIXING | yes | FIXING | hatch completes per owner; needs regression | US01 live hatch + visual |
| US02 | Dinosaur identity and diet | PASS | FIXING | FAIL | FAIL | PASS | FAIL | yes | FAIL | dino concrete block; diet unclear | T001 readable dino |
| US03 | Herbivore plant food | PASS | PASS | FAIL | FAIL | PASS | FAIL | yes | FAIL | no visible food | T002 food visibility/use |
| US04 | Carnivore meat/carcass food | PASS | FIXING | FAIL | FAIL | PASS | FAIL | yes | FAIL | carcass loop not live proven | US04 live meat/carcass |
| US05 | Drink water | PASS | PASS | FAIL | FAIL | PASS | FAIL | yes | FAIL | no visible water | T002 water visibility/use |
| US06 | Survival/growth loop | PASS | PASS | FIXING | FAIL | PASS | PASS | yes | FIXING | source tests exist; live loop weak | live growth/needs proof |
| US07 | Combat real damage | PASS | PASS | FAIL | FAIL | PASS | FIXING | yes | FAIL | attack no-op | T003 attack button |
| US08 | NPC ecosystem | FIXING | FIXING | FAIL | BLOCKED_BY_TOOL | PASS | FAIL | yes | FAIL | no live NPC proof | NPC spawn proof |
| US09 | Old Eden city/fossils | FIXING | FIXING | FAIL | FAIL | PASS | FAIL | yes | FAIL | city/fossil placement incomplete | city placement proof |
| US10 | Group and calls | PASS | PASS | FAIL | FAIL | PASS | PASS | yes | FAIL | call button no visible effect | T004 call feedback |
| US11 | Nesting | PASS | PASS | FAIL | FAIL | PASS | FAIL | yes | FAIL | nest proof incomplete | nesting E2E |
| US12 | Death/respawn persistence | PASS | PASS | FAIL | FAIL | PASS | PASS | yes | FAIL | health 0 no death | T003 health-0 death |
| US13 | Client UI/mobile controls | FAIL | FAIL | FAIL | FAIL | PASS | PASS | yes | FAIL | buttons do nothing | T004/T002/T003 button E2E |
| US14 | Asset materialization honesty | PASS | FAIL | FAIL | BLOCKED_BY_TOOL | PASS | FAIL | yes | FAIL | 70/500 assets in cleaned persisted candidate | T006 asset gate |
| US15 | Fresh full QA gate | FIXING | FIXING | FAIL | FAIL | FAIL | FAIL | yes | FAIL | G016FinalGateSuite added; live proof attrs absent | G016FinalGateSuite live proof requirements |
