local RemoteContracts = {
    RequestHatch = { Direction = "ClientToServer", Arguments = { inputType = "string" }, RateLimitSeconds = 0.2 },
    RequestEat = { Direction = "ClientToServer", Arguments = { targetInstance = "Instance" }, RateLimitSeconds = 0.5 },
    RequestDrink = { Direction = "ClientToServer", Arguments = { targetInstance = "Instance" }, RateLimitSeconds = 0.5 },
    RequestAttack = { Direction = "ClientToServer", Arguments = { attackType = "string", targetInstance = "Instance?" }, RateLimitSeconds = 0.4 },
    RequestCall = { Direction = "ClientToServer", Arguments = { callType = "string" }, RateLimitSeconds = 2.0 },
    RequestGroupInvite = { Direction = "ClientToServer", Arguments = { targetPlayer = "Player" }, RateLimitSeconds = 3.0 },
    RequestGroupAccept = { Direction = "ClientToServer", Arguments = { fromPlayer = "Player" }, RateLimitSeconds = 1.0 },
    RequestNestAction = { Direction = "ClientToServer", Arguments = { actionType = "string", nestInstance = "Instance" }, RateLimitSeconds = 1.0 },
    RequestCollectFossil = { Direction = "ClientToServer", Arguments = { fossilInstance = "Instance" }, RateLimitSeconds = 0.75 },
    StatUpdate = { Direction = "ServerToClient", Payload = { "health", "hunger", "thirst", "stamina", "growth", "growthStage", "diet", "species", "statusEffects" } },
    ClientNotification = { Direction = "ServerToClient", Payload = { "message", "type", "duration", "icon" } },
}

return RemoteContracts
