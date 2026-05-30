local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)
local NPCService = require(script.Parent.NPCService)
-- StatReplicationService is lazy-loaded to avoid circular requires in tests
local _statRepl = nil
local function getStatRepl()
    if not _statRepl then
        local ok, svc = pcall(function() return require(script.Parent.StatReplicationService) end)
        if ok then _statRepl = svc end
    end
    return _statRepl
end

-- Lazy-load the Remotes folder so CombatService works even before Remotes exist in tests
local _remotes = nil
local function getRemotes()
    if not _remotes then
        _remotes = ReplicatedStorage:FindFirstChild("Remotes")
    end
    return _remotes
end

local CombatService = { LastAttack = {} }
CombatService.Range = { Bite = 9, HeavyBite = 10, Claw = 8, Lunge = 14, Headbutt = 9, Nibble = 6 }
CombatService.StaminaCost = { Bite = 14, HeavyBite = 24, Claw = 10, Lunge = 20, Headbutt = 16, Nibble = 6 }

-- Crit chance: 10% base
local CRIT_CHANCE = 0.10
local CRIT_MULTIPLIER = 1.75

function CombatService:AttackAllowedForSpecies(state, attackType)
    local species = SpeciesConfig[state.SpeciesId]
    return species.Abilities.PrimaryAttack == attackType or species.Abilities.SecondaryAbility == attackType
end

function CombatService:StampDamageAttributes(target, damage, attacker)
    target:SetAttribute("LastDamage", damage)
    target:SetAttribute("LastServerDamage", damage)
    target:SetAttribute("LastDamagedByUserId", attacker and attacker.UserId or 0)
    target:SetAttribute("PendingServerDamage", damage)
end

-- Fire CombatFeedback remote to all clients (additive; does not affect server authority)
function CombatService:FireCombatFeedback(target, damage, isCrit, npcRecord)
    local remotes = getRemotes()
    if not remotes then return end
    local remote = remotes:FindFirstChild("CombatFeedback")
    if not remote then return end

    local targetName = target.Name or "NPC"
    local position = Vector3.new(0, 0, 0)
    local root = target:IsA("Model") and target:FindFirstChild("HumanoidRootPart")
    if root then
        position = root.Position
    elseif target:IsA("BasePart") then
        position = target.Position
    elseif target:IsA("Model") and target.PrimaryPart then
        position = target.PrimaryPart.Position
    end

    local targetHealth = target:GetAttribute("Health") or 0
    local targetMaxHealth = target:GetAttribute("MaxHealth") or 100
    if npcRecord then
        targetHealth = npcRecord.Health or targetHealth
        targetMaxHealth = npcRecord.MaxHealth or targetMaxHealth
    end

    -- Fire to all players (broadcast feedback so group members see it too)
    remote:FireAllClients({
        targetName    = targetName,
        position      = position,
        damage        = damage,
        targetHealth  = targetHealth,
        targetMaxHealth = targetMaxHealth,
        isCrit        = isCrit,
    })
end

function CombatService:ApplyDamage(target, damage, attacker, isCrit)
    if not target then return false, "missing_target" end
    local npcRecord = NPCService:FindRecordForInstance(target)
    if npcRecord then
        local ok, reason = NPCService:DamageRecord(npcRecord, damage)
        self:StampDamageAttributes(target, damage, attacker)
        target:SetAttribute("Health", npcRecord.Health)
        if npcRecord.State == "Dead" then
            target:SetAttribute("Dead", true)
            target:SetAttribute("Defeated", true)
            if npcRecord.Carcass then
                target:SetAttribute("CarcassFoodSource", npcRecord.Carcass.Name)
            end
        end
        self:FireCombatFeedback(target, damage, isCrit, npcRecord)
        return ok, reason
    end
    local humanoid = target:IsA("Model") and target:FindFirstChildOfClass("Humanoid") or nil
    if humanoid then
        humanoid:TakeDamage(damage)
        target:SetAttribute("Health", humanoid.Health)
    else
        local currentHealth = target:GetAttribute("Health")
        if currentHealth == nil then currentHealth = target:GetAttribute("MaxHealth") or target:GetAttribute("DamageableHealth") or 25 end
        local nextHealth = math.max(0, currentHealth - damage)
        target:SetAttribute("Health", nextHealth)
        target:SetAttribute("DamageableHealth", nextHealth)
        if nextHealth <= 0 then
            target:SetAttribute("Dead", true)
            target:SetAttribute("Defeated", true)
        end
    end
    self:StampDamageAttributes(target, damage, attacker)
    self:FireCombatFeedback(target, damage, isCrit, nil)
    return true
end

-- Lane D: Determine whether a diet/species qualifies as a carnivore or omnivore predator.
function CombatService:IsPredatorDiet(diet)
    return diet == "Carnivore" or diet == "Omnivore"
end

-- Lane D: Resolve which player owns a character model (nil if none / same player).
function CombatService:GetPlayerFromCharacter(character)
    if not character then return nil end
    return Players:GetPlayerFromCharacter(character)
end

-- Lane D: Core player-predation reward handler called AFTER the victim is already dead
-- (kill was applied via SurvivalService:ApplyDamage → Kill). This function:
--   1. Computes and grants growth reward to killer with stage-gap anti-grief scaling.
--   2. Spawns a player carcass food source at victim's last position.
--   3. Notifies both parties via StatReplicationService:Notify.
-- Does NOT call Kill again — that already happened upstream.
-- All authority is server-side; no client input is trusted for damage/death.
function CombatService:HandlePlayerPredation(killerPlayer, killerState, victimPlayer, victimState)
    local killerName = killerPlayer and killerPlayer.Name or "a carnivore"

    -- Growth reward with anti-grief stage-gap scaling.
    local reward = SurvivalService:ComputePredationGrowthReward(
        killerState.GrowthStage,
        victimState.GrowthStage,
        8 -- base growth points for hunting a player
    )
    if reward > 0 then
        SurvivalService:AddGrowth(killerPlayer, reward)
    end

    -- Spawn player carcass food source at victim's last position.
    -- Other carnivore/omnivore players and NPC predators can eat it for hunger + growth.
    local carcass = NPCService:CreatePlayerCarcassFoodSource(victimPlayer, victimState)

    -- Notify killer ("You fed on X").
    local statRepl = getStatRepl()
    if statRepl then
        local rewardMsg = reward > 0
            and string.format("You fed on %s (+%d growth)", victimPlayer.Name, reward)
            or string.format("You fed on %s (no growth — size advantage too great)", victimPlayer.Name)
        statRepl:Notify(killerPlayer, rewardMsg, "Predation", 5, "Skull")
    end

    -- Notify victim ("You were hunted by X"). Respawn-as-egg is handled by the
    -- existing SurvivalService death flow (DeathCallbacks → respawn).
    if statRepl then
        statRepl:Notify(victimPlayer,
            string.format("You were hunted by %s", killerName),
            "Death", 5, "Skull")
    end

    return true, carcass
end

function CombatService:RequestAttack(player, attackType, target)
    if not RemoteValidationService:CheckRate(player, "RequestAttack") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    -- Safe-zone check on attacker.
    if state.SafeLocked then return false, "safe_locked" end
    if not self:AttackAllowedForSpecies(state, attackType) then return false, "bad_attack" end
    if target then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not RemoteValidationService:HasTag(target, "Damageable") then return false, "not_damageable" end
        if not RemoteValidationService:IsClose(root, target, self.Range[attackType] or 8) then return false, "too_far" end
    end
    local cost = self.StaminaCost[attackType] or 10
    if not SurvivalService:ConsumeStamina(player, cost) then return false, "no_stamina" end
    if target then
        local damage = SpeciesConfig[state.SpeciesId].BaseStats[state.GrowthStage].Damage
        -- Roll for crit server-side
        local isCrit = math.random() < CRIT_CHANCE
        if isCrit then
            damage = math.floor(damage * CRIT_MULTIPLIER)
        end

        -- Lane D: detect if target is another player's character and the attacker is a predator.
        local victimPlayer = self:GetPlayerFromCharacter(target)
        if victimPlayer and victimPlayer ~= player and self:IsPredatorDiet(state.Diet) then
            -- Attacker safe-zone already checked above; check victim safe-zone here.
            if SurvivalService:IsInSafeZone(victimPlayer) then
                return false, "victim_in_safe_zone"
            end
            local victimState = SurvivalService:GetState(victimPlayer)
            if not victimState or victimState.Dead then
                return false, "victim_already_dead"
            end
            -- Apply damage server-side; if this kills the victim, HandlePlayerPredation fires
            -- via the PlayerKilledCallbacks registered below.
            local ok, updatedState = SurvivalService:ApplyDamage(victimPlayer, damage, "CarnivoreAttack")
            if ok and updatedState and updatedState.Dead then
                -- Kill already called internally; predation hook fires via Kill.
                -- Directly handle predation rewards here since Kill has already run.
                self:HandlePlayerPredation(player, state, victimPlayer, victimState)
            end
            self:FireCombatFeedback(target, damage, isCrit, nil)
        else
            -- NPC or non-predator-vs-player path (existing behaviour preserved).
            self:ApplyDamage(target, damage, player, isCrit)
        end
    end
    return true, state
end

return CombatService
