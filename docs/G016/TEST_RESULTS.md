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
| Self-validating harness | FAIL | G015 had failing tests/missing client proof | T005 |
| 500 asset gate | FAIL | latest evidence 34/500 | T006 |
