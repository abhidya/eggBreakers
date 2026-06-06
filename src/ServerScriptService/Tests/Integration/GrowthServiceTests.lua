local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local ProgressionService = require(game:GetService("ServerScriptService").Services.ProgressionService)
local suite = { name = "GrowthServiceTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "growth from survival/eating", run = function()
    local p = MockPlayer.new(35001, "GrowthTester"); local state = SurvivalService:CreateState(p, "parasaurolophus")
    Assert.truthy(SurvivalService:AddGrowth(p, 25), "server can add growth")
    Assert.equals(state.GrowthStage, "Juvenile", "25 growth reaches juvenile")
end })

table.insert(suite.tests, { name = "stage updates stats/model/popup", run = function()
    local p = MockPlayer.new(35002, "GrowthTester2"); local state = SurvivalService:CreateState(p, "parasaurolophus")
    SurvivalService:AddGrowth(p, 75)
    Assert.equals(state.GrowthStage, "Adult", "adult threshold applied")
    Assert.equals(state.Health, 190, "adult stats applied")
    Assert.equals(state.Stamina, 120, "adult stamina applied")
end })


table.insert(suite.tests, { name = "eat and drink loop reaches bigger juvenile state", run = function()
    local CollectionService = game:GetService("CollectionService")
    local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
    local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
    local p = MockPlayer.new(35004, "FoodWaterGrowthTester")
    RateLimitService:ClearPlayer(p)
    local state = SurvivalService:CreateState(p, "parasaurolophus")
    state.Hatched = true
    state.Growth = 23
    state.Hunger = 40
    state.Thirst = 40
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local food = Instance.new("Part"); food.Position = Vector3.new(2, 3, 0); food:SetAttribute("Diet", "Herbivore"); food:SetAttribute("Nutrition", 25); food.Parent = workspace; CollectionService:AddTag(food, "FoodSource")
    local water = Instance.new("Part"); water.Position = Vector3.new(3, 3, 0); water.Parent = workspace; CollectionService:AddTag(water, "WaterSource")

    Assert.truthy(FoodWaterService:RequestEat(p, food), "eat succeeds")
    RateLimitService:ClearPlayer(p)
    Assert.truthy(FoodWaterService:RequestDrink(p, water), "drink succeeds")
    Assert.equals(state.GrowthStage, "Juvenile", "food plus water growth reaches visibly larger juvenile stage")
    Assert.truthy(state.Hunger > 40, "hunger restored")
    Assert.truthy(state.Thirst > 40, "thirst restored")
    food:Destroy(); water:Destroy()
end })

table.insert(suite.tests, { name = "rewards server-side", run = function()
    local p = MockPlayer.new(35003, "RewardTester")
    local ok = ProgressionService:OnGrowthStage(p, "Juvenile")
    local ok2 = ProgressionService:OnGrowthStage(p, "Juvenile")
    Assert.truthy(ok, "first growth reward accepted")
    Assert.falsy(ok2, "duplicate growth reward rejected")
end })

return suite
