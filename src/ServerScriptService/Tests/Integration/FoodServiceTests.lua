local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local MapLayoutService = require(game:GetService("ServerScriptService").Services.MapLayoutService)
local suite = { name = "FoodServiceTests.server", category = "Integration", tests = {} }

local function assertNear(actual, expected, epsilon, message)
    Assert.truthy(math.abs(actual - expected) <= (epsilon or 0.001), (message or "values near") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function setup(id, diet)
    local p = MockPlayer.new(id, "FoodTester")
    RateLimitService:ClearPlayer(p)
    SurvivalService:CreateState(p, diet == "Carnivore" and "utahraptor" or "parasaurolophus").Hatched = true
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
    Assert.equals(food:GetAttribute("LastEatAction"), "Graze", "plant bite verb is readable")
    Assert.equals(food:GetAttribute("LastEatenBy"), "FoodTester", "food records eater")
    Assert.equals(state.LastEatTarget, "TestFood", "player state records food target")
    Assert.equals(state.LastEatNutrition, 20, "player state records nutrition")
    Assert.equals(state.Growth, FoodWaterService.FoodGrowthGrant, "growth grant server-side")
    food:Destroy()
end })

table.insert(suite.tests, { name = "unlabelled foliage normalizes before eating", run = function()
    local p, food = setup(32010, "Herbivore")
    food:SetAttribute("Diet", nil)
    food:SetAttribute("FoodKind", nil)
    food:SetAttribute("Nutrition", nil)
    local ok = FoodWaterService:RequestEat(p, food)
    Assert.truthy(ok, "unlabelled tagged foliage is edible")
    Assert.equals(food:GetAttribute("Diet"), "Herbivore", "foliage diet normalized")
    Assert.equals(food:GetAttribute("FoodKind"), "Foliage", "foliage kind normalized")
    Assert.equals(food:GetAttribute("LastEatAction"), "Graze", "normalized foliage gets graze verb")
    food:Destroy()
end })

table.insert(suite.tests, { name = "omnivore and fish food metadata keep their diet variety", run = function()
    local omnivoreFood = Instance.new("Part")
    omnivoreFood.Name = "OmnivoreSeedPod"
    omnivoreFood.Position = Vector3.new(3, 3, 0)
    omnivoreFood:SetAttribute("FoodKind", "SeedPod")
    omnivoreFood:SetAttribute("Nutrition", 18)
    omnivoreFood.Parent = workspace
    CollectionService:AddTag(omnivoreFood, "FoodSource")
    Assert.truthy(FoodWaterService:NormaliseFoodMetadata(omnivoreFood), "omnivore food normalizes")
    Assert.equals(omnivoreFood:GetAttribute("Diet"), "Omnivore", "omnivore food kind infers omnivore diet")
    Assert.falsy(omnivoreFood:GetAttribute("EdibleVegetation"), "omnivore forage is not flattened into foliage")

    local fish = Instance.new("Part")
    fish.Name = "UnlabelledFishFood"
    fish.Position = Vector3.new(3, 3, 0)
    fish:SetAttribute("FoodKind", "Fish")
    fish:SetAttribute("Nutrition", 18)
    fish.Parent = workspace
    CollectionService:AddTag(fish, "FoodSource")
    CollectionService:AddTag(fish, "FishSource")
    Assert.truthy(FoodWaterService:NormaliseFoodMetadata(fish), "fish food normalizes")
    Assert.equals(fish:GetAttribute("Diet"), "Carnivore", "fish food kind infers carnivore diet")

    local p = MockPlayer.new(32011, "OmnivoreFoodTester")
    RateLimitService:ClearPlayer(p)
    SurvivalService:CreateState(p, "citipati").Hatched = true
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local state = SurvivalService:GetState(p); state.Hunger = 40
    Assert.truthy(FoodWaterService:RequestEat(p, omnivoreFood), "player eats omnivore forage")
    Assert.equals(omnivoreFood:GetAttribute("Diet"), "Omnivore", "eat path preserves omnivore diet")
    Assert.equals(omnivoreFood:GetAttribute("LastEatAction"), "Forage", "omnivore food uses readable forage verb")
    Assert.equals(state.LastEatFoodDiet, "Omnivore", "player state records omnivore food diet")

    omnivoreFood:Destroy(); fish:Destroy(); char:Destroy()
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

table.insert(suite.tests, { name = "sprint toggles and drains stamina progression", run = function()
    local p, food = setup(32008, "Herbivore")
    local state = SurvivalService:GetState(p)
    state.Stamina = math.min(50, math.max(10, state.Stamina - 4))
    local sprintStartStamina = state.Stamina
    local ok = SurvivalService:SetSprinting(p, true)
    Assert.truthy(ok, "sprint enables for hatched player")
    Assert.equals(state.Sprinting, true, "sprinting state replicated")
    SurvivalService:ApplyNeedsTick(p, 2)
    Assert.truthy(state.Stamina < sprintStartStamina, "sprinting drains stamina over time")
    ok = SurvivalService:SetSprinting(p, false)
    Assert.truthy(ok, "sprint disables")
    local afterDrain = state.Stamina
    SurvivalService:ApplyNeedsTick(p, 1)
    Assert.truthy(state.Stamina > afterDrain, "stamina regenerates after sprint off")
    food:Destroy()
end })


table.insert(suite.tests, { name = "food depletion cooldown can refresh", run = function()
    local p, food = setup(32005, "Herbivore")
    local leaf = Instance.new("Part")
    leaf.Name = "LeafAffordance"
    leaf.Transparency = 0.1
    leaf:SetAttribute("VisibleGameplayAffordance", true)
    leaf:SetAttribute("EdibleFoliageVisual", true)
    leaf.Parent = food
    local frond = Instance.new("Part")
    frond.Name = "FrondAffordance"
    frond.Transparency = 0.25
    frond:SetAttribute("VisibleGameplayAffordance", true)
    frond:SetAttribute("EdibleFoliageVisual", true)
    frond.Parent = food
    food:SetAttribute("RespawnCooldownSeconds", 1)
    Assert.truthy(FoodWaterService:RequestEat(p, food), "eat depletes food")
    Assert.equals(food:GetAttribute("Depleted"), true, "food depleted")
    Assert.equals(leaf.Transparency, FoodWaterService.DepletedFoliageTransparency, "first visible affordance dims")
    Assert.equals(frond.Transparency, FoodWaterService.DepletedFoliageTransparency, "second visible affordance dims")
    food:SetAttribute("DepletedUntil", os.time() - 1)
    food.Transparency = 0.8
    FoodWaterService:RefreshDepletion(food)
    Assert.equals(food:GetAttribute("Depleted"), false, "food restored after cooldown")
    Assert.equals(food.Transparency, 0, "food visibly restored after cooldown")
    assertNear(leaf.Transparency, 0.1, 0.001, "first affordance restores original transparency")
    assertNear(frond.Transparency, 0.25, 0.001, "second affordance restores original transparency")
    food:Destroy()
end })

table.insert(suite.tests, { name = "food service depletes imported food visual affordance", run = function()
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = game:GetService("ReplicatedStorage")
    end
    local template = Instance.new("Model")
    template.Name = "TestImportedFoodServiceFern"
    template:SetAttribute("ImportedFoodVisualTemplate", true)
    template:SetAttribute("FoodKind", "StarterPlant")
    template:SetAttribute("Diet", "Herbivore")
    template:SetAttribute("ImportedVisibleAsset", true)
    local readablePart = Instance.new("Part")
    readablePart.Name = "ReadableImportedFern"
    readablePart.Transparency = 0.15
    readablePart.Parent = template
    template.PrimaryPart = readablePart
    template.Parent = library

    local p, food = setup(32009, "Herbivore")
    food:SetAttribute("RespawnCooldownSeconds", 1)
    MapLayoutService:ApplyFoodMetadata(food, { diet = "Herbivore", nutrition = 20, kind = "StarterPlant" })
    MapLayoutService:ApplyReleaseHiddenQueryPart(food)
    local visual = MapLayoutService:EnsureVisibleFoliageVisual(food, { diet = "Herbivore", kind = "StarterPlant" })
    Assert.notNil(visual, "imported visual attaches")
    Assert.equals(food:GetAttribute("ImportedFoodVisualAttached"), true, "query helper records imported visual")
    local visualPart = visual:FindFirstChild("ReadableImportedFern", true)
    Assert.notNil(visualPart, "imported visual exposes readable part")

    Assert.truthy(FoodWaterService:RequestEat(p, food), "eat depletes imported visual food")
    Assert.equals(visualPart.Transparency, FoodWaterService.DepletedFoliageTransparency, "imported visible part dims")
    food:SetAttribute("DepletedUntil", os.time() - 1)
    FoodWaterService:RefreshDepletion(food)
    assertNear(visualPart.Transparency, 0.15, 0.001, "imported visible part restores")

    template:Destroy()
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


table.insert(suite.tests, { name = "carnivore player eats NPC-created carcass", run = function()
    local p, _, root = setup(32008, "Carnivore")
    local prey = Instance.new("Model")
    prey.Name = "FoodWaterCarcassPrey"
    prey.Parent = workspace
    local ok, record = NPCService:Register(prey, "Prey")
    Assert.truthy(ok, "prey registered")
    local deadOk, carcass = NPCService:MarkPreyDead(record)
    Assert.truthy(deadOk, "prey death creates carcass")
    Assert.notNil(carcass, "carcass instance exists")
    root.Position = NPCService:GetInstancePosition(carcass) + Vector3.new(0, 0, -3)
    local state = SurvivalService:GetState(p)
    state.Hunger = 30
    RateLimitService:ClearPlayer(p)
    local eatOk = FoodWaterService:RequestEat(p, carcass)
    Assert.truthy(eatOk, "carnivore player can eat NPC-created carcass")
    Assert.truthy(state.Hunger > 30, "carcass restores hunger")
    Assert.equals(carcass:GetAttribute("Depleted"), true, "carcass depletes after player eat")
    Assert.equals(carcass:GetAttribute("LastEatAction"), "BiteCarcass", "carcass bite verb is readable")
    Assert.equals(state.LastEatFoodKind, "PreyCarcass", "state records carcass food kind")
    prey:Destroy(); carcass:Destroy()
end })

table.insert(suite.tests, { name = "player-eaten carcass has procedural bone fallback without callback", run = function()
    local p, setupFood, root = setup(32012, "Carnivore")
    local previousCallbacks = FoodWaterService.CarcassConsumedCallbacks
    FoodWaterService.CarcassConsumedCallbacks = {}

    local carcass = Instance.new("Part")
    carcass.Name = "CallbacklessCarcass"
    carcass.Position = Vector3.new(3, 3, 0)
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("FoodKind", "PreyCarcass")
    carcass:SetAttribute("Nutrition", 30)
    carcass:SetAttribute("CarcassFoodSource", true)
    carcass:SetAttribute("CarcassConsumed", false)
    carcass.Parent = workspace
    CollectionService:AddTag(carcass, "FoodSource")
    CollectionService:AddTag(carcass, "CarnivoreFoodCandidate")

    root.Position = carcass.Position + Vector3.new(0, 0, -3)
    RateLimitService:ClearPlayer(p)
    local callOk, ok, resultOrReason = pcall(function()
        return FoodWaterService:RequestEat(p, carcass)
    end)
    FoodWaterService.CarcassConsumedCallbacks = previousCallbacks

    Assert.truthy(callOk, tostring(ok))
    Assert.truthy(ok, tostring(resultOrReason))
    Assert.equals(carcass:GetAttribute("CarcassConsumed"), true, "carcass enters consumed state")
    Assert.falsy(CollectionService:HasTag(carcass, "FoodSource"), "consumed carcass is no longer edible")
    local bonesName = carcass:GetAttribute("BonesReplacement")
    Assert.truthy((bonesName or "") ~= "", "bones replacement recorded")
    local bones = workspace:FindFirstChild(bonesName, true)
    Assert.notNil(bones, "bones replacement exists")
    Assert.equals(bones:GetAttribute("ProceduralBonesVisual"), true, "fallback is bone-shaped procedural remains")
    Assert.notNil(bones:FindFirstChild("SpineBone", true), "fallback includes named bone geometry")

    setupFood:Destroy()
    carcass:Destroy()
    if bones then bones:Destroy() end
end })

table.insert(suite.tests, { name = "no-op carcass callback still falls back to bones", run = function()
    local p, setupFood, root = setup(32013, "Carnivore")
    local previousCallbacks = FoodWaterService.CarcassConsumedCallbacks
    FoodWaterService.CarcassConsumedCallbacks = {
        function()
            return true
        end,
    }

    local carcass = Instance.new("Part")
    carcass.Name = "NoopCallbackCarcass"
    carcass.Position = Vector3.new(3, 3, 0)
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("FoodKind", "PreyCarcass")
    carcass:SetAttribute("Nutrition", 30)
    carcass:SetAttribute("CarcassFoodSource", true)
    carcass:SetAttribute("CarcassConsumed", false)
    carcass.Parent = workspace
    CollectionService:AddTag(carcass, "FoodSource")
    CollectionService:AddTag(carcass, "CarnivoreFoodCandidate")

    root.Position = carcass.Position + Vector3.new(0, 0, -3)
    RateLimitService:ClearPlayer(p)
    local callOk, ok, resultOrReason = pcall(function()
        return FoodWaterService:RequestEat(p, carcass)
    end)
    FoodWaterService.CarcassConsumedCallbacks = previousCallbacks

    Assert.truthy(callOk, tostring(ok))
    Assert.truthy(ok, tostring(resultOrReason))
    Assert.equals(carcass:GetAttribute("CarcassConsumeCallbacks"), 1, "callback was attempted")
    Assert.equals(carcass:GetAttribute("CarcassConsumed"), true, "fallback consumes carcass when callback leaves it active")
    local bonesName = carcass:GetAttribute("BonesReplacement")
    local bones = workspace:FindFirstChild(bonesName or "", true)
    Assert.notNil(bones, "fallback bones exist after no-op callback")

    setupFood:Destroy()
    carcass:Destroy()
    if bones then bones:Destroy() end
end })

table.insert(suite.tests, { name = "NPC eating uses readable shared food depletion", run = function()
    local npc = Instance.new("Model")
    npc.Name = "ReadableEatingNPC"
    npc.Parent = workspace
    local ok, record = NPCService:Register(npc, "Prey")
    Assert.truthy(ok, "NPC registered")
    record.Hatched = true
    record.Hunger = 20

    local food = Instance.new("Part")
    food.Name = "ReadableNPCFern"
    food.Position = Vector3.new(2, 3, 0)
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("FoodKind", "TreeBrowse")
    food:SetAttribute("Nutrition", 22)
    food:SetAttribute("RespawnCooldownSeconds", 30)
    food.Parent = workspace
    CollectionService:AddTag(food, "FoodSource")

    Assert.truthy(NPCService:Eat(record, food), "NPC eats food")
    Assert.equals(record.State, "Eat", "NPC enters eat state")
    Assert.equals(npc:GetAttribute("EatingState"), "Browse", "NPC exposes readable eating verb")
    Assert.equals(npc:GetAttribute("EatTarget"), "ReadableNPCFern", "NPC exposes eat target")
    Assert.equals(food:GetAttribute("LastEatAction"), "Browse", "food records browse verb")
    Assert.equals(food:GetAttribute("LastEatenByNPC"), "ReadableEatingNPC", "food records NPC eater")
    Assert.equals(food:GetAttribute("BiteCount"), 1, "food records bite count")
    Assert.notNil(food:GetAttribute("DepletedUntil"), "NPC depletion uses respawn cooldown")

    npc:Destroy(); food:Destroy()
end })

return suite
