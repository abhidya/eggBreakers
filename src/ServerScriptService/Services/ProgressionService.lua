local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Shared.EconomyConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local ProgressionService = { SessionRewards = {} }

function ProgressionService:_bucket(player)
    self.SessionRewards[player] = self.SessionRewards[player] or {}
    return self.SessionRewards[player]
end

function ProgressionService:GrantOnce(player, key, currency, amount, reason)
    local bucket = self:_bucket(player)
    if bucket[key] then return false, "already_granted" end
    bucket[key] = true
    if currency == "DNA" then return PlayerDataService:GrantDNA(player, amount, reason) end
    if currency == "Fossils" then return PlayerDataService:GrantFossils(player, amount, reason) end
    return false, "bad_currency"
end

function ProgressionService:OnHatched(player)
    return self:GrantOnce(player, "FirstHatch", "DNA", EconomyConfig.DNARewards.FirstHatch, "first_hatch")
end

function ProgressionService:OnGrowthStage(player, stage)
    local rewards = {
        Juvenile = EconomyConfig.DNARewards.ReachJuvenile,
        SubAdult = EconomyConfig.DNARewards.ReachSubAdult,
        Adult = EconomyConfig.DNARewards.ReachAdult,
    }
    if rewards[stage] then
        return self:GrantOnce(player, "Reach" .. stage, "DNA", rewards[stage], "growth_" .. stage)
    end
    return false, "no_reward"
end

function ProgressionService:OnBiomeDiscovered(player, zoneId)
    if zoneId == "ApocalypticCity" then
        return self:GrantOnce(player, "DiscoverApocalypticCity", "DNA", EconomyConfig.DNARewards.DiscoverApocalypticCity, "discover_city")
    end
    return self:GrantOnce(player, "DiscoverBiome_" .. tostring(zoneId), "DNA", EconomyConfig.DNARewards.DiscoverBiome, "discover_biome")
end

function ProgressionService:Clear(player)
    self.SessionRewards[player] = nil
end

return ProgressionService
