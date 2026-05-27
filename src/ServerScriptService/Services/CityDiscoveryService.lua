local Players = game:GetService("Players")
local ProgressionService = require(script.Parent.ProgressionService)
local StatReplicationService = require(script.Parent.StatReplicationService)

local CityDiscoveryService = { Discovered = {} }

function CityDiscoveryService:Discover(player, zoneId)
    if zoneId ~= "ApocalypticCity" then
        return ProgressionService:OnBiomeDiscovered(player, zoneId)
    end
    self.Discovered[player] = self.Discovered[player] or {}
    if self.Discovered[player].ApocalypticCity then return false, "already_discovered" end
    self.Discovered[player].ApocalypticCity = true
    ProgressionService:OnBiomeDiscovered(player, "ApocalypticCity")
    StatReplicationService:Notify(player, "Old Eden discovered", "Discovery", 5, "City")
    return true
end

function CityDiscoveryService:BindTrigger(triggerPart)
    if not triggerPart or triggerPart:GetAttribute("CityDiscoveryBound") then return false end
    triggerPart:SetAttribute("CityDiscoveryBound", true)
    triggerPart.Touched:Connect(function(hit)
        local character = hit and hit.Parent
        local player = character and Players:GetPlayerFromCharacter(character)
        if player then
            self:Discover(player, triggerPart:GetAttribute("ZoneId") or "ApocalypticCity")
        end
    end)
    return true
end

function CityDiscoveryService:BindTriggers(root)
    local bound = 0
    for _, instance in ipairs((root or workspace):GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("CityDiscoveryTrigger") == true then
            if self:BindTrigger(instance) then bound = bound + 1 end
        end
    end
    return bound
end

function CityDiscoveryService:Clear(player)
    self.Discovered[player] = nil
end

return CityDiscoveryService
