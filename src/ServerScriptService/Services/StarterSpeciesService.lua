local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)

local StarterSpeciesService = {}
StarterSpeciesService.StarterOrder = { "coelophysis", "parasaurolophus", "utahraptor", "citipati" }

function StarterSpeciesService:GetUnlockedStarterSpecies(data)
    local unlocked = data and data.UnlockedSpecies or {}
    local result = {}
    for _, speciesId in ipairs(self.StarterOrder) do
        if unlocked[speciesId] == true and SpeciesConfig[speciesId] then
            table.insert(result, speciesId)
        end
    end
    if #result == 0 then
        for _, speciesId in ipairs(self.StarterOrder) do
            if SpeciesConfig[speciesId] then
                table.insert(result, speciesId)
            end
        end
    end
    return result
end

function StarterSpeciesService:ChooseStarterSpecies(data, roll)
    local candidates = self:GetUnlockedStarterSpecies(data)
    if #candidates == 0 then return Constants.DefaultSpeciesId end
    if type(roll) == "number" then
        local index = math.clamp(math.floor(roll), 1, #candidates)
        local chosen = candidates[index]
        if type(data) == "table" then
            data.LastStarterSpecies = chosen
        end
        return chosen
    end
    local lastSpecies = type(data) == "table" and data.LastStarterSpecies or nil
    local index = math.random(1, #candidates)
    if #candidates > 1 and candidates[index] == lastSpecies then
        index = (index % #candidates) + 1
    end
    local chosen = candidates[index]
    if type(data) == "table" then
        data.LastStarterSpecies = chosen
    end
    return chosen
end

-- Full selectable / hatch pool: EVERY playable species in SpeciesConfig (the full
-- staged roster, ~52 species). Sourced from SpeciesConfig keys so the selection UI
-- offers the whole roster, not just the curated starters. Sorted for stable ordering.
function StarterSpeciesService:GetSelectableSpecies()
    local ids = {}
    for speciesId, entry in pairs(SpeciesConfig) do
        if type(entry) == "table" and entry.SpeciesId == speciesId and not Constants.RetiredPrototypeSpecies[speciesId] then
            ids[#ids + 1] = speciesId
        end
    end
    table.sort(ids)
    return ids
end

-- The selectable pool a given player may hatch. By default the FULL roster so every
-- staged species is hatchable; honors an explicit unlock gate when present.
-- `requireUnlock` (optional) restricts to data.UnlockedSpecies when true.
function StarterSpeciesService:GetHatchPool(data, requireUnlock)
    if requireUnlock and type(data) == "table" and type(data.UnlockedSpecies) == "table" then
        local pool = {}
        for _, speciesId in ipairs(self:GetSelectableSpecies()) do
            if data.UnlockedSpecies[speciesId] == true then
                pool[#pool + 1] = speciesId
            end
        end
        if #pool > 0 then
            return pool
        end
    end
    return self:GetSelectableSpecies()
end

function StarterSpeciesService:HasCarnivoreAndHerbivore(data)
    local hasCarnivore = false
    local hasHerbivore = false
    for _, speciesId in ipairs(self:GetUnlockedStarterSpecies(data)) do
        local species = SpeciesConfig[speciesId]
        if species and species.Diet == "Carnivore" then hasCarnivore = true end
        if species and species.Diet == "Herbivore" then hasHerbivore = true end
    end
    return hasCarnivore and hasHerbivore
end

return StarterSpeciesService
