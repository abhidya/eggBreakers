local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local suite = { name = "FoodServiceTests.server", category = "Integration", tests = {} }

local function setup(id, diet)
    local p = MockPlayer.new(id, "FoodTester")
    RateLimitService:ClearPlayer(p)
    SurvivalService:CreateState(p, diet == "Carnivore" and "velociraptor" or "gallimimus").Hatched = true
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local food = Instance.new("Part"); food.Name = "TestFood"; food.Position = Vector3.new(3, 3, 0); food:SetAttribute("Diet", diet); food:SetAttribute("Nutrition", 20); food.Parent = workspace; CollectionService:AddTag(food, "FoodSource")
    return p, food, root
end

table.insert(suite.tests, { name = "tagged food detection and distance", run = function()
    local p, food = setup(32001, "Herbivore")
    local ok = FoodWaterService:RequestEat(p, food)
    Assert.truthy(ok, "near tagged matching food succeeds")
    food:Destroy()
end })

table.insert(suite.tests, { name = "correct diet succeeds wrong/depleted fails", run = function()
    local p, food = setup(32002, "Carnivore")
    local ok = FoodWaterService:RequestEat(p, food)
    Assert.truthy(ok, "matching carnivore food succeeds")
    RateLimitService:ClearPlayer(p)
    ok = FoodWaterService:RequestEat(p, food)
    Assert.falsy(ok, "depleted food rejected")
    food:Destroy()
    local p2, plant = setup(32003, "Herbivore")
    SurvivalService:GetState(p2).Diet = "Carnivore"
    ok = FoodWaterService:RequestEat(p2, plant)
    Assert.falsy(ok, "wrong diet rejected")
    plant:Destroy()
end })

table.insert(suite.tests, { name = "food updates stat state", run = function()
    local p, food = setup(32004, "Herbivore")
    local state = SurvivalService:GetState(p); state.Hunger = 50; state.Growth = 0
    local ok = FoodWaterService:RequestEat(p, food)
    Assert.truthy(ok, "eat request succeeds")
    Assert.between(state.Hunger, 69, 100, "hunger restored")
    Assert.equals(food:GetAttribute("Depleted"), true, "food depleted server-side")
    Assert.equals(state.Growth, FoodWaterService.FoodGrowthGrant, "growth grant server-side")
    food:Destroy()
end })

table.insert(suite.tests, { name = "water updates thirst and growth state", run = function()
    local p, food, root = setup(32007, "Herbivore")
    local water = Instance.new("Part")
    water.Name = "TestWater"
    water.Position = Vector3.new(3, 3, 0)
    water.Parent = workspace
    CollectionService:AddTag(water, "WaterSource")
    local state = SurvivalService:GetState(p); state.Thirst = 45; state.Growth = 0
    local ok = FoodWaterService:RequestDrink(p, water)
    Assert.truthy(ok, "drink request succeeds")
    Assert.between(state.Thirst, 79, 100, "thirst restored")
    Assert.equals(state.Growth, FoodWaterService.WaterGrowthGrant, "water grants growth server-side")
    food:Destroy(); water:Destroy()
end })


table.insert(suite.tests, { name = "food depletion cooldown can refresh", run = function()
    local p, food = setup(32005, "Herbivore")
    food:SetAttribute("RespawnCooldownSeconds", 1)
    Assert.truthy(FoodWaterService:RequestEat(p, food), "eat depletes food")
    Assert.equals(food:GetAttribute("Depleted"), true, "food depleted")
    food:SetAttribute("DepletedUntil", os.time() - 1)
    food.Transparency = 0.8
    FoodWaterService:RefreshDepletion(food)
    Assert.equals(food:GetAttribute("Depleted"), false, "food restored after cooldown")
    Assert.equals(food.Transparency, 0, "food visibly restored after cooldown")
    food:Destroy()
end })

table.insert(suite.tests, { name = "egg cannot eat before hatch", run = function()
    local p, food = setup(32006, "Herbivore")
    SurvivalService:GetState(p).Hatched = false
    local ok, reason = FoodWaterService:RequestEat(p, food)
    Assert.falsy(ok, "egg cannot eat")
    Assert.equals(reason, "not_alive_hatched", "egg eat reason")
    food:Destroy()
end })

table.insert(suite.tests, { name = "dead prey creates carnivore carcass food", run = function()
    local prey = Instance.new("Model")
    prey.Name = "TestPrey"
    prey.Parent = workspace
    local ok, record = NPCService:Register(prey, "Prey")
    Assert.truthy(ok, "prey registered")
    local deadOk, carcass = NPCService:MarkPreyDead(record)
    Assert.truthy(deadOk, "prey death creates carcass")
    Assert.truthy(CollectionService:HasTag(carcass, "FoodSource"), "carcass tagged FoodSource")
    Assert.equals(carcass:GetAttribute("Diet"), "Carnivore", "carcass carnivore diet")
    Assert.truthy(carcass:GetAttribute("Nutrition") > 0, "carcass nutrition")
    prey:Destroy(); carcass:Destroy()
end })

return suite
