local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)
local WaterService = require(script.Parent.WaterService)
local OxygenService = require(script.Parent.OxygenService)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)

local SwimService = {}
SwimService.SwimDistance = 16
SwimService.StaminaCost = 4

-- ---------------------------------------------------------------------------
-- IsSwimCapableSpecies
-- Server-authoritative check: returns true when SpeciesConfig declares
-- MovementModes.Swim == true for the given speciesId.
-- ---------------------------------------------------------------------------
function SwimService:IsSwimCapableSpecies(speciesId)
    if not speciesId then return false end
    local cfg = SpeciesConfig[speciesId]
    return cfg ~= nil
        and cfg.MovementModes ~= nil
        and cfg.MovementModes.Swim == true
end

-- ---------------------------------------------------------------------------
-- RequestSwim
-- Validates the swim request server-side.  Swim is only permitted when:
--   1. Rate limit passes.
--   2. Player is alive and hatched.
--   3. The target is a valid water source.
--   4. The player's root is within SwimDistance of that water source.
--   5. The player's species can swim (SpeciesConfig gate).
--   6. The player has enough stamina.
-- ---------------------------------------------------------------------------
function SwimService:RequestSwim(player, water)
    if not RemoteValidationService:CheckRate(player, "RequestSwim") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    if not WaterService:IsWaterSource(water) then return false, "not_water" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not RemoteValidationService:IsClose(root, water, self.SwimDistance) then return false, "too_far" end
    -- Species gate: only MovementModes.Swim species can enter swim state.
    if not self:IsSwimCapableSpecies(state.SpeciesId) then return false, "swim_locked" end
    if not SurvivalService:ConsumeStamina(player, self.StaminaCost) then return false, "low_stamina" end
    state.Swimming = true
    state.Flying = false
    state.CurrentWaterSource = water.Name
    -- Seed oxygen from species stat so OxygenService clamp uses the right cap.
    OxygenService:EnsureOxygen(state)
    state.MovementState = "Swimming"
    state.MovementSurface = "Swim"
    return true, state
end

function SwimService:StopSwimming(player)
    local state = SurvivalService:GetState(player)
    if not state then return false, "missing_state" end
    state.Swimming = false
    state.CurrentWaterSource = nil
    state.MovementState = state.Flying and "Flying" or "Grounded"
    state.MovementSurface = state.Flying and "Flight" or "Ground"
    return true, state
end

return SwimService
