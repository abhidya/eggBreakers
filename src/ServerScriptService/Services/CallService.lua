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
    marker.Transparency = 0.45
    marker.Material = Enum.Material.Neon
    marker.Color = callType == "Threat" and Color3.fromRGB(255, 80, 60)
        or callType == "Warning" and Color3.fromRGB(255, 210, 70)
        or callType == "BabyDistress" and Color3.fromRGB(120, 180, 255)
        or Color3.fromRGB(95, 255, 140)
    marker.Shape = Enum.PartType.Ball
    marker.Size = Vector3.new(math.max(6, radius / 10), 1, math.max(6, radius / 10))
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then marker.Position = root.Position + Vector3.new(0, 1.5, 0) end
    marker:SetAttribute("VisibleGameplayFeedback", true)
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
