local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local requiredStages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }
local suite = { name = "SpeciesConfigTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "every species has required fields and stages", run = function()
    local count = 0
    for speciesId, species in pairs(SpeciesConfig) do
        count = count + 1
        Assert.equals(species.SpeciesId, speciesId, "SpeciesId matches key")
        Assert.notNil(species.DisplayName, "DisplayName required")
        Assert.truthy(species.Diet == "Herbivore" or species.Diet == "Carnivore", "Diet valid")
        Assert.notNil(species.Role, "Role required")
        Assert.notNil(species.Abilities.PrimaryAttack, "PrimaryAttack required")
        Assert.notNil(species.Abilities.SecondaryAbility, "SecondaryAbility required")
        for _, stage in ipairs(requiredStages) do
            local stats = species.BaseStats[stage]
            Assert.notNil(stats, "stats for " .. stage)
            Assert.truthy(stats.MaxHealth > 0, "MaxHealth positive")
            Assert.truthy(stats.WalkSpeed > 0, "WalkSpeed positive")
            Assert.truthy(stats.SprintSpeed >= stats.WalkSpeed, "SprintSpeed >= WalkSpeed")
            Assert.truthy(stats.MaxStamina > 0, "MaxStamina positive")
            Assert.truthy(stats.Damage >= 0, "Damage nonnegative")
            Assert.truthy(species.ModelPaths[stage] ~= nil, "model path for " .. stage)
        end
    end
    Assert.equals(count, 4, "vertical slice has exactly four starter species")
end })

table.insert(suite.tests, { name = "starter species diet roles stay fixed", run = function()
    Assert.equals(SpeciesConfig.gallimimus.Diet, "Herbivore")
    Assert.equals(SpeciesConfig.triceratops.Diet, "Herbivore")
    Assert.equals(SpeciesConfig.velociraptor.Diet, "Carnivore")
    Assert.equals(SpeciesConfig.carnotaurus.Diet, "Carnivore")
end })

return TestRunner.registerSuite(suite)
