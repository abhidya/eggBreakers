local RemoteValidationService = require(script.Parent.RemoteValidationService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local FossilService = { Collected = {} }
FossilService.Distance = 12

function FossilService:RequestCollect(player, fossil)
    if not RemoteValidationService:CheckRate(player, "RequestCollectFossil") then return false, "rate_limited" end
    if not RemoteValidationService:HasTag(fossil, "Fossil") then return false, "not_fossil" end
    local key = fossil:GetDebugId()
    self.Collected[player] = self.Collected[player] or {}
    if self.Collected[player][key] then return false, "already_collected" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not RemoteValidationService:IsClose(root, fossil, self.Distance) then return false, "too_far" end
    self.Collected[player][key] = true
    PlayerDataService:GrantFossils(player, fossil:GetAttribute("FossilReward") or 1, "fossil_collect")
    fossil:SetAttribute("Collected", true)
    return true
end

return FossilService
