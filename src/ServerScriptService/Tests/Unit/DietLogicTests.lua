local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local suite = { name = "DietLogicTests", category = "Unit", tests = {} }

local function canEat(diet, foodDiet, depleted)
    return not depleted and (diet == "Omnivore" or foodDiet == "Omnivore" or diet == foodDiet)
end

table.insert(suite.tests, { name = "herbivore carnivore and omnivore diet matrix", run = function()
    Assert.truthy(canEat("Herbivore", "Herbivore", false))
    Assert.falsy(canEat("Herbivore", "Carnivore", false))
    Assert.truthy(canEat("Carnivore", "Carnivore", false))
    Assert.falsy(canEat("Carnivore", "Herbivore", false))
    Assert.truthy(canEat("Omnivore", "Herbivore", false))
    Assert.truthy(canEat("Omnivore", "Carnivore", false))
    Assert.truthy(canEat("Herbivore", "Omnivore", false))
    Assert.falsy(canEat("Herbivore", "Herbivore", true))
end })

table.insert(suite.tests, { name = "starter diets align with roles", run = function()
    Assert.equals(SpeciesConfig.parasaurolophus.Diet, "Herbivore")
    Assert.equals(SpeciesConfig.utahraptor.Diet, "Carnivore")
    Assert.equals(SpeciesConfig.oviraptor.Diet, "Omnivore")
end })

return TestRunner.registerSuite(suite)
