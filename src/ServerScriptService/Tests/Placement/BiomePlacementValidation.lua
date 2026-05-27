local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)

local suite = { name = "BiomePlacementValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "required biome folders exist", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    for zoneId in pairs(ZoneConfig) do
        Assert.notNil(folders.Zones:FindFirstChild(zoneId), "missing zone folder " .. zoneId)
    end
end })

table.insert(suite.tests, { name = "biomes contain imported identity props and markers", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    Assert.notNil(folders.Landmarks, "landmark folder exists")
    Assert.notNil(folders.FoodSources, "food source folder exists")
    Assert.notNil(folders.WaterSources, "water source folder exists")
    Assert.notNil(folders.NPCSpawns, "NPC spawn folder exists")
end })


table.insert(suite.tests, { name = "asset manifest placement rules keep biome props coherent", run = function()
    local result = AssetManifest.Validate({ minimum = 500 })
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    local cityCount = 0
    local swampCount = 0
    local rockCount = 0
    local fossilOutsideSafeCount = 0
    local foliageEdgeCount = 0

    for _, entry in ipairs(AssetManifest.Entries) do
        Assert.equals(entry.PlacementPattern, "natural_offset_no_grid", "no grid/square placement for " .. entry.AssetId)
        Assert.truthy(entry.AvoidRouteCenters, "route centers kept clear for " .. entry.AssetId)
        local text = string.lower(table.concat({ entry.Name or "", entry.CreatorStoreSearchQuery or "", entry.SourceCategoryPath or "" }, " "))
        if string.find(text, "city", 1, true) or string.find(text, "car", 1, true) or string.find(text, "rubble", 1, true) or string.find(text, "ruin", 1, true) then
            Assert.equals(entry.UsedIn, "ApocalypticCity", "city prop belongs in Apocalyptic City: " .. entry.AssetId)
            cityCount = cityCount + 1
        end
        if string.find(text, "swamp", 1, true) or string.find(text, "water lily", 1, true) then
            Assert.equals(entry.UsedIn, "SwampDelta", "swamp prop belongs in Swamp Delta: " .. entry.AssetId)
            swampCount = swampCount + 1
        end
        if string.find(text, "rock", 1, true) or string.find(text, "cliff", 1, true) or string.find(text, "boulder", 1, true) then
            Assert.truthy(entry.UsedIn == "RedstoneCanyon" or entry.UsedIn == "MountainNestingCliffs", "rock/cliff prop belongs in redstone or mountain: " .. entry.AssetId)
            rockCount = rockCount + 1
        end
        if entry.AssetType == "Fossil" then
            Assert.falsy(entry.UsedIn == "NurseryGrove", "fossils stay outside safe nursery: " .. entry.AssetId)
            fossilOutsideSafeCount = fossilOutsideSafeCount + 1
        end
        if entry.AssetType == "Foliage" then
            Assert.truthy(entry.PlacementBand == "NaturalGroveEdge" or entry.PlacementBand == "SwampBankEdge", "foliage stays on grove/bank edges: " .. entry.AssetId)
            foliageEdgeCount = foliageEdgeCount + 1
        end
    end

    Assert.truthy(cityCount > 0, "city prop coverage exists")
    Assert.truthy(swampCount > 0, "swamp prop coverage exists")
    Assert.truthy(rockCount > 0, "rock/cliff coverage exists")
    Assert.truthy(fossilOutsideSafeCount > 0, "fossil coverage exists")
    Assert.truthy(foliageEdgeCount > 0, "foliage edge coverage exists")
end })

table.insert(suite.tests, { name = "full map terrain underlay is single and oversized", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    Assert.truthy(folders.Map:GetAttribute("FullMapTerrainUnderlay"), "full map underlay marker set")
    Assert.equals(folders.Map:GetAttribute("FullMapTerrainUnderlaySize"), "4700,12,4400", "full map underlay covers all biomes and routes")
end })

TestRunner.registerSuite(suite)
return suite
