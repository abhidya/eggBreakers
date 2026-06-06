local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local PlayerDataService = {}
PlayerDataService.StoreName = "PlayerDataV1"
PlayerDataService.Store = nil
PlayerDataService.Profiles = {}

function PlayerDataService:GetStore()
    if not self.Store then
        self.Store = DataStoreService:GetDataStore(self.StoreName)
    end
    return self.Store
end

local STARTER_SPECIES = {
    coelophysis = true,
    parasaurolophus = true,
    utahraptor = true,
    citipati = true,
}

local function normalizeUnlockedSpecies(unlocked)
    unlocked = unlocked or {}
    for speciesId in pairs(Constants.RetiredPrototypeSpecies) do
        unlocked[speciesId] = nil
    end
    for speciesId in pairs(STARTER_SPECIES) do
        unlocked[speciesId] = true
    end
    return unlocked
end

function PlayerDataService.DefaultData(now)
    return {
        SchemaVersion = 1,
        DNA = 0,
        Fossils = 0,
        TutorialCompleted = false,
        UnlockedSpecies = normalizeUnlockedSpecies(table.clone(STARTER_SPECIES)),
        SpeciesMastery = {},
        CosmeticsOwned = {},
        EquippedCosmetics = {},
        BadgesEarnedLocal = {},
        Settings = { MusicVolume = 0.7, SFXVolume = 0.8, CameraShake = true, MobileButtonScale = 1.0 },
        LastStarterSpecies = nil,
        LastPlayedAt = now or os.time(),
    }
end

function PlayerDataService:Load(player)
    local key = tostring(player.UserId)
    local ok, data = pcall(function()
        return self:GetStore():GetAsync(key)
    end)
    if not ok or type(data) ~= "table" then
        data = self.DefaultData()
    end
    data.SchemaVersion = 1
    data.UnlockedSpecies = normalizeUnlockedSpecies(data.UnlockedSpecies or table.clone(STARTER_SPECIES))
    self.Profiles[player] = data
    return data
end

function PlayerDataService:Save(player)
    local data = self.Profiles[player]
    if not data then
        return false, "no profile loaded"
    end
    data.LastPlayedAt = os.time()
    local key = tostring(player.UserId)
    local ok, err = pcall(function()
        self:GetStore():SetAsync(key, data)
    end)
    if not ok then
        warn(("Failed to save PlayerDataV1 for %s: %s"):format(player.Name, tostring(err)))
        return false, err
    end
    return true
end

function PlayerDataService:GrantDNA(player, amount, reason)
    assert(type(amount) == "number" and amount >= 0, "server-only DNA grant amount must be non-negative")
    local data = self:Get(player)
    data.DNA = data.DNA + amount
    return true, reason
end

function PlayerDataService:GrantFossils(player, amount, reason)
    assert(type(amount) == "number" and amount >= 0, "server-only fossil grant amount must be non-negative")
    local data = self:Get(player)
    data.Fossils = data.Fossils + amount
    return true, reason
end

function PlayerDataService:Get(player)
    if not self.Profiles[player] then
        self.Profiles[player] = self.DefaultData()
    end
    return self.Profiles[player]
end

function PlayerDataService:UnlockSpecies(player, speciesId, costDNA)
    local data = self:Get(player)
    costDNA = costDNA or 0
    if data.UnlockedSpecies[speciesId] then
        return false, "already_unlocked"
    end
    if data.DNA < costDNA then
        return false, "not_enough_dna"
    end
    data.DNA = data.DNA - costDNA
    data.UnlockedSpecies[speciesId] = true
    return true
end

function PlayerDataService:Clear(player)
    self.Profiles[player] = nil
end

return PlayerDataService
