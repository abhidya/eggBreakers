local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)

-- SurvivalService tracks per-player survival state and drives the needs loop.
-- Lane D additions: PlayerKilledByCarnivore hooks for player predation flow.
local SurvivalService = { States = {}, NeedsLoopConnection = nil, NeedsLoopAccumulator = 0, NeedsTickSeconds = 1, DeathCallbacks = {}, PlayerKilledCallbacks = {} }
SurvivalService.SprintDrainPerSecond = 7
SurvivalService.RestNeedDrainMultiplier = 0.35
SurvivalService.RestStaminaRegenMultiplier = 2
SurvivalService.RestHealthRegenPerSecond = 2

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function SurvivalService:CreateState(player, speciesId)
    local defaultSpeciesId = Constants.DefaultSpeciesId or "coelophysis"
    local species = SpeciesConfig[speciesId or defaultSpeciesId] or SpeciesConfig[defaultSpeciesId] or SpeciesConfig.leafling_runner
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
        Resting = false,
        SleepState = "Awake",
        AgeSeconds = 0,
    }
    self.States[player] = state
    return state
end

function SurvivalService:GetState(player)
    return self.States[player]
end

function SurvivalService:SelectSpecies(player, speciesId)
    if type(speciesId) ~= "string" then return false, "bad_species" end
    local species = SpeciesConfig[speciesId]
    if not species or not species.BaseStats then return false, "unknown_species" end
    local current = self:GetState(player)
    if current and current.Hatched == true then return false, "already_hatched" end
    if current and current.Dead == true then return false, "invalid_hatch_state" end
    local nextState = self:CreateState(player, speciesId)
    nextState.SelectedBeforeHatch = true
    return true, nextState
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
    state.AgeSeconds = (state.AgeSeconds or 0) + deltaSeconds
    local resting = state.Resting == true
    local drainMultiplier = resting and self.RestNeedDrainMultiplier or 1
    state.Hunger = clamp(state.Hunger - stats.HungerDrain * deltaSeconds * drainMultiplier, 0, 100)
    state.Thirst = clamp(state.Thirst - stats.ThirstDrain * deltaSeconds * drainMultiplier, 0, 100)
    if state.Sprinting == true then
        state.Stamina = clamp(state.Stamina - self.SprintDrainPerSecond * deltaSeconds, 0, stats.MaxStamina)
        if state.Stamina <= 0 then
            state.Sprinting = false
        end
    else
        local regenMultiplier = resting and self.RestStaminaRegenMultiplier or 1
        state.Stamina = clamp(state.Stamina + (stats.StaminaRegen or 8) * regenMultiplier * deltaSeconds, 0, stats.MaxStamina)
    end
    if resting and state.Hunger > 15 and state.Thirst > 15 then
        state.Health = clamp(state.Health + self.RestHealthRegenPerSecond * deltaSeconds, 0, stats.MaxHealth)
    end
    state.MaxOxygen = stats.MaxOxygen or state.MaxOxygen or 100
    if state.Underwater ~= true then
        state.Oxygen = clamp((state.Oxygen or state.MaxOxygen) + (stats.OxygenRegen or 12) * deltaSeconds, 0, state.MaxOxygen)
    end
    if state.Hunger <= 0 or state.Thirst <= 0 then
        self:ApplyDamage(player, 3 * deltaSeconds, "Starvation/Dehydration")
    end
    return true, state
end

function SurvivalService:SetResting(player, enabled)
    local state = self:GetState(player)
    if not state or state.Dead or state.Hatched ~= true then return false, "not_alive_hatched" end
    state.Resting = enabled == true
    state.SleepState = state.Resting and "Resting" or "Awake"
    state.Sprinting = false
    state.Hidden = state.Resting
    local character = player and player.Character
    if character and character.SetAttribute then
        character:SetAttribute("Resting", state.Resting)
        character:SetAttribute("SleepState", state.SleepState)
        character:SetAttribute("Hidden", state.Hidden)
    end
    if player and player.SetAttribute then
        player:SetAttribute("Resting", state.Resting)
        player:SetAttribute("Hidden", state.Hidden)
    end
    return true, state
end

function SurvivalService:SetSprinting(player, enabled)
    local state = self:GetState(player)
    if not state or state.Dead or state.Hatched ~= true then return false, "not_alive_hatched" end
    if enabled == true and state.Resting == true then
        self:SetResting(player, false)
    end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species.BaseStats[state.GrowthStage]
    if enabled == true and (state.Stamina or 0) <= 3 then
        state.Sprinting = false
        return false, "low_stamina"
    end
    state.Sprinting = enabled == true
    state.CurrentWalkSpeed = state.Sprinting and math.floor((stats.WalkSpeed or 16) * 1.35) or stats.WalkSpeed
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
    state.JustMaturedTo = nil
    state.Growth = clamp(state.Growth + amount, 0, 100)
    local nextStage = state.Growth >= 75 and "Adult" or state.Growth >= 50 and "SubAdult" or state.Growth >= 25 and "Juvenile" or "Hatchling"
    if nextStage ~= state.GrowthStage then
        local previousStage = state.GrowthStage
        state.GrowthStage = nextStage
        local stats = SpeciesConfig[state.SpeciesId].BaseStats[nextStage]
        state.Health = stats.MaxHealth
        state.Stamina = stats.MaxStamina
        state.MaxOxygen = stats.MaxOxygen or state.MaxOxygen or 100
        state.Oxygen = state.MaxOxygen
        -- Growth/Alpha lane: mark that the player just matured this tick so callers
        -- (and the optional Alpha promotion) can react. Reaching Adult at full growth
        -- makes the player Alpha-eligible; the buff itself is opt-in via PromoteToAlpha.
        state.JustMaturedTo = nextStage
        if nextStage == "Adult" and previousStage ~= "Adult" then
            state.AlphaEligible = true
        end
        -- Apply the Alpha buff on top of the fresh Adult base stats if it was already
        -- granted on a prior life/stage cycle and the species is still Adult.
        if state.IsAlpha and nextStage == "Adult" then
            self:_applyAlphaBuff(state, stats)
        end
    end
    return true, state
end

-- Growth/Alpha lane: Alpha status is an optional apex buff for fully-grown adults.
-- It multiplies max health / stamina and grants a visible scale bump. Opt-in so the
-- base growth stage-up stats stay backward-compatible with existing tests.
SurvivalService.AlphaHealthMultiplier = 1.25
SurvivalService.AlphaStaminaMultiplier = 1.15
SurvivalService.AlphaDamageMultiplier = 1.2
SurvivalService.AlphaScale = 1.15

function SurvivalService:_applyAlphaBuff(state, stats)
    stats = stats or (SpeciesConfig[state.SpeciesId] and SpeciesConfig[state.SpeciesId].BaseStats[state.GrowthStage])
    if not stats then return end
    local maxHealth = math.floor(stats.MaxHealth * self.AlphaHealthMultiplier)
    local maxStamina = math.floor(stats.MaxStamina * self.AlphaStaminaMultiplier)
    state.AlphaMaxHealth = maxHealth
    state.AlphaMaxStamina = maxStamina
    state.AlphaDamageMultiplier = self.AlphaDamageMultiplier
    state.AlphaScale = self.AlphaScale
    state.Health = maxHealth
    state.Stamina = maxStamina
end

-- Promote a fully-grown adult to Alpha (apex) status. Returns false with a reason when
-- the player is not eligible. Idempotent: re-promoting an Alpha is a no-op success.
function SurvivalService:PromoteToAlpha(player)
    local state = self:GetState(player)
    if not state or state.Dead then return false, "not_alive" end
    if state.GrowthStage ~= "Adult" then return false, "not_adult" end
    if state.IsAlpha then return true, state end
    state.IsAlpha = true
    state.AlphaEligible = true
    local stats = SpeciesConfig[state.SpeciesId] and SpeciesConfig[state.SpeciesId].BaseStats[state.GrowthStage]
    self:_applyAlphaBuff(state, stats)
    return true, state
end

-- Effective outgoing damage for the player's current stage, including the Alpha bonus.
function SurvivalService:GetEffectiveDamage(player)
    local state = self:GetState(player)
    if not state then return 0 end
    local species = SpeciesConfig[state.SpeciesId]
    local stats = species and species.BaseStats[state.GrowthStage]
    local base = (stats and stats.Damage) or 0
    if state.IsAlpha then
        return base * (state.AlphaDamageMultiplier or self.AlphaDamageMultiplier)
    end
    return base
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
    local defaultSpeciesId = Constants.DefaultSpeciesId or "coelophysis"
    local species = SpeciesConfig[speciesId or defaultSpeciesId] or SpeciesConfig[defaultSpeciesId]
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

-- Lane D: Register a callback fired when a player is killed by a carnivore attacker.
-- Callback signature: callback(deadPlayer, deadState, killerPlayer, killerState)
-- killerPlayer / killerState may be nil if the killer is an NPC carnivore.
function SurvivalService:OnPlayerKilledByCarnivore(callback)
    table.insert(self.PlayerKilledCallbacks, callback)
    return function()
        for index, candidate in ipairs(self.PlayerKilledCallbacks) do
            if candidate == callback then
                table.remove(self.PlayerKilledCallbacks, index)
                break
            end
        end
    end
end

-- Lane D: Returns true if the player's character is currently inside a safe zone.
-- Checks SafeLocked flag (set by zone service) AND CollectionService "SafeZone" tag on
-- any part the character is touching (belt-and-suspenders).
function SurvivalService:IsInSafeZone(player)
    local state = self:GetState(player)
    if state and state.SafeLocked then return true end
    local character = player and player.Character
    if not character then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    -- Check overlapping parts for SafeZone tag
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    -- We check all world parts; CollectionService tag is the authority.
    local touching = workspace:GetPartBoundsInRadius(root.Position, 6, params)
    for _, part in ipairs(touching) do
        if CollectionService:HasTag(part, Constants.Tags.SafeZone) then
            return true
        end
    end
    return false
end

-- Lane D: Growth stage index for size-gating comparisons (higher = bigger).
local STAGE_RANK = { Hatchling = 1, Juvenile = 2, SubAdult = 3, Adult = 4 }

-- Lane D: Compute the predation growth reward for killer preying on victim.
-- Returns a value in [0, baseReward] with reduced reward for punching down.
-- Anti-grief rules:
--   Adult (rank 4) killing Hatchling (rank 1) → 0 growth (3+ stage gap).
--   Adult killing Juvenile (rank 2)            → 25 % of base (2 stage gap).
--   1-stage gap (e.g. SubAdult vs Juvenile)    → 75 % of base.
--   Same or victim larger                      → 100 % of base.
function SurvivalService:ComputePredationGrowthReward(killerStage, victimStage, baseReward)
    baseReward = baseReward or 8
    local killerRank = STAGE_RANK[killerStage] or 1
    local victimRank = STAGE_RANK[victimStage] or 1
    local gap = killerRank - victimRank
    if gap >= 3 then return 0 end
    if gap == 2 then return math.floor(baseReward * 0.25) end
    if gap == 1 then return math.floor(baseReward * 0.75) end
    return baseReward
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
    state.Resting = false
    state.SleepState = "Dead"
    state.DeathState = "Dying"
    state.DiedAtAgeSeconds = state.AgeSeconds or 0
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if character and character.SetAttribute then
        character:SetAttribute("DeathState", state.DeathState)
        character:SetAttribute("DeathCause", type(cause) == "string" and cause or "Damage")
        character:SetAttribute("DiedAtAgeSeconds", state.DiedAtAgeSeconds)
        character:SetAttribute("Resting", false)
        character:SetAttribute("SleepState", "Dead")
    end
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
    for _, callback in ipairs(self.DeathCallbacks) do
        task.spawn(callback, player, state)
    end
    -- Lane D: if the kill was inflicted by a carnivore player attacker, fire predation hooks.
    -- cause is expected to be a table { carnivoreKiller = <Player>, carnivoreKillerState = <state> }
    -- when set by CombatService:RequestAttack on a player target.
    if type(cause) == "table" and cause.carnivoreKiller then
        local killerPlayer = cause.carnivoreKiller
        local killerState = cause.carnivoreKillerState
        for _, cb in ipairs(self.PlayerKilledCallbacks) do
            task.spawn(cb, player, state, killerPlayer, killerState)
        end
    end
    return true, state
end

function SurvivalService:Respawn(player)
    local old = self:GetState(player)
    local speciesId = old and old.SpeciesId or (Constants.DefaultSpeciesId or "coelophysis")
    local nest = old and old.NestRespawn
    local newState = self:CreateState(player, speciesId)
    if nest and nest.Parent then
        newState.NestRespawn = nest
    end
    return newState
end

return SurvivalService
