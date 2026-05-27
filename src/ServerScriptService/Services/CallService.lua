local Workspace = game:GetService("Workspace")
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local CallService = {}
CallService.Allowed = { Friendly = true, Warning = true, Threat = true, BabyDistress = true }

function CallService:CreateCallMarker(player, callType, radius)
    local folder = Workspace:FindFirstChild("CallEffects")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CallEffects"
        folder.Parent = Workspace
    end
    local marker = Instance.new("Part")
    marker.Name = "_INVISIBLE_Call_" .. tostring(callType)
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Transparency = 1
    marker.Size = Vector3.new(1, 1, 1)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    marker.Position = root and root.Position or Vector3.new(0, 0, 0)
    marker:SetAttribute("GameplayDebugMarker", true)
    marker:SetAttribute("CallType", callType)
    marker:SetAttribute("Radius", radius)
    marker:SetAttribute("ExpiresAt", os.time() + 4)
    marker.Parent = folder
    return marker
end

function CallService:RequestCall(player, callType)
    if not RemoteValidationService:CheckRate(player, "RequestCall") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    if not self.Allowed[callType] then return false, "bad_call" end
    local result = { Player = player, CallType = callType, Radius = 80 }
    result.Marker = self:CreateCallMarker(player, callType, result.Radius)
    return true, result
end

return CallService
