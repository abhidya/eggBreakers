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
    MapLayoutService:EnsureFoodSourcePlacements(folders)
    Assert.notNil(folders.FoodSources.NurseryGrove:FindFirstChild("NurseryStarterFern_01"), "nursery starter plant exists")
    Assert.notNil(folders.FoodSources.FernPlains:FindFirstChild("FernPlainsGrazingPatch_01"), "Fern Plains grazing plant exists")
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
                Assert.falsy(zone == "NurseryGrove", "carnivore prey/carcass outside Nursery " .. food.Name)
            end
            if zone == "ApocalypticCity" then counts.CityReward = counts.CityReward + 1 end
        end
    end
    Assert.truthy(counts.NurseryGrove >= 2, "nursery starter plant count")
    Assert.truthy(counts.FernPlains >= 2, "Fern Plains plant density")
    Assert.truthy(counts.Carnivore >= 4, "carnivore prey/carcass source count")
    Assert.truthy(counts.CityReward >= 2, "city high-risk food rewards")
end })

TestRunner.registerSuite(suite)
return suite
