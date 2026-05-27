local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local suite = { name = "HungerThirstTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "needs drain and clamp", run = function()
    local player = MockPlayer.new(201, "NeedsTester")
    local state = SurvivalService:CreateState(player, "gallimimus")
    state.Hatched = true
    SurvivalService:ApplyNeedsTick(player, 10)
    Assert.truthy(state.Hunger < 100, "hunger drains")
    Assert.truthy(state.Thirst < 100, "thirst drains")
    SurvivalService:ApplyNeedsTick(player, 10000)
    Assert.equals(state.Hunger, 0)
    Assert.equals(state.Thirst, 0)
end })

table.insert(suite.tests, { name = "starvation damages after depletion", run = function()
    local player = MockPlayer.new(202, "StarveTester")
    local state = SurvivalService:CreateState(player, "gallimimus")
    state.Hatched = true
    state.Hunger = 0
    state.Thirst = 0
    local health = state.Health
    SurvivalService:ApplyNeedsTick(player, 1)
    Assert.truthy(state.Health < health, "health decreases")
end })

return TestRunner.registerSuite(suite)
