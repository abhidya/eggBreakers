local RemoteContracts = {
    RequestHatch = { Direction = "ClientToServer", Arguments = { inputType = "string" }, RateLimitSeconds = 0.2 },
    RequestEat = { Direction = "ClientToServer", Arguments = { targetInstance = "Instance" }, RateLimitSeconds = 0.5 },
    RequestDrink = { Direction = "ClientToServer", Arguments = { targetInstance = "Instance" }, RateLimitSeconds = 0.5 },
    RequestSwim = { Direction = "ClientToServer", Arguments = { waterInstance = "Instance" }, RateLimitSeconds = 0.4 },
    RequestFlight = { Direction = "ClientToServer", Arguments = { enabled = "boolean" }, RateLimitSeconds = 0.4 },
    RequestSprint = { Direction = "ClientToServer", Arguments = { enabled = "boolean" }, RateLimitSeconds = 0.25 },
    RequestSelectSpecies = { Direction = "ClientToServer", Arguments = { speciesId = "string" }, RateLimitSeconds = 0.25 },
    RequestAttack = { Direction = "ClientToServer", Arguments = { attackType = "string", targetInstance = "Instance?" }, RateLimitSeconds = 0.4 },
    RequestCall = { Direction = "ClientToServer", Arguments = { callType = "string" }, RateLimitSeconds = 2.0 },
    RequestGroupInvite = { Direction = "ClientToServer", Arguments = { targetPlayer = "Player" }, RateLimitSeconds = 3.0 },
    RequestGroupAccept = { Direction = "ClientToServer", Arguments = { fromPlayer = "Player" }, RateLimitSeconds = 1.0 },
    RequestNestAction = { Direction = "ClientToServer", Arguments = { actionType = "string", nestInstance = "Instance" }, RateLimitSeconds = 1.0 },
    RequestCollectFossil = { Direction = "ClientToServer", Arguments = { fossilInstance = "Instance" }, RateLimitSeconds = 0.75 },
    RequestHatchFromNest = { Direction = "ClientToServer", Arguments = {}, RateLimitSeconds = 1.0 },
    RequestPromoteAlpha = { Direction = "ClientToServer", Arguments = {}, RateLimitSeconds = 2.0 },
    StatUpdate = { Direction = "ServerToClient", Payload = { "health", "hunger", "thirst", "stamina", "oxygen", "maxOxygen", "growth", "growthStage", "diet", "species", "creatureCategory", "swimming", "flying", "sprinting", "movementModes", "ecosystemProfile", "statusEffects" } },
    ClientNotification = { Direction = "ServerToClient", Payload = { "message", "type", "duration", "icon" } },
    CombatFeedback = { Direction = "ServerToClient", Payload = { "kind", "targetName", "position", "damage", "targetHealth", "targetMaxHealth", "isCrit", "isApex" } },
    CombatTelegraph = { Direction = "ServerToClient", Payload = { "kind", "attackType", "attackerName", "attackerUserId", "position", "targetName", "targetPosition", "windupSeconds" } },
    PlayActionSound = { Direction = "ServerToClient", Payload = { "category", "position", "soundId" } },
}

return RemoteContracts
