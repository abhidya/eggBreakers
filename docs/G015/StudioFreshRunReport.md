# G015 Studio Fresh Run Report

Studio instance/session: `eggBreakers2.rbxl` (`0ccc8230-8c47-47e5-8e31-09163868efb0`)
Place file opened: `eggBreakers2.rbxl`
Rojo sync state: source tree builds with Rojo; live Studio place has G015 source tests only after source commit/build context, not proven through Rojo serve.
Command used: Studio MCP `execute_luau` requiring `ReplicatedStorage.Shared.TestFramework.TestRunner`, `TestRunner.clearSuites()`, then `TestRunner.run({ category = "All", milestone = "G015FreshAllCategoryEditMode" })`.
Fresh/stale assessment: Fresh edit-mode clone discovery path was used (`_FreshDiscover`); Play VM client execution is not proven.

| Metric | Value |
|---|---:|
| Categories discovered | Unit=7, Integration=10, Placement=11, E2E=11, Security=7, Performance=4, Client=0, G015FinalGate=1 |
| Total tests | 146 |
| Passed | 129 |
| Failed | 17 |
| Skipped | 0 |

Failures included: release-ready live imports below 500, G014/G015 final gate asset failures, missing mobile proof, missing RBXL proof, missing placeholder sweep proof, user story matrix not PASS, CombatService damage assertion, ProgressionService unlock assertion, placement/terrain/biome/food metadata failures.

Status: FAIL. Client category is empty in server edit-mode run and Play/mobile proof is not established.
