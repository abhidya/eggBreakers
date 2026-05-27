local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatReplicationService = {}

function StatReplicationService:BuildPayload(state)
    return {
        health = state.Health,
        hunger = state.Hunger,
        thirst = state.Thirst,
        stamina = state.Stamina,
        growth = state.Growth,
        growthStage = state.GrowthStage,
        hatched = state.Hatched == true,
        hatchProgress = state.HatchProgress or 0,
        diet = state.Diet,
        species = state.SpeciesId,
        statusEffects = state.StatusEffects or {},
    }
end

function StatReplicationService:Send(player, state)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local statUpdate = remotes and remotes:FindFirstChild("StatUpdate")
    if statUpdate and state then
        statUpdate:FireClient(player, self:BuildPayload(state))
    end
end

function StatReplicationService:Notify(player, message, notificationType, duration, icon)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local event = remotes and remotes:FindFirstChild("ClientNotification")
    if event then
        event:FireClient(player, { message = message, type = notificationType or "Info", duration = duration or 3, icon = icon })
    end
end

return StatReplicationService
