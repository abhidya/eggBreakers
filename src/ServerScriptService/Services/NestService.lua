local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local NestService = { Nests = {} }
NestService.Distance = 16

function NestService:RequestNestAction(player, actionType, nestInstance)
    if not RemoteValidationService:CheckRate(player, "RequestNestAction") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not state or state.GrowthStage ~= "Adult" then return false, "not_adult" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not RemoteValidationService:HasTag(nestInstance, "NestZone") then return false, "bad_nest_zone" end
    if not RemoteValidationService:IsClose(root, nestInstance, self.Distance) then return false, "too_far" end
    self.Nests[player] = { Owner = player, Instance = nestInstance, UpdatedAt = os.time(), Action = actionType }
    state.NestRespawn = nestInstance
    state.NestEggSlots = math.max(state.NestEggSlots or 0, actionType == "Create" and 1 or 0)
    state.HatchlingBuff = state.HatchlingBuff or { Source = "Nest", HungerBonus = 5, ThirstBonus = 5 }
    return true, self.Nests[player]
end

return NestService
