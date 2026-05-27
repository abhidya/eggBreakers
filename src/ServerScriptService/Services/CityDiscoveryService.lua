local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ProgressionService = require(script.Parent.ProgressionService)
local StatReplicationService = require(script.Parent.StatReplicationService)

local CityDiscoveryService = { Discovered = {}, TriggerConnections = {} }

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

function CityDiscoveryService:GetTriggerFolder()
    local map = Workspace:FindFirstChild("Map") or Workspace
    local folder = map:FindFirstChild("CityDiscoveryTriggers")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CityDiscoveryTriggers"
        folder.Parent = map
    end
    return folder
end

function CityDiscoveryService:HandleTriggerTouched(trigger, hit)
    local character = hit and hit.Parent
    local player = character and Players:GetPlayerFromCharacter(character)
    if not player then return false, "no_player" end
    return self:Discover(player, trigger:GetAttribute("ZoneId") or "ApocalypticCity")
end

function CityDiscoveryService:BindTrigger(trigger)
    if not trigger or self.TriggerConnections[trigger] then return false, "already_bound" end
    self.TriggerConnections[trigger] = trigger.Touched:Connect(function(hit)
        self:HandleTriggerTouched(trigger, hit)
    end)
    trigger:SetAttribute("DiscoveryTriggerBound", true)
    return true
end

function CityDiscoveryService:EnsureCityTrigger(zoneId, position)
    zoneId = zoneId or "ApocalypticCity"
    local folder = self:GetTriggerFolder()
    local trigger = folder:FindFirstChild(zoneId .. "Trigger")
    if not trigger then
        trigger = Instance.new("Part")
        trigger.Name = zoneId .. "Trigger"
        trigger.Anchored = true
        trigger.CanCollide = false
        trigger.CanTouch = true
        trigger.CanQuery = true
        trigger.Transparency = 1
        trigger.Size = Vector3.new(60, 24, 60)
        trigger.Position = position or Vector3.new(0, 12, -220)
        trigger:SetAttribute("ZoneId", zoneId)
        trigger:SetAttribute("DiscoveryTrigger", true)
        trigger.Parent = folder
    end
    self:BindTrigger(trigger)
    return trigger
end

function CityDiscoveryService:EnsureCityDiscoveryTriggers()
    return self:EnsureCityTrigger("ApocalypticCity")
end

function CityDiscoveryService:Clear(player)
    self.Discovered[player] = nil
end

return CityDiscoveryService
