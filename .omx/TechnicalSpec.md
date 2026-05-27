# Technical Spec

- Rojo maps `src/ReplicatedStorage`, `src/ServerScriptService`, `src/StarterPlayer`, `src/StarterGui`, and `src/Workspace`.
- Startup: `ServerMain.server.lua` requires `ServerScriptService/Bootstrap.lua` ModuleScript and calls `Init()`.
- Services live under `ServerScriptService/Services` and own server authority.
- Client controllers only request actions through remotes; server validates state, diet, distance, rates, and ownership.
