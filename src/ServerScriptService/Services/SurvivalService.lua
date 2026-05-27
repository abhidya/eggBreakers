local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local SurvivalService = { States = {}, NeedsLoopConnection = nil, NeedsLoopAccumulator = 0, NeedsTickSeconds = 1, DeathCallbacks = {} }

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function SurvivalService:CreateState(player, speciesId)
    local species = SpeciesConfig[speciesId or "gallimimus"] or SpeciesConfig.gallimimus or SpeciesConfig.leafling_runner
    if not species then
        for _, candidate in pairs(SpeciesConfig) do
            if type(candidate) == "table" and candidate.BaseStats then
                species = candidate
                break
            end
        end
    end
    assert(species and species.BaseStats, "valid species config required")
    local stage = "Hatchling"
    local stats = species.BaseStats[stage]
    local state = {
        Player = player,
        SpeciesId = species.SpeciesId,
        Diet = species.Diet,
        GrowthStage = stage,
        Growth = 0,
        Hatched = false,
        HatchProgress = 0,
        Health = stats.MaxHealth,
        Hunger = 100,
        Thirst = 100,
        Stamina = stats.MaxStamina,
        Oxygen = stats.MaxOxygen or 100,
        MaxOxygen = stats.MaxOxygen or 100,
        MovementModes = species.MovementModes or { Ground = true },
        CreatureCategory = species.CreatureCategory or "Unclassified",
        EcosystemProfile = species.EcosystemProfile or {},
        Dead = false,
        NestRespawn = nil,
    }
    self.States[player] = state
    return state
end

function SurvivalService:GetState(player)
    return self.States[player]
end

function SurvivalService:RequestHatch(player, inputType)
    local state = self:GetState(player) or self:CreateState(player)
    if state.Hatched or state.Dead then return false, "invalid_hatch_state" end
    if type(inputType) ~= "string" then return false, "bad_input" end
    state.HatchProgress = clamp(state.HatchProgress + 20, 0, 100)
    if state.HatchProgress >= 100 then
        state.Hatched = true
    end
    return true, state
end

function SurvivalService:ApplyNeedsTick(player, deltaSeconds)
    local state = self:GetState(player)
    if not state or not state.Hatched or state.Dead then return false end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species.BaseStats[state.GrowthStage]
    state.Hunger = clamp(state.Hunger - stats.HungerDrain * deltaSeconds, 0, 100)
    state.Thirst = clamp(state.Thirst - stats.ThirstDrain * deltaSeconds, 0, 100)
    state.Stamina = clamp(state.Stamina + (stats.StaminaRegen or 8) * deltaSeconds, 0, stats.MaxStamina)
    state.MaxOxygen = stats.MaxOxygen or state.MaxOxygen or 100
    state.Oxygen = clamp((state.Oxygen or state.MaxOxygen) + (stats.OxygenRegen or 12) * deltaSeconds, 0, state.MaxOxygen)
    if state.Hunger <= 0 or state.Thirst <= 0 then
        self:ApplyDamage(player, 3 * deltaSeconds, "Starvation/Dehydration")
    end
    return true, state
end

function SurvivalService:ApplyDamage(player, amount, cause)
    local state = self:GetState(player)
    if not state or state.Dead then return false, "not_alive" end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species.BaseStats[state.GrowthStage]
    state.Health = clamp(state.Health - math.max(0, amount or 0), 0, stats.MaxHealth)
    if state.Health <= 0 then
        self:Kill(player, cause or "Damage")
    end
    return true, state
end

function SurvivalService:AddGrowth(player, amount)
    local state = self:GetState(player)
    if not state or state.Dead then return false end
    state.Growth = clamp(state.Growth + amount, 0, 100)
    local nextStage = state.Growth >= 75 and "Adult" or state.Growth >= 50 and "SubAdult" or state.Growth >= 25 and "Juvenile" or "Hatchling"
    if nextStage ~= state.GrowthStage then
        state.GrowthStage = nextStage
        local stats = SpeciesConfig[state.SpeciesId].BaseStats[nextStage]
        state.Health = stats.MaxHealth
        state.Stamina = stats.MaxStamina
        state.MaxOxygen = stats.MaxOxygen or state.MaxOxygen or 100
        state.Oxygen = state.MaxOxygen
    end
    return true, state
end

function SurvivalService:ConsumeStamina(player, amount)
    local state = self:GetState(player)
    if not state or state.Dead or state.Hatched ~= true then return false end
    if state.Stamina < amount then return false end
    state.Stamina = state.Stamina - amount
    return true
end

function SurvivalService:GetSpeciesProfile(stateOrSpeciesId)
    local speciesId = type(stateOrSpeciesId) == "table" and stateOrSpeciesId.SpeciesId or stateOrSpeciesId
    local species = SpeciesConfig[speciesId or "gallimimus"] or SpeciesConfig.gallimimus
    if not species then return nil end
    return {
        speciesId = species.SpeciesId,
        diet = species.Diet,
        creatureCategory = species.CreatureCategory or "Unclassified",
        movementModes = species.MovementModes or { Ground = true },
        ecosystemProfile = species.EcosystemProfile or {},
    }
end

function SurvivalService:ApplySwimOxygenTick(player, isSubmerged, deltaSeconds)
    local state = self:GetState(player)
    if not state or state.Dead or state.Hatched ~= true then return false, "not_alive_hatched" end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species.BaseStats[state.GrowthStage]
    state.MaxOxygen = stats.MaxOxygen or state.MaxOxygen or 100
    if isSubmerged then
        state.Oxygen = clamp((state.Oxygen or state.MaxOxygen) - (stats.OxygenDrain or 10) * (deltaSeconds or 1), 0, state.MaxOxygen)
        if state.Oxygen <= 0 then
            self:ApplyDamage(player, (stats.DrowningDamage or 8) * (deltaSeconds or 1), "Drowning")
        end
    else
        state.Oxygen = clamp((state.Oxygen or state.MaxOxygen) + (stats.OxygenRegen or 12) * (deltaSeconds or 1), 0, state.MaxOxygen)
    end
    return true, state
end

function SurvivalService:ConsumeFlightStamina(player, deltaSeconds)
    local state = self:GetState(player)
    if not state or state.Dead or state.Hatched ~= true then return false, "not_alive_hatched" end
    if not state.MovementModes or state.MovementModes.Flight ~= true then return false, "flight_unavailable" end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species.BaseStats[state.GrowthStage]
    local drain = (stats.FlightStaminaDrain or 18) * (deltaSeconds or 1)
    if (state.Stamina or 0) < drain then return false, "stamina_empty" end
    state.Stamina = state.Stamina - drain
    return true, state
end

function SurvivalService:OnDeath(callback)
    table.insert(self.DeathCallbacks, callback)
    return function()
        for index, candidate in ipairs(self.DeathCallbacks) do
            if candidate == callback then
                table.remove(self.DeathCallbacks, index)
                break
            end
        end
    end
end

function SurvivalService:StartNeedsLoop(intervalSeconds, playersService, statReplicationService)
    if self.NeedsLoopConnection then
        return false, "already_running"
    end
    self.NeedsTickSeconds = intervalSeconds or self.NeedsTickSeconds or 1
    self.NeedsLoopAccumulator = 0
    playersService = playersService or Players
    self.NeedsLoopConnection = RunService.Heartbeat:Connect(function(deltaSeconds)
        self.NeedsLoopAccumulator = self.NeedsLoopAccumulator + deltaSeconds
        if self.NeedsLoopAccumulator < self.NeedsTickSeconds then
            return
        end
        local elapsed = self.NeedsLoopAccumulator
        self.NeedsLoopAccumulator = 0
        for _, player in ipairs(playersService:GetPlayers()) do
            local ok, state = self:ApplyNeedsTick(player, elapsed)
            if ok and statReplicationService then
                statReplicationService:Send(player, state)
            end
        end
    end)
    return true
end

function SurvivalService:StopNeedsLoop()
    if self.NeedsLoopConnection then
        self.NeedsLoopConnection:Disconnect()
        self.NeedsLoopConnection = nil
    end
    self.NeedsLoopAccumulator = 0
end

function SurvivalService:Kill(player, cause)
    local state = self:GetState(player)
    if not state then return false end
    if state.Dead == true then return true, state end
    state.Health = 0
    state.Dead = true
    state.DeathCause = cause
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
    for _, callback in ipairs(self.DeathCallbacks) do
        task.spawn(callback, player, state)
    end
    return true, state
end

function SurvivalService:Respawn(player)
    local old = self:GetState(player)
    local speciesId = old and old.SpeciesId or "gallimimus"
    return self:CreateState(player, speciesId)
end

return SurvivalService
