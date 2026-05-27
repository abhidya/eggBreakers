local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local RateLimitService = require(script.Parent.RateLimitService)

local RemoteValidationService = {}

function RemoteValidationService:CheckRate(player, remoteName)
    local contract = RemoteContracts[remoteName]
    return RateLimitService:Check(player, remoteName, contract and contract.RateLimitSeconds or 1)
end

function RemoteValidationService:IsAlive(state)
    return state and state.Dead ~= true and state.Health and state.Health > 0
end

function RemoteValidationService:IsHatched(state)
    return state and state.Hatched == true
end

function RemoteValidationService:IsClose(playerRoot, target, maxDistance)
    if not playerRoot or not target or not target:IsDescendantOf(workspace) then
        return false
    end
    local targetPosition = target:IsA("BasePart") and target.Position or target:GetPivot().Position
    return (playerRoot.Position - targetPosition).Magnitude <= maxDistance
end

function RemoteValidationService:HasTag(instance, tag)
    return instance ~= nil and CollectionService:HasTag(instance, tag)
end

function RemoteValidationService:ValidateFoodTarget(playerRoot, target, diet, maxDistance)
    if not self:HasTag(target, Constants.Tags.FoodSource) then return false, "target_not_food" end
    if not self:IsClose(playerRoot, target, maxDistance) then return false, "too_far" end
    if target:GetAttribute("Depleted") then return false, "depleted" end
    if target:GetAttribute("Diet") ~= diet then return false, "wrong_diet" end
    return true
end

return RemoteValidationService
