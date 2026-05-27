local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local FoodWaterService = {}
FoodWaterService.EatDistance = 12
FoodWaterService.DrinkDistance = 14

function FoodWaterService:RequestEat(player, target)
    if not RemoteValidationService:CheckRate(player, "RequestEat") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local ok, reason = RemoteValidationService:ValidateFoodTarget(root, target, state.Diet, self.EatDistance)
    if not ok then return false, reason end
    state.Hunger = math.min(100, state.Hunger + (target:GetAttribute("Nutrition") or 25))
    target:SetAttribute("Depleted", true)
    SurvivalService:AddGrowth(player, 1)
    return true, state
end

function FoodWaterService:RequestDrink(player, target)
    if not RemoteValidationService:CheckRate(player, "RequestDrink") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) then return false, "not_alive" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not RemoteValidationService:HasTag(target, "WaterSource") then return false, "not_water" end
    if not RemoteValidationService:IsClose(root, target, self.DrinkDistance) then return false, "too_far" end
    state.Thirst = math.min(100, state.Thirst + 35)
    return true, state
end

return FoodWaterService
