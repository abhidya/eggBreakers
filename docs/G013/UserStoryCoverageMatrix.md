# G013 User Story Coverage Matrix

Status vocabulary is intentionally closed: **PASS**, **FAIL**, **BLOCKED**. There are no indeterminate rows.

| Story | Expected player-facing outcome | Status | Current evidence | Required closure |
| --- | --- | --- | --- | --- |
| US01 | Fresh player starts as a visible egg, not the default Roblox avatar. | PASS | `CharacterVisualServiceTests.lua` covers egg visual and hidden default avatar; `ServerMain.server.lua` applies visuals on character init. | Fresh Studio play proof still recommended for release signoff. |
| US02 | Hatch interaction turns egg into a visible dinosaur model. | FAIL | `CharacterVisualService.lua` can fall back to visible Part dinosaur when configured model is missing; G013 final gate rejects release fallback. | Provide/import configured dinosaur models for every release species/stage. |
| US03 | Client bootstrap and HUD/mobile controllers are present. | PASS | `CharacterVisualBootstrap.client.lua` and client controller/test files exist under `StarterPlayerScripts`. | Run fresh client/mobile Studio test pass. |
| US04 | Players cannot drink/eat before hatching. | FAIL | G014 source verifies `FoodWaterService:RequestDrink` requires hatched state. | Keep regression tests green. |
| US05 | Herbivores can eat real placed plant food sources after hatch. | PASS | `MapLayoutService:EnsureFoodSourcePlacements`; `FoodWaterPlacementValidation.lua`; `FoodServiceTests.lua`. | Fresh Studio all-test run. |
| US06 | Carnivores can hunt prey and eat carcasses after hatch. | FAIL | `NPCService.lua` has duplicate `CreateCarcassFoodSource` definitions and generic Part carcass output; gate rejects placeholder carcass. | Consolidate carcass API and use final carcass asset/model. |
| US07 | Combat applies server-authoritative health/damage, not only a pending attribute. | FAIL | G014 source applies health damage and `LastServerDamage`; `PendingServerDamage` remains telemetry. | Keep regression tests green. |
| US08 | The world has coherent biome placement and safe travel corridors. | PASS | Placement validation suites and task 28 review show current source builds and geometry/placement tests exist. | Re-run after final imports/merge. |
| US09 | City ruins/cars/rubble are in Apocalyptic City without generic visible placeholders. | BLOCKED | Placement/audit tests exist; live materialized final city asset count is not complete. | Finish live Store materialization and final placement audit. |
| US10 | Food, water, carcasses, city props, and assets are not generic visible placeholders. | FAIL | `CharacterVisualService` and `NPCService` still create visible Part fallbacks/placeholders in release paths. | Replace fallback visuals with approved assets or make gate/debug only. |
| US11 | NPCs spawn as visible, non-empty dinosaur/prey models. | FAIL | `NPCSpawnService:CreateNPCRecord` creates an empty `Model` with attributes only. | Attach approved model/parts and behavior state. |
| US12 | 500 unique Creator Store source asset IDs are separately reported from materialized imports. | FAIL | `AssetManifest.lua` has 500 catalog IDs, but `UniqueImportPilotReport.lua` reports only 44 cumulative tracked materialized unique primary IDs. | Materialize/import and audit remaining unique source assets, or downgrade release claim. |
| US13 | Startup/remotes/hatch reload are require-safe and idempotent. | PASS | `Bootstrap.lua`; `RemoteValidationTests.lua`; task 26 build and syntax evidence. | Preserve during merges. |
| US14 | Security/performance gates have current final evidence. | BLOCKED | Targeted gates exist, but all-category fresh Studio execution remains pending in team evidence. | Fresh synced Studio TestRunner all categories plus performance/security docs. |
| US15 | Final report has no PASS claim while blockers remain. | PASS | `docs/G013/FinalReport.md` marks release as FAIL/BLOCKED and names blockers. | Change only after G013FinalGate passes. |
