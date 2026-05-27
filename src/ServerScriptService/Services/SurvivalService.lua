local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local SurvivalService = { States = {}, TickLoopStarted = false }
SurvivalService.NeedsTickSeconds = 1

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

function SurvivalService:StartNeedsLoop(playersService, statReplicationService)
    if self.TickLoopStarted then return false, "already_started" end
    self.TickLoopStarted = true
    task.spawn(function()
        while self.TickLoopStarted do
            task.wait(self.NeedsTickSeconds)
            for _, player in ipairs((playersService or game:GetService("Players")):GetPlayers()) do
                local ok, state = self:ApplyNeedsTick(player, self.NeedsTickSeconds)
                if ok and statReplicationService then
                    statReplicationService:Send(player, state)
                end
            end
        end
    end)
    return true
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
    end
    return true, state
end

function SurvivalService:ConsumeStamina(player, amount)
    local state = self:GetState(player)
    if not state or not state.Hatched or state.Dead then return false end
    if state.Stamina < amount then return false end
    state.Stamina = state.Stamina - amount
    return true
end

function SurvivalService:Kill(player, cause)
    local state = self:GetState(player)
    if not state then return false end
    state.Dead = true
    state.DeathCause = cause
    return true
end

function SurvivalService:Respawn(player)
    local old = self:GetState(player)
    local speciesId = old and old.SpeciesId or "gallimimus"
    return self:CreateState(player, speciesId)
end

return SurvivalService
