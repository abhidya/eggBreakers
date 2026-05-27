local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local suite = { name = "CombatFormulaTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "attack damage exists in species config", run = function()
    for _, species in pairs(SpeciesConfig) do
        for stage, stats in pairs(species.BaseStats) do
            Assert.truthy(stats.Damage >= 0, species.SpeciesId .. " " .. stage .. " damage")
        end
    end
end })

table.insert(suite.tests, { name = "invalid attack and dead player fail", run = function()
    local player = MockPlayer.new(401, "CombatTester")
    local state = SurvivalService:CreateState(player, "gallimimus")
    Assert.falsy(CombatService:AttackAllowedForSpecies(state, "Laser"))
    SurvivalService:Kill(player, "test")
    local ok = CombatService:RequestAttack(player, "Nibble", nil)
    Assert.falsy(ok)
end })

return TestRunner.registerSuite(suite)
