local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local StarterSpeciesService = require(ServerScriptService.Services.StarterSpeciesService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local suite = { name = "StarterSpeciesSelectionTests", category = "Unit", tests = {} }

local defaultData = {
    UnlockedSpecies = {
        gallimimus = true,
        triceratops = true,
        velociraptor = true,
        carnotaurus = true,
    },
}

table.insert(suite.tests, { name = "starter pool includes herbivores and carnivores", run = function()
    local pool = StarterSpeciesService:GetUnlockedStarterSpecies(defaultData)
    Assert.equals(#pool, 4, "all four vertical-slice species are eligible starters")
    Assert.truthy(StarterSpeciesService:HasCarnivoreAndHerbivore(defaultData), "starter pool has both diets")
end })

table.insert(suite.tests, { name = "roll can pick every starter species", run = function()
    for index, speciesId in ipairs(StarterSpeciesService.StarterOrder) do
        local chosen = StarterSpeciesService:ChooseStarterSpecies(defaultData, index)
        Assert.equals(chosen, speciesId, "roll chooses " .. speciesId)
        Assert.notNil(SpeciesConfig[chosen], "chosen species exists")
    end
end })

table.insert(suite.tests, { name = "locked profile falls back to full starter pool", run = function()
    local chosen = StarterSpeciesService:ChooseStarterSpecies({ UnlockedSpecies = {} }, 4)
    Assert.equals(chosen, "carnotaurus", "fallback pool still allows carnivore starter")
end })

table.insert(suite.tests, { name = "random starter avoids repeating previous life when possible", run = function()
    local data = {
        UnlockedSpecies = {
            gallimimus = true,
            triceratops = true,
            velociraptor = true,
            carnotaurus = true,
        },
        LastStarterSpecies = "gallimimus",
    }
    for _ = 1, 25 do
        local chosen = StarterSpeciesService:ChooseStarterSpecies(data)
        Assert.falsy(chosen == "gallimimus", "next random starter should not repeat the last life when alternatives exist")
        data.LastStarterSpecies = "gallimimus"
    end
end })

return TestRunner.registerSuite(suite)
