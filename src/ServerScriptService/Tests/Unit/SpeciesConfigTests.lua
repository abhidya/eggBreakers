local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)
local requiredStages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }
local suite = { name = "SpeciesConfigTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "every species has required fields and stages", run = function()
    local count = 0
    for speciesId, species in pairs(SpeciesConfig) do
        count = count + 1
        Assert.equals(species.SpeciesId, speciesId, "SpeciesId matches key")
        Assert.notNil(species.DisplayName, "DisplayName required")
        Assert.truthy(species.Diet == "Herbivore" or species.Diet == "Carnivore" or species.Diet == "Omnivore", "Diet valid")
        Assert.notNil(species.CreatureCategory, "CreatureCategory required")
        Assert.notNil(species.EcosystemProfile, "EcosystemProfile required")
        Assert.notNil(species.MovementModes, "MovementModes required")
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
            Assert.truthy(stats.StaminaRegen > 0, "StaminaRegen positive")
            Assert.truthy(stats.MaxOxygen > 0, "MaxOxygen positive")
            Assert.notNil(stats.FlightStaminaDrain, "FlightStaminaDrain declared")
            Assert.truthy(stats.Damage >= 0, "Damage nonnegative")
            Assert.truthy(species.ModelPaths[stage] ~= nil, "model path for " .. stage)
        end
    end
    Assert.truthy(count >= Constants.ScopeFreeze.RequiredPlayableSpecies, "vertical slice keeps required starter species")
    -- The full staged roster is now playable, minus the four retired prototype
    -- species. Curated imported dinos plus staged replacements keep at least 48
    -- playable species while excluding the old starter ids from runtime config.
    Assert.truthy(count <= Constants.ScopeFreeze.MaxPlayableSpecies, "playable roster stays within full-roster cap")
    Assert.truthy(count >= 48, "full staged roster (>=48 distinct playable species) is available")
end })

table.insert(suite.tests, { name = "starter species diet roles stay fixed", run = function()
    Assert.equals(SpeciesConfig.coelophysis.Diet, "Carnivore")
    Assert.equals(SpeciesConfig.parasaurolophus.Diet, "Herbivore")
    Assert.equals(SpeciesConfig.utahraptor.Diet, "Carnivore")
    Assert.equals(SpeciesConfig.citipati.Diet, "Omnivore")
end })

table.insert(suite.tests, { name = "retired prototype species are not playable", run = function()
    for speciesId in pairs(Constants.RetiredPrototypeSpecies) do
        Assert.equals(SpeciesConfig[speciesId], nil, speciesId .. " is retired from runtime species config")
    end
end })

table.insert(suite.tests, { name = "ecosystem expansion profiles cover apex herding and omnivore", run = function()
    Assert.equals(SpeciesConfig.tyrannosaurus.EcosystemProfile.Category, "Apex", "apex category profile")
    Assert.equals(SpeciesConfig.tyrannosaurus.EcosystemProfile.Apex, true, "apex flag")
    Assert.truthy(SpeciesConfig.tyrannosaurus.UnlockCostDNA >= 3000, "apex unlock cost")
    Assert.equals(SpeciesConfig.oviraptor.Diet, "Omnivore", "omnivore diet profile")
    Assert.equals(SpeciesConfig.oviraptor.EcosystemProfile.Herding, true, "omnivore herding profile")
end })

return TestRunner.registerSuite(suite)
