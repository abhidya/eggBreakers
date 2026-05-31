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

local function markFishWater(water, zoneId)
    water:SetAttribute("SwimZone", true)
    water:SetAttribute("FishSpawnAllowed", true)
    water:SetAttribute("ZoneId", zoneId or "SwampDelta")
    water:SetAttribute("BiomeId", zoneId or "SwampDelta")
    return water
end

local function fixedRng(values)
    return {
        Index = 0,
        Values = values,
        NextNumber = function(self, minValue, maxValue)
            self.Index = self.Index + 1
            local value = self.Values[self.Index] or 0
            return math.clamp(value, minValue, maxValue)
        end,
    }
end

local function carnivorePlayer(id, position)
    local player = MockPlayer.new(id, "CarnivoreTester")
    RateLimitService:ClearPlayer(player)
    local state = SurvivalService:CreateState(player, "utahraptor")
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
    local water = markFishWater(makeWater("US28FishWater", Vector3.new(20, 4, 20)), "SwampDelta")
    local fish = FishService:CreateFishSource(water, "US28Fish", Vector3.new(100, 0, 100))
    Assert.notNil(fish, "fish source created")
    Assert.truthy(CollectionService:HasTag(fish, "FishSource"), "fish tag set")
    Assert.truthy(CollectionService:HasTag(fish, "FishSchool"), "fish school tag set")
    Assert.equals(fish:GetAttribute("FishSchool"), true, "fish school attribute set")
    Assert.equals(fish:GetAttribute("ZoneId"), "SwampDelta", "fish school carries zone")
    Assert.equals(fish:GetAttribute("BiomeId"), "SwampDelta", "fish school carries biome")
    Assert.equals(fish:GetAttribute("WaterSourceName"), water.Name, "fish school carries water source")
    Assert.equals(fish:GetAttribute("Diet"), "Carnivore", "fish feeds carnivores")
    Assert.truthy(WaterService:ContainsPoint(water, fish.Position, 0.01), "fish clamped inside water")
    local player, state, character = carnivorePlayer(92801, fish.Position)
    Assert.truthy(FoodWaterService:RequestEat(player, fish), "carnivore eats fish source")
    Assert.truthy(state.Hunger > 20, "fish restores hunger")
    fish:Destroy(); water:Destroy(); character:Destroy()
end })

table.insert(suite.tests, { name = "US29 water service classifies depth and marks fish habitat", run = function()
    local shallow = makeWater("US29ShallowWater", Vector3.new(18, 4, 18))
    local deep = markFishWater(makeWater("US29DeepWater", Vector3.new(18, 10, 18)), "SwampDelta")
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

table.insert(suite.tests, { name = "Beat 5 adapted imported fish random walk stays inside water", run = function()
    local water = markFishWater(makeWater("Beat5AdaptedFishWater", Vector3.new(20, 4, 20)), "SwampDelta")
    local fish = FishService:CreateFishSource(water, "Beat5AdaptedFish", Vector3.new(9, 0, 9))
    Assert.notNil(fish, "fish source created")

    local ok, reason = FishService:ApplyBeat5ImportedRandomWalk(fish, water, {
        stepStuds = 12,
        rng = fixedRng({ 12, 6, 12 }),
    })

    Assert.truthy(ok, reason or "adapted random walk succeeds")
    Assert.truthy(WaterService:ContainsPoint(water, fish.Position, 0.01), "adapted random walk remains inside water")
    Assert.equals(fish:GetAttribute("ImportedScriptAdapted"), true, "fish movement is stamped adapted")
    Assert.equals(fish:GetAttribute("AdaptedIntoEggBreakers"), true, "fish movement records Egg Breakers adaptation")
    Assert.equals(fish:GetAttribute("ScriptAdaptedTo"), "FishService.ApplyBeat5ImportedRandomWalk", "adapted target recorded")
    Assert.equals(fish:GetAttribute("ImportedBehaviorOwner"), FishService.ImportedBehaviorName, "adapted behavior owner recorded")
    Assert.equals(fish:GetAttribute("ImportedSourceBeat"), "Beat5", "source beat recorded")
    Assert.truthy(CollectionService:HasTag(fish, FishService.ImportedScriptAdaptedTag), "adapted fish tag set")
    fish:Destroy(); water:Destroy()
end })

table.insert(suite.tests, { name = "G018-US02 fish schools reject dry or drink-only water", run = function()
    local drinkOnly = makeWater("G018DrinkOnlyWater", Vector3.new(18, 4, 18))
    local fish, reason = FishService:CreateFishSource(drinkOnly, "InvalidDrinkOnlyFish")
    Assert.equals(fish, nil, "drink-only water does not spawn fish schools")
    Assert.equals(reason, "fish_not_allowed", "drink-only fish rejection reason")

    local dryFish = Instance.new("Part")
    dryFish.Name = "G018DryFishCandidate"
    dryFish.Parent = workspace
    fish, reason = FishService:CreateFishSource(dryFish, "InvalidDryFish")
    Assert.equals(fish, nil, "dry part does not spawn fish schools")
    Assert.equals(reason, "not_water", "dry fish rejection reason")
    drinkOnly:Destroy(); dryFish:Destroy()
end })

table.insert(suite.tests, { name = "G018-US03 water integrity separates drinkable shallow from swim water", run = function()
    local drinkable = makeWater("G018DrinkableShallow", Vector3.new(18, 4, 18))
    local swim = markFishWater(makeWater("G018SwimFishWater", Vector3.new(28, 5, 28)), "SwampDelta")
    WaterService:ValidateAllWaterSources()

    local drinkIntegrity = WaterService:GetWaterIntegrity(drinkable)
    local swimIntegrity = WaterService:GetWaterIntegrity(swim)
    Assert.equals(drinkIntegrity, "DrinkableShallow", "drinkable water integrity")
    Assert.equals(swimIntegrity, "SwimShallow", "swim water integrity")
    Assert.truthy(CollectionService:HasTag(drinkable, "DrinkableWater"), "drinkable water tag set")
    Assert.falsy(CollectionService:HasTag(swim, "DrinkableWater"), "swim water not tagged drinkable")
    Assert.truthy(CollectionService:HasTag(swim, "SwimWater"), "swim water tag set")
    Assert.truthy(CollectionService:HasTag(swim, "FishHabitat"), "fish habitat tag set")
    drinkable:Destroy(); swim:Destroy()
end })

return suite
