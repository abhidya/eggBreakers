local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local suite = { name = "HungerThirstTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "needs drain and clamp", run = function()
    local player = MockPlayer.new(201, "NeedsTester")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.Stamina = 0
    SurvivalService:ApplyNeedsTick(player, 10)
    Assert.truthy(state.Hunger < 100, "hunger drains")
    Assert.truthy(state.Stamina > 0, "stamina regens")
    Assert.truthy(state.Thirst < 100, "thirst drains")
    SurvivalService:ApplyNeedsTick(player, 10000)
    Assert.equals(state.Hunger, 0)
    Assert.equals(state.Thirst, 0)
end })

table.insert(suite.tests, { name = "starvation damages after depletion", run = function()
    local player = MockPlayer.new(202, "StarveTester")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.Hunger = 0
    state.Thirst = 0
    local health = state.Health
    SurvivalService:ApplyNeedsTick(player, 1)
    Assert.truthy(state.Health < health, "health decreases")
end })

table.insert(suite.tests, { name = "rest slows needs and restores stamina health", run = function()
    local player = MockPlayer.new(203, "RestTester")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.Hunger = 80
    state.Thirst = 80
    state.Health = state.Health - 10
    state.Stamina = 0
    local ok = SurvivalService:SetResting(player, true)
    Assert.truthy(ok, "rest starts")
    SurvivalService:ApplyNeedsTick(player, 2)
    Assert.equals(state.Resting, true, "state is resting")
    Assert.equals(state.SleepState, "Resting", "sleep state readable")
    Assert.truthy(state.Stamina > 0, "rest restores stamina")
    Assert.truthy(state.Health > 0, "rest allows health recovery")
    Assert.truthy(state.Hunger > 75, "rest slows hunger drain")
end })

table.insert(suite.tests, { name = "retired and unknown species do not silently create default state", run = function()
    local retiredPlayer = MockPlayer.new(204, "RetiredSpeciesTester")
    local retiredOk = pcall(function()
        SurvivalService:CreateState(retiredPlayer, "gallimimus")
    end)
    Assert.falsy(retiredOk, "retired prototype species should fail explicit state creation")
    local selectOk, selectReason = SurvivalService:SelectSpecies(retiredPlayer, "gallimimus")
    Assert.falsy(selectOk, "retired prototype species cannot be selected")
    Assert.equals(selectReason, "unknown_species", "retired selection fails explicitly")

    local unknownProfile = SurvivalService:GetSpeciesProfile("missing_species")
    Assert.equals(unknownProfile, nil, "unknown species profile is not silently defaulted")

    local defaultPlayer = MockPlayer.new(205, "DefaultSpeciesTester")
    local defaultState = SurvivalService:CreateState(defaultPlayer)
    Assert.equals(defaultState.SpeciesId, "coelophysis", "nil species still uses configured default")
end })

return TestRunner.registerSuite(suite)
