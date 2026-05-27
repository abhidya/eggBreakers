local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "WaterServiceTests.server", category = "Integration", tests = {} }

local function setup(id, dist)
    local p = MockPlayer.new(id, "WaterTester"); RateLimitService:ClearPlayer(p)
    SurvivalService:CreateState(p, "gallimimus").Hatched = true
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local water = Instance.new("Part"); water.Name = "TestWater"; water.Position = Vector3.new(dist or 3, 3, 0); water.Parent = workspace; CollectionService:AddTag(water, "WaterSource")
    return p, water
end

table.insert(suite.tests, { name = "valid water drink", run = function()
    local p, water = setup(33001, 3)
    SurvivalService:GetState(p).Thirst = 40
    Assert.truthy(FoodWaterService:RequestDrink(p, water), "near water succeeds")
    water:Destroy()
end })

table.insert(suite.tests, { name = "distance invalid water fail", run = function()
    local p, water = setup(33002, 50)
    local ok, reason = FoodWaterService:RequestDrink(p, water)
    Assert.falsy(ok, "far water rejected")
    Assert.equals(reason, "too_far", "distance reason")
    water:Destroy()
end })

table.insert(suite.tests, { name = "thirst updates", run = function()
    local p, water = setup(33003, 2)
    local state = SurvivalService:GetState(p); state.Thirst = 30
    FoodWaterService:RequestDrink(p, water)
    Assert.between(state.Thirst, 64, 100, "thirst restored")
    water:Destroy()
end })

return suite
