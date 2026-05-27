# G013 Test Results

Overall release gate: **FAIL**.

No test result in this document uses indeterminate labels. Incomplete evidence is marked **BLOCKED** and release-blocking behavior is marked **FAIL**.

| Gate | Status | Evidence |
| --- | --- | --- |
| Lua syntax | PASS | `luac -p` on modified G013 gate plus core startup files. |
| Rojo build | PASS | `rojo build default.project.json` must succeed before task close. |
| Startup/remotes | PASS | `Bootstrap.lua` ModuleScript and `RemoteValidationTests.lua` exact-once/hatch reload tests exist. |
| Client bootstrap | PASS | `src/StarterPlayer/StarterPlayerScripts/CharacterVisualBootstrap.client.lua` exists. |
| Final G013 gate expected result | FAIL | `G013FinalGate.lua` / `G013FinalGate.server.lua` is intentionally red until fallback visuals, pre-hatch drinking, pending-only combat, empty NPC models, placeholder carcasses, and materialized import count blockers are fixed. |
| Fresh Studio all-category TestRunner | BLOCKED | Not rerun in this worker after latest cross-worker merge blockers; task 28 reported worker-3 merge conflicts still open. |
| Live materialized Store imports | FAIL | Current report says cumulative tracked materialized unique primary IDs = 44, gap to 500 = 456. |
| Mobile/client runtime smoke | BLOCKED | Client test files exist; fresh touch/mobile Studio runtime evidence still needed. |
