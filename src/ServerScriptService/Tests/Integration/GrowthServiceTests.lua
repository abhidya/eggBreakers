local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local ProgressionService = require(game:GetService("ServerScriptService").Services.ProgressionService)
local suite = { name = "GrowthServiceTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "growth from survival/eating", run = function()
    local p = MockPlayer.new(35001, "GrowthTester"); local state = SurvivalService:CreateState(p, "gallimimus")
    Assert.truthy(SurvivalService:AddGrowth(p, 25), "server can add growth")
    Assert.equals(state.GrowthStage, "Juvenile", "25 growth reaches juvenile")
end })

table.insert(suite.tests, { name = "stage updates stats/model/popup", run = function()
    local p = MockPlayer.new(35002, "GrowthTester2"); local state = SurvivalService:CreateState(p, "triceratops")
    SurvivalService:AddGrowth(p, 75)
    Assert.equals(state.GrowthStage, "Adult", "adult threshold applied")
    Assert.equals(state.Health, 190, "adult stats applied")
    Assert.equals(state.Stamina, 120, "adult stamina applied")
end })

table.insert(suite.tests, { name = "rewards server-side", run = function()
    local p = MockPlayer.new(35003, "RewardTester")
    local ok = ProgressionService:OnGrowthStage(p, "Juvenile")
    local ok2 = ProgressionService:OnGrowthStage(p, "Juvenile")
    Assert.truthy(ok, "first growth reward accepted")
    Assert.falsy(ok2, "duplicate growth reward rejected")
end })

return suite
