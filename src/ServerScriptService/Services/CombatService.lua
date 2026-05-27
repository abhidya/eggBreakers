local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local CombatService = { LastAttack = {} }
CombatService.Range = { Bite = 9, HeavyBite = 10, Claw = 8, Lunge = 14, Headbutt = 9, Nibble = 6 }
CombatService.StaminaCost = { Bite = 14, HeavyBite = 24, Claw = 10, Lunge = 20, Headbutt = 16, Nibble = 6 }

function CombatService:AttackAllowedForSpecies(state, attackType)
    local species = SpeciesConfig[state.SpeciesId]
    return species.Abilities.PrimaryAttack == attackType or species.Abilities.SecondaryAbility == attackType
end

function CombatService:ApplyDamageToTarget(target, damage)
    local humanoid = target and (target:IsA("Humanoid") and target or target:FindFirstChildOfClass("Humanoid"))
    if humanoid then
        humanoid:TakeDamage(damage)
        return true, humanoid.Health
    end
    local currentHealth = target:GetAttribute("Health") or target:GetAttribute("DamageableHealth") or target:GetAttribute("MaxHealth") or 25
    local nextHealth = math.max(0, currentHealth - damage)
    target:SetAttribute("Health", nextHealth)
    target:SetAttribute("DamageableHealth", nextHealth)
    target:SetAttribute("LastServerDamage", damage)
    if nextHealth <= 0 then
        target:SetAttribute("Dead", true)
    end
    return true, nextHealth
end

function CombatService:RequestAttack(player, attackType, target)
    if not RemoteValidationService:CheckRate(player, "RequestAttack") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
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
        self:ApplyDamageToTarget(target, damage)
    end
    return true, state
end

return CombatService
