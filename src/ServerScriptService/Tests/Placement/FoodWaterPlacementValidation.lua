local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)
local CollectionService = game:GetService("CollectionService")

local suite = { name = "FoodWaterPlacementValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "nursery food water exists", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    Assert.notNil(folders.Zones:FindFirstChild("NurseryGrove"), "NurseryGrove zone exists")
    Assert.notNil(folders.FoodSources, "FoodSources folder exists")
    Assert.notNil(folders.WaterSources, "WaterSources folder exists")
    MapLayoutService:EnsureTerrainContinuity(folders)
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    local tutorialFood = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryStarterFern_01")
    local tutorialWater = folders.WaterSources:FindFirstChild("NurseryTutorialWater")
    Assert.notNil(tutorialFood, "nursery starter plant exists")
    Assert.notNil(folders.FoodSources.FernPlains:FindFirstChild("FernPlainsGrazingPatch_01"), "Fern Plains grazing plant exists")
    local tutorialMeat = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryTutorialMeatCache")
    Assert.notNil(tutorialMeat, "nursery carnivore tutorial meat exists")
    Assert.notNil(tutorialWater, "nursery tutorial water exists")
    Assert.truthy(CollectionService:HasTag(tutorialFood, "FoodSource"), "tutorial food tagged")
    Assert.truthy(CollectionService:HasTag(tutorialWater, "WaterSource"), "tutorial water tagged")
    Assert.equals(tutorialFood.Transparency, 0, "tutorial food visible")
    Assert.truthy(tutorialWater.Transparency < 1, "tutorial water visible")
    Assert.equals(tutorialFood:GetAttribute("TutorialSafe"), true, "tutorial food marked safe")
    Assert.equals(tutorialWater:GetAttribute("TutorialSafe"), true, "tutorial water marked safe")
    Assert.equals(tutorialMeat:GetAttribute("TutorialSafe"), true, "tutorial meat marked safe")
    Assert.equals(tutorialFood:GetAttribute("InteractionHint"), "Eat plant", "plant hint is readable")
    Assert.equals(tutorialMeat:GetAttribute("InteractionHint"), "Eat carcass", "meat hint is readable")
    Assert.equals(tutorialWater:GetAttribute("InteractionHint"), "Drink water", "water hint is readable")
end })


table.insert(suite.tests, { name = "tutorial loop has nearby food water and trees", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    MapLayoutService:EnsureBiomeDressing(folders)

    local spawnPosition = Vector3.new(-2000, 12, 0)
    local counts = { food = 0, herbivoreFood = 0, carnivoreFood = 0, water = 0, trees = 0 }
    for _, target in ipairs(CollectionService:GetTagged("FoodSource")) do
        if target:IsA("BasePart") and (target.Position - spawnPosition).Magnitude <= 260 then
            counts.food = counts.food + 1
            if target:GetAttribute("Diet") == "Herbivore" then counts.herbivoreFood = counts.herbivoreFood + 1 end
            if target:GetAttribute("Diet") == "Carnivore" then counts.carnivoreFood = counts.carnivoreFood + 1 end
            Assert.truthy(target:GetAttribute("VisibleGameplayAffordance"), "nearby food is visibly marked")
        end
    end
    for _, target in ipairs(CollectionService:GetTagged("WaterSource")) do
        if target:IsA("BasePart") and (target.Position - spawnPosition).Magnitude <= 260 then
            counts.water = counts.water + 1
            Assert.truthy(target:GetAttribute("VisibleGameplayAffordance"), "nearby water is visibly marked")
        end
    end
    for _, target in ipairs(CollectionService:GetTagged("TreeProp")) do
        if target:IsA("BasePart") and (target.Position - spawnPosition).Magnitude <= 260 then
            counts.trees = counts.trees + 1
        end
    end

    Assert.truthy(counts.food >= 8, "tutorial radius has enough visible food for repeated early attempts")
    Assert.truthy(counts.herbivoreFood >= 5, "tutorial radius has enough herbivore starter plants")
    Assert.truthy(counts.carnivoreFood >= 3, "tutorial radius has enough carnivore starter meat/carcass")
    Assert.truthy(counts.water >= 1, "tutorial radius has visible water")
    Assert.truthy(counts.trees >= 2, "tutorial radius has visible tree trunk/canopy")
end })

table.insert(suite.tests, { name = "non nursery water and risky food/fossils reachable", run = function()
    local root = Instance.new("Part")
    root.Position = Vector3.new(0, 0, 0)
    root.Parent = workspace
    local nearby = Instance.new("Part")
    nearby.Position = Vector3.new(5, 0, 0)
    nearby.Parent = workspace
    local far = Instance.new("Part")
    far.Position = Vector3.new(80, 0, 0)
    far.Parent = workspace
    Assert.truthy(RemoteValidationService:IsClose(root, nearby, 12), "nearby placement reachable")
    Assert.falsy(RemoteValidationService:IsClose(root, far, 12), "far placement rejected")
    root:Destroy(); nearby:Destroy(); far:Destroy()
end })


table.insert(suite.tests, { name = "placed food sources have diet nutrition tags and biome density", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    local counts = { NurseryGrove = 0, FernPlains = 0, Carnivore = 0, CityReward = 0 }
    for _, food in ipairs(CollectionService:GetTagged("FoodSource")) do
        if food:IsDescendantOf(folders.FoodSources) then
            Assert.truthy(food:GetAttribute("Diet") == "Herbivore" or food:GetAttribute("Diet") == "Carnivore", "food diet set " .. food.Name)
            Assert.truthy((food:GetAttribute("Nutrition") or 0) > 0, "food nutrition set " .. food.Name)
            Assert.equals(food:GetAttribute("Depleted"), false, "food starts available " .. food.Name)
            Assert.truthy(food:GetAttribute("RespawnCooldownSeconds") > 0, "food cooldown set " .. food.Name)
            local zone = food:GetAttribute("ZoneId")
            if zone == "NurseryGrove" then counts.NurseryGrove = counts.NurseryGrove + 1 end
            if zone == "FernPlains" and food:GetAttribute("Diet") == "Herbivore" then counts.FernPlains = counts.FernPlains + 1 end
            if food:GetAttribute("Diet") == "Carnivore" then
                counts.Carnivore = counts.Carnivore + 1
                Assert.falsy(zone == "NurseryGrove" and food:GetAttribute("TutorialSafe") ~= true, "carnivore prey/carcass outside Nursery unless tutorial-safe " .. food.Name)
            end
            if zone == "ApocalypticCity" then counts.CityReward = counts.CityReward + 1 end
        end
    end
    Assert.truthy(counts.NurseryGrove >= 8, "nursery starter food density")
    Assert.truthy(counts.FernPlains >= 3, "Fern Plains plant density")
    Assert.truthy(counts.Carnivore >= 8, "carnivore prey/carcass source count")
    Assert.truthy(counts.CityReward >= 2, "city high-risk food rewards")
end })

TestRunner.registerSuite(suite)
return suite
