local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local suite = { name = "GrowthLogicTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "growth thresholds map to stages and clamp", run = function()
    local player = MockPlayer.new(101, "GrowthTester")
    SurvivalService:CreateState(player, "parasaurolophus")
    SurvivalService:AddGrowth(player, 25)
    Assert.equals(SurvivalService:GetState(player).GrowthStage, "Juvenile")
    SurvivalService:AddGrowth(player, 25)
    Assert.equals(SurvivalService:GetState(player).GrowthStage, "SubAdult")
    SurvivalService:AddGrowth(player, 25)
    Assert.equals(SurvivalService:GetState(player).GrowthStage, "Adult")
    SurvivalService:AddGrowth(player, 999)
    Assert.equals(SurvivalService:GetState(player).Growth, 100)
end })

table.insert(suite.tests, { name = "death resets life state but not account service", run = function()
    local player = MockPlayer.new(102, "DeathTester")
    SurvivalService:CreateState(player, "parasaurolophus")
    Assert.truthy(SurvivalService:Kill(player, "test"))
    Assert.truthy(SurvivalService:GetState(player).Dead)
    local state = SurvivalService:Respawn(player)
    Assert.falsy(state.Dead)
    Assert.equals(state.GrowthStage, "Hatchling")
end })

table.insert(suite.tests, { name = "health zero kills humanoid and invokes death callback", run = function()
    local player = MockPlayer.new(103, "ZeroHealthDeathTester")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    local humanoid = Instance.new("Humanoid")
    humanoid.Health = 12
    local character = Instance.new("Model")
    humanoid.Parent = character
    player.Character = character
    local called = false
    local disconnect = SurvivalService:OnDeath(function(deadPlayer, deadState)
        if deadPlayer == player and deadState == state then
            called = true
        end
    end)
    local ok = SurvivalService:ApplyDamage(player, 999, "test_zero")
    disconnect()
    Assert.truthy(ok, "damage accepted")
    Assert.equals(state.Health, 0, "state health clamped to zero")
    Assert.equals(state.Dead, true, "zero health sets Dead")
    Assert.equals(state.DeathCause, "test_zero", "death cause recorded")
    Assert.equals(humanoid.Health, 0, "humanoid killed for live death flow")
    Assert.truthy(called, "death callback invoked")
end })

return TestRunner.registerSuite(suite)
