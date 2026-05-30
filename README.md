# eggBreakers

Roblox survival prototype where players hatch as dinosaurs, manage hunger/thirst/stamina, grow through life stages, explore biomes, collect fossils, and survive NPC/prey encounters.

## Startup contract

- `ServerScriptService/Bootstrap.lua` is a ModuleScript with `Init()`.
- `ServerScriptService/ServerMain.server.lua` requires `Bootstrap` and calls `Bootstrap.Init()` before binding remotes.
- `Bootstrap.Init()` is idempotent: it creates `ReplicatedStorage.Remotes` and one `RemoteEvent` per `ReplicatedStorage.Shared.RemoteContracts` entry.

## Validation

Use Rojo for source sync/build. Current automated gates are documented in `.omx/TestResults.md` and the G013 docs under `.omx/`.

**Authoritative status:** The freshest validated state lives in the **Current Authoritative Snapshot — 2026-05-30 (validated via live Studio)** block at the top of `eggBreakers_Master_Plan.md`, `eggBreakers_World_and_Gameplay_Design.md`, and `eggBreakers_Asset_Ledger_and_Build_Sequence.md`, and is consolidated in `eggBreakers_STATUS.md`. Wording follows `docs/G026/PlanningCountContradictionReport.md`: `catalogedSourceAssetIds=500` is the catalog (unique SourceAssetIds), NOT 500 live imports; `releaseReadyVisibleAssets=22/500` is the release gate. Latest live test run: 176 total / 143 passed / 34 failed (15 pre-existing module-load failures + 19 content/release-gate failures). Treat any other count in older docs as dated history.
