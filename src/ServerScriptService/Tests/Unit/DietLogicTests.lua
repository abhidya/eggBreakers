local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local suite = { name = "DietLogicTests", category = "Unit", tests = {} }

local function canEat(diet, foodDiet, depleted)
    return not depleted and (diet == foodDiet or diet == "Omnivore")
end

table.insert(suite.tests, { name = "herbivore and carnivore diet matrix", run = function()
    Assert.truthy(canEat("Herbivore", "Herbivore", false))
    Assert.falsy(canEat("Herbivore", "Carnivore", false))
    Assert.truthy(canEat("Carnivore", "Carnivore", false))
    Assert.falsy(canEat("Carnivore", "Herbivore", false))
    Assert.truthy(canEat("Omnivore", "Herbivore", false))
    Assert.truthy(canEat("Omnivore", "Carnivore", false))
    Assert.falsy(canEat("Herbivore", "Herbivore", true))
end })

table.insert(suite.tests, { name = "starter diets align with roles", run = function()
    Assert.equals(SpeciesConfig.gallimimus.Diet, "Herbivore")
    Assert.equals(SpeciesConfig.carnotaurus.Diet, "Carnivore")
end })

return TestRunner.registerSuite(suite)
