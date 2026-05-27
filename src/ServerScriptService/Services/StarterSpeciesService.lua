local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local StarterSpeciesService = {}
StarterSpeciesService.StarterOrder = { "gallimimus", "triceratops", "velociraptor", "carnotaurus" }

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
    if #candidates == 0 then return "gallimimus" end
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
