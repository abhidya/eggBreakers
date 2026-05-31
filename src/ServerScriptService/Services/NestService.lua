local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local NestService = { Nests = {} }
NestService.Distance = 16

NestService.MaxEggSlots = 3

function NestService:RequestNestAction(player, actionType, nestInstance)
    if not RemoteValidationService:CheckRate(player, "RequestNestAction") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not state or state.GrowthStage ~= "Adult" then return false, "not_adult" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not RemoteValidationService:HasTag(nestInstance, "NestZone") then return false, "bad_nest_zone" end
    if not RemoteValidationService:IsClose(root, nestInstance, self.Distance) then return false, "too_far" end

    -- Reuse an existing claim on this nest so claiming + laying are cumulative,
    -- otherwise start a fresh claim record for this adult.
    local nest = self.Nests[player]
    if not nest or nest.Instance ~= nestInstance then
        nest = { Owner = player, Instance = nestInstance, Eggs = 0, Outcome = { EggSlots = 1, HatchlingBuff = "NestRested" } }
        self.Nests[player] = nest
    end
    nest.UpdatedAt = os.time()
    nest.Action = actionType

    if actionType == "LayEgg" then
        if nest.Eggs >= self.MaxEggSlots then return false, "nest_full" end
        nest.Eggs = nest.Eggs + 1
    end

    local outcome = nest.Outcome
    outcome.EggSlots = math.max(outcome.EggSlots or 1, nest.Eggs > 0 and nest.Eggs or 1)
    state.NestRespawn = nestInstance
    state.NestEggSlots = outcome.EggSlots
    state.NestEggCount = nest.Eggs
    state.HatchlingBuff = outcome.HatchlingBuff
    return true, nest
end

-- Returns the nest claim record bound to the player, or nil.
function NestService:GetNest(player)
    return self.Nests[player]
end

-- Hatch-from-nest: a dead player whose state still points at a parented nest can
-- consume one laid egg (if any) to respawn at that nest with the nest hatchling buff.
-- Returns (true, newState) on success or (false, reason). Additive + safe when the
-- world/nest is absent; callers in ServerMain own the actual character respawn.
function NestService:RequestHatchFromNest(player)
    if not RemoteValidationService:CheckRate(player, "RequestNestAction") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not state then return false, "no_state" end
    if not state.Dead then return false, "not_dead" end
    local nestInstance = state.NestRespawn
    if not (nestInstance and nestInstance.Parent) then return false, "no_nest" end

    local nest = self.Nests[player]
    if nest and nest.Instance == nestInstance and (nest.Eggs or 0) > 0 then
        nest.Eggs = nest.Eggs - 1
        nest.UpdatedAt = os.time()
    end

    local newState = SurvivalService:Respawn(player)
    newState.HatchlingBuff = (nest and nest.Outcome and nest.Outcome.HatchlingBuff) or "NestRested"
    newState.NestEggCount = nest and nest.Eggs or 0
    return true, newState
end

return NestService
