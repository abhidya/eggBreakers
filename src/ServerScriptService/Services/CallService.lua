local Workspace = game:GetService("Workspace")
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local CallService = {}
CallService.Allowed = { Friendly = true, Warning = true, Threat = true, BabyDistress = true }

function CallService:GetEffectFolder()
    local folder = Workspace:FindFirstChild("CallEffects")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CallEffects"
        folder.Parent = Workspace
    end
    return folder
end

function CallService:CreateDebugMarker(player, callType, radius)
    local marker = Instance.new("Part")
    marker.Name = "VisibleCallPulse"
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Shape = Enum.PartType.Ball
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(120, 210, 255)
    marker.Transparency = 0.45
    marker.Size = Vector3.new(10, 10, 10)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then marker.Position = root.Position end
    marker:SetAttribute("VisibleActionEffect", true)
    marker:SetAttribute("CallType", callType)
    marker:SetAttribute("Radius", radius)
    marker:SetAttribute("SourceUserId", player.UserId)
    marker.Parent = self:GetEffectFolder()
    task.delay(4, function()
        if marker.Parent then marker:Destroy() end
    end)
    return marker
end

function CallService:RequestCall(player, callType)
    if not RemoteValidationService:CheckRate(player, "RequestCall") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    if not self.Allowed[callType] then return false, "bad_call" end
    local marker = self:CreateDebugMarker(player, callType, 80)
    return true, { Player = player, CallType = callType, Radius = 80, EffectMarker = marker, Marker = marker }
end

return CallService
