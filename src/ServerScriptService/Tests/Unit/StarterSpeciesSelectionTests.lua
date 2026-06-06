local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local StarterSpeciesService = require(ServerScriptService.Services.StarterSpeciesService)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local NPCService = require(ServerScriptService.Services.NPCService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)

local suite = { name = "StarterSpeciesSelectionTests", category = "Unit", tests = {} }

local defaultData = {
    UnlockedSpecies = {
        coelophysis = true,
        parasaurolophus = true,
        utahraptor = true,
        citipati = true,
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
    local chosen = StarterSpeciesService:ChooseStarterSpecies({ UnlockedSpecies = {} }, 3)
    Assert.equals(chosen, "utahraptor", "fallback pool still allows carnivore starter")
end })

table.insert(suite.tests, { name = "random starter avoids repeating previous life when possible", run = function()
    local data = {
        UnlockedSpecies = {
            coelophysis = true,
            parasaurolophus = true,
            utahraptor = true,
            citipati = true,
        },
        LastStarterSpecies = "parasaurolophus",
    }
    for _ = 1, 25 do
        local chosen = StarterSpeciesService:ChooseStarterSpecies(data)
        Assert.falsy(chosen == "parasaurolophus", "next random starter should not repeat the last life when alternatives exist")
        data.LastStarterSpecies = "parasaurolophus"
    end
end })

table.insert(suite.tests, { name = "retired prototypes stay out of hatch and NPC routes", run = function()
    local selectable = StarterSpeciesService:GetSelectableSpecies()
    local hatchPool = StarterSpeciesService:GetHatchPool()
    local seenSelectable = {}
    local seenHatch = {}
    for _, speciesId in ipairs(selectable) do
        seenSelectable[speciesId] = true
    end
    for _, speciesId in ipairs(hatchPool) do
        seenHatch[speciesId] = true
    end

    for speciesId in pairs(Constants.RetiredPrototypeSpecies) do
        Assert.falsy(seenSelectable[speciesId], speciesId .. " is absent from selectable species")
        Assert.falsy(seenHatch[speciesId], speciesId .. " is absent from hatch pool")
    end

    for kind, speciesId in pairs(MapLayoutService.NPCKindSpeciesIds) do
        Assert.falsy(Constants.RetiredPrototypeSpecies[speciesId], kind .. " does not route to retired species")
        Assert.notNil(SpeciesConfig[speciesId], kind .. " routes to playable species")
    end

    for kind, profile in pairs(NPCService.KindProfiles) do
        Assert.falsy(Constants.RetiredPrototypeSpecies[profile.SpeciesId], kind .. " profile does not use retired species")
        Assert.notNil(SpeciesConfig[profile.SpeciesId], kind .. " profile uses playable species")
    end

    local retiredSpawn = MapLayoutService:GetPlayerSpawnForSpecies("gallimimus")
    Assert.equals(retiredSpawn, nil, "retired species does not silently use default spawn")
end })

table.insert(suite.tests, { name = "random hatch option rolls from the full playable roster", run = function()
    local hatchPool = StarterSpeciesService:GetHatchPool()
    Assert.truthy(#hatchPool >= 50, "random option has the full 50+ dinosaur roster available")
    local first = StarterSpeciesService:ChooseRandomHatchSpecies(nil, 1)
    local last = StarterSpeciesService:ChooseRandomHatchSpecies(nil, #hatchPool)
    Assert.equals(first, hatchPool[1], "deterministic low roll chooses first full-roster species")
    Assert.equals(last, hatchPool[#hatchPool], "deterministic high roll chooses last full-roster species")
    Assert.notNil(SpeciesConfig[first], "first random species is playable")
    Assert.notNil(SpeciesConfig[last], "last random species is playable")
    Assert.falsy(Constants.RetiredPrototypeSpecies[first], "first random species is not retired")
    Assert.falsy(Constants.RetiredPrototypeSpecies[last], "last random species is not retired")
    Assert.falsy(first == Constants.RandomStarterSpeciesId, "random sentinel is not part of playable species")
    Assert.falsy(last == Constants.RandomStarterSpeciesId, "random sentinel is not part of playable species")
end })

table.insert(suite.tests, { name = "random hatch option can be gated to renderable happy paths", run = function()
    local chosen = StarterSpeciesService:ChooseRandomHatchSpecies(nil, 1, function(speciesId)
        return speciesId == "utahraptor"
    end)
    Assert.equals(chosen, "utahraptor", "predicate-filtered random pool chooses the renderable candidate")

    local none, reason = StarterSpeciesService:ChooseRandomHatchSpecies(nil, 1, function()
        return false
    end)
    Assert.equals(none, nil, "empty visual-ready pool returns nil instead of a fallback species")
    Assert.equals(reason, "no_renderable_random_species", "empty visual-ready pool reports the gate failure")
end })

return TestRunner.registerSuite(suite)
