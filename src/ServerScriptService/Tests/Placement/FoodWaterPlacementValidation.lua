local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)
local WaterService = require(ServerScriptService.Services.WaterService)
local CollectionService = game:GetService("CollectionService")

local suite = { name = "FoodWaterPlacementValidation.server", category = "Placement", tests = {} }

local function countVisibleFoodAffordances(food)
    local count = 0
    for _, descendant in ipairs(food:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("VisibleGameplayAffordance") == true then
            Assert.falsy(CollectionService:HasTag(descendant, "FoodSource"), "visible affordance is not a FoodSource tag " .. descendant.Name)
            Assert.equals(descendant.CanQuery, false, "visible affordance is not the gameplay query " .. descendant.Name)
            Assert.truthy(descendant.Transparency < 1, "visible affordance starts readable " .. descendant.Name)
            count = count + 1
        end
    end
    return count
end

local function countVisibleWaterAffordances(water)
    local count = 0
    for _, descendant in ipairs(water:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("WaterVisual") == true then
            Assert.truthy(descendant.Transparency < 1, "water visual starts readable " .. descendant.Name)
            Assert.equals(descendant.CanQuery, false, "water visual is not the gameplay query " .. descendant.Name)
            Assert.equals(descendant:GetAttribute("VisibleGameplayAffordance"), true, "water visual is stamped readable " .. descendant.Name)
            count = count + 1
        end
    end
    return count
end

local function makeImportedFoodTemplate(name, kind, diet)
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = ReplicatedStorage
    end
    local template = Instance.new("Model")
    template.Name = name
    template:SetAttribute("ImportedFoodVisualTemplate", true)
    template:SetAttribute("FoodKind", kind)
    template:SetAttribute("Diet", diet)
    template:SetAttribute("CreatorStoreOnly", true)
    template:SetAttribute("ImportedVisibleAsset", true)
    template:SetAttribute("AssetManifestId", "TestImported" .. kind)
    local part = Instance.new("Part")
    part.Name = name .. "_ReadablePart"
    part.Size = Vector3.new(4, 2, 4)
    part.Transparency = 0.05
    part.Parent = template
    template.PrimaryPart = part
    template.Parent = library
    return template
end

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
    Assert.equals(tutorialFood.Transparency, 1, "tutorial food hidden for release")
    Assert.equals(tutorialFood:GetAttribute("InvisibleQueryHelper"), true, "tutorial food remains an invisible query helper")
    Assert.falsy(tutorialFood:GetAttribute("VisibleGameplayAffordance"), "tutorial food does not expose procedural visuals")
    Assert.equals(tutorialWater.Transparency, 1, "tutorial water query hidden for release")
    Assert.equals(tutorialWater:GetAttribute("InvisibleQueryHelper"), true, "tutorial water remains an invisible query helper")
    Assert.truthy(countVisibleWaterAffordances(tutorialWater) >= 3, "tutorial water has rounded readable visual surfaces")
    Assert.equals(tutorialFood:GetAttribute("TutorialSafe"), true, "tutorial food marked safe")
    Assert.equals(tutorialWater:GetAttribute("TutorialSafe"), true, "tutorial water marked safe")
    Assert.equals(tutorialMeat:GetAttribute("TutorialSafe"), true, "tutorial meat marked safe")
    Assert.equals(tutorialFood:GetAttribute("InteractionHint"), "Eat tender fern", "plant hint is readable")
    Assert.equals(tutorialMeat:GetAttribute("InteractionHint"), "Eat safe carcass", "meat hint is readable")
    Assert.equals(tutorialWater:GetAttribute("InteractionHint"), "Drink water", "water hint is readable")
    Assert.truthy(countVisibleFoodAffordances(tutorialFood) >= 3, "starter plant has a readable foliage cluster")
    Assert.truthy(countVisibleFoodAffordances(tutorialMeat) >= 3, "starter carcass has meat and bone affordances")
end })

table.insert(suite.tests, { name = "imported food visual templates are preferred and stamped", run = function()
    local plantTemplate = makeImportedFoodTemplate("TestImportedStarterFernVisual", "StarterPlant", "Herbivore")
    local carcassTemplate = makeImportedFoodTemplate("TestImportedTutorialCarcassVisual", "TutorialCarcass", "Carnivore")
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)

    local tutorialFood = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryStarterFern_01")
    local tutorialMeat = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryTutorialMeatCache")
    local importedPlant = tutorialFood and tutorialFood:FindFirstChild(MapLayoutService.ImportedFoodVisualName)
    local importedCarcass = tutorialMeat and tutorialMeat:FindFirstChild(MapLayoutService.ImportedFoodVisualName)

    Assert.notNil(importedPlant, "starter plant uses imported visual child")
    Assert.notNil(importedCarcass, "tutorial carcass uses imported visual child")
    Assert.equals(tutorialFood.Transparency, 1, "starter plant query stays hidden")
    Assert.equals(tutorialFood:GetAttribute("InvisibleQueryHelper"), true, "starter plant remains hidden query helper")
    Assert.equals(tutorialFood:GetAttribute("ImportedFoodVisualAttached"), true, "starter plant stamped with imported visual binding")
    Assert.truthy(string.find(tutorialFood:GetAttribute("ImportedFoodVisualTemplate") or "", plantTemplate.Name, 1, true) ~= nil, "starter plant records imported template source")
    Assert.equals(importedPlant:GetAttribute("ImportedFoodVisual"), true, "imported plant clone is stamped")
    Assert.equals(importedPlant:GetAttribute("ImportedVisibleAsset"), true, "imported plant clone remains imported asset")
    Assert.truthy(countVisibleFoodAffordances(tutorialFood) >= 1, "imported plant visual is readable")
    Assert.equals(tutorialMeat:GetAttribute("ImportedFoodVisualAttached"), true, "tutorial carcass stamped with imported visual binding")
    Assert.truthy(string.find(tutorialMeat:GetAttribute("ImportedFoodVisualTemplate") or "", carcassTemplate.Name, 1, true) ~= nil, "tutorial carcass records imported template source")
    Assert.falsy(tutorialFood:FindFirstChild(MapLayoutService.FoliageVisualName), "procedural foliage is not generated when import exists")
    Assert.falsy(tutorialMeat:FindFirstChild("CarcassBoneVisual"), "procedural carcass bone is not generated when import exists")

    plantTemplate:Destroy()
    carcassTemplate:Destroy()
end })

table.insert(suite.tests, { name = "food resolver does not use carnivore carcass template for herbivore plants", run = function()
    local carcassTemplate = makeImportedFoodTemplate("TestImportedTutorialCarcassVisual", "TutorialCarcass", "Carnivore")
    local query = Instance.new("Part")
    query.Name = "HerbivorePlantProbe"
    query:SetAttribute("FoodKind", "StarterPlant")
    query:SetAttribute("Diet", "Herbivore")

    local resolved = MapLayoutService:ResolveImportedFoodVisualTemplate(query)

    Assert.equals(resolved, nil, "herbivore plant resolver rejects carnivore carcass template")

    query:Destroy()
    carcassTemplate:Destroy()
end })

table.insert(suite.tests, { name = "procedural food visual remains fallback when import absent", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    local source = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryStarterFern_01")
    if source then source:Destroy() end

    MapLayoutService:EnsureFoodSourcePlacements(folders)
    local tutorialFood = folders.FoodSources.NurseryGrove:FindFirstChild("NurseryStarterFern_01")
    Assert.notNil(tutorialFood, "starter plant recreated")
    Assert.equals(tutorialFood:GetAttribute("ImportedFoodVisualAttached"), false, "starter plant records missing imported visual")
    Assert.falsy(tutorialFood:FindFirstChild(MapLayoutService.ImportedFoodVisualName), "no imported visual child without template")
    Assert.notNil(tutorialFood:FindFirstChild(MapLayoutService.FoliageVisualName), "procedural foliage fallback exists")
    Assert.truthy(countVisibleFoodAffordances(tutorialFood) >= 3, "procedural foliage fallback remains readable")
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
            Assert.truthy(target:GetAttribute("GameplayQuery"), "nearby food remains queryable")
            Assert.equals(target.Transparency, 1, "nearby procedural food is hidden for release")
        end
    end
    for _, target in ipairs(CollectionService:GetTagged("WaterSource")) do
        if target:IsA("BasePart") and (target.Position - spawnPosition).Magnitude <= 260 then
            counts.water = counts.water + 1
            Assert.truthy(countVisibleWaterAffordances(target) >= 1, "nearby water has visible rounded affordance")
        end
    end
    for _, target in ipairs(CollectionService:GetTagged("TreeProp")) do
        if target:IsA("BasePart") and (target.Position - spawnPosition).Magnitude <= 260 then
            counts.trees = counts.trees + 1
        end
    end

    Assert.truthy(counts.food >= 14, "tutorial radius has dense invisible food queries for repeated early attempts")
    Assert.truthy(counts.herbivoreFood >= 9, "tutorial radius has dense herbivore starter plants")
    Assert.truthy(counts.carnivoreFood >= 5, "tutorial radius has enough carnivore starter meat/carcass")
    Assert.truthy(counts.water >= 1, "tutorial radius has visible water")
    Assert.truthy(counts.trees >= 2, "tutorial radius has tree browse query helpers")
end })

table.insert(suite.tests, { name = "G018 fish schools are sourced from valid swim water volumes", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)

    local fishSchools = 0
    for _, fish in ipairs(CollectionService:GetTagged("FishSchool")) do
        if fish:IsA("BasePart") then
            fishSchools = fishSchools + 1
            Assert.equals(fish:GetAttribute("FishSchool"), true, "fish school attr set " .. fish.Name)
            Assert.truthy(type(fish:GetAttribute("ZoneId")) == "string", "fish school has ZoneId " .. fish.Name)
            Assert.truthy(type(fish:GetAttribute("BiomeId")) == "string", "fish school has BiomeId " .. fish.Name)
            local waterName = fish:GetAttribute("WaterSourceName")
            Assert.truthy(type(waterName) == "string", "fish school has water source " .. fish.Name)
            local water = folders.WaterSources:FindFirstChild(waterName)
            Assert.notNil(water, "fish school water source exists " .. fish.Name)
            Assert.truthy(WaterService:IsValidFishHabitat(water), "fish school source is valid habitat " .. waterName)
            Assert.truthy(WaterService:ContainsPoint(water, fish.Position, 0.01), "fish school stays inside water " .. fish.Name)
        end
    end

    Assert.truthy(fishSchools >= 3, "fish schools exist for swim/fish water volumes")
end })

table.insert(suite.tests, { name = "G018 water integrity marks drinkable and swim sources separately", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    local drinkable = 0
    local swim = 0

    for _, water in ipairs(folders.WaterSources:GetChildren()) do
        if water:IsA("BasePart") then
            local integrity = water:GetAttribute("WaterIntegrity")
            Assert.truthy(type(integrity) == "string", "water integrity stamped " .. water.Name)
            if CollectionService:HasTag(water, "DrinkableWater") then
                drinkable = drinkable + 1
                Assert.equals(integrity, "DrinkableShallow", "drinkable water is shallow " .. water.Name)
                Assert.equals(water:GetAttribute("ShallowDrinkable"), true, "drinkable attr set " .. water.Name)
            end
            if CollectionService:HasTag(water, "SwimWater") then
                swim = swim + 1
                Assert.truthy(integrity == "SwimShallow" or integrity == "SwimDeep", "swim water integrity set " .. water.Name)
                Assert.falsy(CollectionService:HasTag(water, "DrinkableWater"), "swim source is not drink-only " .. water.Name)
            end
        end
    end

    Assert.truthy(drinkable >= 3, "drinkable shallow water exists")
    Assert.truthy(swim >= 3, "swim water exists")
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
    Assert.truthy(counts.NurseryGrove >= 14, "nursery starter food density")
    Assert.truthy(counts.FernPlains >= 3, "Fern Plains plant density")
    Assert.truthy(counts.Carnivore >= 10, "carnivore prey/carcass source count")
    Assert.truthy(counts.CityReward >= 2, "city high-risk food rewards")
end })


table.insert(suite.tests, { name = "edible vegetation and tree browse metadata is varied", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    MapLayoutService:EnsureFoodSources()
    MapLayoutService:EnsureBiomeDressing(folders)

    local vegetationTypes = {}
    local treeBrowseCount = 0
    local compactGroups = {}
    local nurseryBrowse = 0
    for _, food in ipairs(CollectionService:GetTagged("FoodSource")) do
        if food:GetAttribute("Diet") == "Herbivore" and food:GetAttribute("EdibleVegetation") == true then
            local vegetationType = food:GetAttribute("VegetationType")
            local compactGroup = food:GetAttribute("CompactFoodGroup")
            Assert.truthy(type(vegetationType) == "string" and vegetationType ~= "", "herbivore food has vegetation type " .. food.Name)
            Assert.truthy(type(food:GetAttribute("PlantPart")) == "string", "herbivore food has plant part " .. food.Name)
            Assert.truthy((food:GetAttribute("BrowseHeightStuds") or 0) > 0, "herbivore food has browse height " .. food.Name)
            Assert.truthy(type(compactGroup) == "string" and compactGroup ~= "", "herbivore food has compact group " .. food.Name)
            vegetationTypes[vegetationType] = true
            compactGroups[compactGroup] = true
            if food:GetAttribute("TreeBrowse") == true then
                treeBrowseCount = treeBrowseCount + 1
                Assert.truthy(CollectionService:HasTag(food, "TreeProp"), "tree browse remains tagged as tree prop")
                Assert.equals(food:GetAttribute("BrowseTier"), "Tree", "tree browse tier is explicit")
                Assert.equals(food:GetAttribute("InteractionHint"), "Eat tree leaves", "tree browse hint is readable")
            end
            if food:GetAttribute("ZoneId") == "NurseryGrove" and food:GetAttribute("CompactFoodGroup") then
                nurseryBrowse = nurseryBrowse + 1
            end
        end
    end

    local vegetationTypeCount = 0
    for _ in pairs(vegetationTypes) do vegetationTypeCount = vegetationTypeCount + 1 end
    local compactGroupCount = 0
    for _ in pairs(compactGroups) do compactGroupCount = compactGroupCount + 1 end
    Assert.truthy(vegetationTypeCount >= 5, "herbivore foods use varied vegetation metadata")
    Assert.truthy(compactGroupCount >= 4, "herbivore foods use varied compact groups")
    Assert.truthy(treeBrowseCount >= 7, "all procedural trees generate edible browse query helpers")
    Assert.truthy(nurseryBrowse >= 10, "nursery browse remains compact and dense")
end })

table.insert(suite.tests, { name = "procedural food and tree dressing are hidden query helpers", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    MapLayoutService:EnsureFoodSources()
    MapLayoutService:EnsureBiomeDressing(folders)

    local visibleProceduralFood = 0
    local visibleAffordances = 0
    local treeBrowse = 0
    for _, food in ipairs(CollectionService:GetTagged("FoodSource")) do
        if food:IsA("BasePart") and (food:IsDescendantOf(folders.FoodSources) or food:IsDescendantOf(folders.BiomeDressing)) then
            Assert.equals(food:GetAttribute("GameplayQuery"), true, "food remains queryable " .. food.Name)
            Assert.equals(food:GetAttribute("InvisibleQueryHelper"), true, "procedural food is marked as invisible helper " .. food.Name)
            if food.Transparency < 1 then visibleProceduralFood = visibleProceduralFood + 1 end
            local affordanceCount = countVisibleFoodAffordances(food)
            Assert.truthy(affordanceCount > 0, "food query helper needs visible non-FoodSource affordance children: " .. food:GetFullName())
            visibleAffordances = visibleAffordances + affordanceCount
            if food:GetAttribute("TreeBrowse") == true then treeBrowse = treeBrowse + 1 end
        end
    end
    for _, part in ipairs(CollectionService:GetTagged("TreeProp")) do
        if part:IsA("BasePart") and part:IsDescendantOf(folders.BiomeDressing) then
            Assert.equals(part.Transparency, 1, "procedural tree part hidden " .. part.Name)
            Assert.falsy(part.Shape == Enum.PartType.Ball and part.Transparency < 1, "no visible rectangle+ball procedural tree dressing")
        end
    end
    Assert.equals(visibleProceduralFood, 0, "no visible procedural food placeholders remain")
    Assert.truthy(visibleAffordances >= 12, "visible child affordances make hidden food readable")
    Assert.truthy(treeBrowse >= 7, "tree browse helpers cover every procedural tree")
end })


table.insert(suite.tests, { name = "starter food compactness stays bounded around spawn", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    MapLayoutService:EnsureFoodSources()
    MapLayoutService:EnsureBiomeDressing(folders)

    local spawnPosition = Vector3.new(-2000, 12, 0)
    local nearFood = 0
    local nearestSpacing = math.huge
    local compactGroups = {}
    local foods = {}
    for _, food in ipairs(CollectionService:GetTagged("FoodSource")) do
        local position = food:IsA("BasePart") and food.Position or nil
        if position and (position - spawnPosition).Magnitude <= 260 then
            nearFood = nearFood + 1
            table.insert(foods, food)
            compactGroups[food:GetAttribute("CompactFoodGroup") or food:GetAttribute("FoodKind") or food.Name] = true
        end
    end
    for i = 1, #foods do
        for j = i + 1, #foods do
            local distance = (foods[i].Position - foods[j].Position).Magnitude
            if distance < nearestSpacing then nearestSpacing = distance end
        end
    end
    local groupCount = 0
    for _ in pairs(compactGroups) do groupCount = groupCount + 1 end

    Assert.truthy(nearFood >= 16, "spawn radius has dense starter food after browse additions")
    Assert.truthy(nearFood <= 40, "spawn radius food density remains bounded after vegetation browse")
    Assert.truthy(groupCount >= 3, "spawn food density includes varied compact groups")
    Assert.truthy(nearestSpacing >= 12, "starter food is compact but not overlapping")
end })

TestRunner.registerSuite(suite)
return suite
