# Remote Contracts

Source of truth: `src/ReplicatedStorage/Shared/RemoteContracts.lua`.

`Bootstrap.Init()` creates exactly one `RemoteEvent` for each contract under `ReplicatedStorage.Remotes`:
RequestHatch, RequestEat, RequestDrink, RequestAttack, RequestCall, RequestGroupInvite, RequestNestAction, RequestCollectFossil, StatUpdate, ClientNotification.
