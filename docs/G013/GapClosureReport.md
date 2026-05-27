# G013 Gap Closure Report

Overall status: **FAIL** — do not publish or claim final PASS.

## Closed / Passing Evidence
- Startup bootstrap is require-safe via `Bootstrap.lua` and `ServerMain.server.lua` using `Bootstrap.Init()`.
- Remote creation is idempotent and covered by `RemoteValidationTests.lua`.
- Client bootstrap file and client controller tests are present.
- Coherent placement validation suites exist and current worker-1 source built in task 28.

## Open Release Blockers
1. **Visible dinosaur model fallback** — `CharacterVisualService.lua` still creates visible Part egg and fallback dinosaur visuals; release must use approved art/models or explicitly non-release debug fallback.
2. **Pre-hatch drinking** — `FoodWaterService:RequestDrink` does not require hatched state.
3. **Pending-only combat** — `CombatService:RequestAttack` sets `PendingServerDamage` instead of applying health/NPC damage.
4. **Empty NPC models** — `NPCSpawnService:CreateNPCRecord` creates an empty `Model`.
5. **Carcass placeholder/API conflict** — `NPCService.lua` has duplicate `CreateCarcassFoodSource` definitions and visible Part carcass output.
6. **500 materialized Store imports** — catalog has 500 source IDs, but materialized import report has 44 unique primary IDs and a 456 gap.
7. **Fresh all-category Studio QA** — current evidence is targeted/static; final all-category, mobile, performance, and security execution remains blocked/pending.
8. **Worker-3 merge risk** — task 28 found task 24 branch would regress Bootstrap/docs and has `+=` luac incompatibility unless rebased/fixed.

## Next Closure Order
1. Rebase/fix task 24 without deleting task 26 docs/bootstrap.
2. Replace release fallback visuals and empty NPC/carcass placeholders with approved models/assets.
3. Fix pre-hatch drink and server-authoritative combat damage.
4. Continue materialized Store imports to 500 unique audited primary source IDs or explicitly fail the owner-corrected rule.
5. Run fresh synced Studio all-category TestRunner and update this report from FAIL to PASS only after `G013FinalGate.lua` / `G013FinalGate.server.lua` passes.
