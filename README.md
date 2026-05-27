# eggBreakers

Roblox survival prototype where players hatch as dinosaurs, manage hunger/thirst/stamina, grow through life stages, explore biomes, collect fossils, and survive NPC/prey encounters.

## Startup contract

- `ServerScriptService/Bootstrap.lua` is a ModuleScript with `Init()`.
- `ServerScriptService/ServerMain.server.lua` requires `Bootstrap` and calls `Bootstrap.Init()` before binding remotes.
- `Bootstrap.Init()` is idempotent: it creates `ReplicatedStorage.Remotes` and one `RemoteEvent` per `ReplicatedStorage.Shared.RemoteContracts` entry.

## Validation

Use Rojo for source sync/build. Current automated gates are documented in `.omx/TestResults.md` and the G013 docs under `.omx/`.
