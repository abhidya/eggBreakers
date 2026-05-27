# Remotes

Runtime creates required RemoteEvents via `ServerScriptService/Bootstrap.lua` from `Shared/RemoteContracts.lua`.
`Bootstrap.Init()` is idempotent and must be called before server systems bind remote handlers.
Required names: RequestHatch, RequestEat, RequestDrink, RequestAttack, RequestCall, RequestGroupInvite, RequestNestAction, RequestCollectFossil, StatUpdate, ClientNotification.
