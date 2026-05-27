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

function CityDiscoveryService:Clear(player)
    self.Discovered[player] = nil
end

return CityDiscoveryService
