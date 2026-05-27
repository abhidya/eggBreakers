local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local SmallPreyService = require(game:GetService("ServerScriptService").Services.SmallPreyService)
local FishService = require(game:GetService("ServerScriptService").Services.FishService)
local WaterService = require(game:GetService("ServerScriptService").Services.WaterService)

local suite = { name = "SmallPreyFishWaterServiceTests.server", category = "Integration", tests = {} }

local function makeWater(name, size)
    local water = Instance.new("Part")
    water.Name = name or "ServiceTestWater"
    water.Size = size or Vector3.new(24, 4, 18)
    water.Position = Vector3.new(0, 3, 0)
    water.Anchored = true
    water.Parent = workspace
    CollectionService:AddTag(water, "WaterSource")
    return water
end

local function carnivorePlayer(id, position)
    local player = MockPlayer.new(id, "CarnivoreTester")
    RateLimitService:ClearPlayer(player)
    local state = SurvivalService:CreateState(player, "velociraptor")
    state.Hatched = true
    state.Hunger = 20
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = position or Vector3.new(0, 3, 0)
    local character = Instance.new("Model")
    root.Parent = character
    player.Character = character
    return player, state, character
end

table.insert(suite.tests, { name = "US27 small prey flees, dies, and becomes carnivore food", run = function()
    local prey = Instance.new("Part")
    prey.Name = "US27SmallPrey"
    prey.Position = Vector3.new(4, 3, 0)
    prey.Parent = workspace
    Assert.truthy(SmallPreyService:Register(prey), "small prey registers")
    Assert.truthy(CollectionService:HasTag(prey, "SmallPrey"), "small prey tag set")
    Assert.truthy(SmallPreyService:FleeFrom(prey, Vector3.new(0, 3, 0), 10), "small prey flees threat")
    local ok, carcass = SmallPreyService:ApplyDamage(prey, 999)
    Assert.truthy(ok, "small prey damage accepted")
    Assert.notNil(carcass, "dead small prey creates carcass")
    Assert.truthy(CollectionService:HasTag(carcass, "FoodSource"), "carcass is food source")
    Assert.equals(carcass:GetAttribute("Diet"), "Carnivore", "carcass feeds carnivores")
    prey:Destroy(); carcass:Destroy()
end })

table.insert(suite.tests, { name = "US28 fish source stays inside water and feeds carnivores", run = function()
    local water = makeWater("US28FishWater", Vector3.new(20, 4, 20))
    local fish = FishService:CreateFishSource(water, "US28Fish", Vector3.new(100, 0, 100))
    Assert.notNil(fish, "fish source created")
    Assert.truthy(CollectionService:HasTag(fish, "FishSource"), "fish tag set")
    Assert.equals(fish:GetAttribute("Diet"), "Carnivore", "fish feeds carnivores")
    Assert.truthy(WaterService:ContainsPoint(water, fish.Position, 0.01), "fish clamped inside water")
    local player, state, character = carnivorePlayer(92801, fish.Position)
    Assert.truthy(FoodWaterService:RequestEat(player, fish), "carnivore eats fish source")
    Assert.truthy(state.Hunger > 20, "fish restores hunger")
    fish:Destroy(); water:Destroy(); character:Destroy()
end })

table.insert(suite.tests, { name = "US29 water service classifies depth and marks fish habitat", run = function()
    local shallow = makeWater("US29ShallowWater", Vector3.new(18, 4, 18))
    local deep = makeWater("US29DeepWater", Vector3.new(18, 10, 18))
    local shallowKind, shallowDepth = WaterService:ClassifyDepth(shallow)
    local deepKind, deepDepth = WaterService:ClassifyDepth(deep)
    Assert.equals(shallowKind, "Shallow", "shallow water classified")
    Assert.equals(shallowDepth, 4, "shallow depth recorded")
    Assert.equals(deepKind, "Deep", "deep water classified")
    Assert.equals(deepDepth, 10, "deep depth recorded")
    Assert.truthy(WaterService:MarkFishHabitat(deep), "fish habitat marked")
    Assert.truthy(CollectionService:HasTag(deep, "FishHabitat"), "fish habitat tag set")
    shallow:Destroy(); deep:Destroy()
end })

return suite
