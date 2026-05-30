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
    Assert.notNil(folders.BiomeDressing, "biome dressing folder exists")
end })



table.insert(suite.tests, { name = "visible trees and biome dressing are materialized", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureBiomeDressing(folders)

    local visibleTrees = 0
    local visibleDressingZones = {}
    for _, instance in ipairs(folders.BiomeDressing:GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("BiomeDressing") == true and instance.Transparency < 1 then
            local zoneId = instance:GetAttribute("ZoneId")
            visibleDressingZones[zoneId] = true
            if instance:GetAttribute("DressingKind") == "Tree" then
                visibleTrees = visibleTrees + 1
            end
            Assert.truthy(instance:GetAttribute("AvoidRouteCenters"), "dressing keeps route centers clear: " .. instance.Name)
        end
    end

    local zoneCount = 0
    for _ in pairs(visibleDressingZones) do
        zoneCount = zoneCount + 1
    end
    Assert.truthy(visibleTrees >= 20, "ten visible trees create trunk/canopy parts")
    Assert.truthy(zoneCount >= 7, "dressing covers every major biome")
end })

table.insert(suite.tests, { name = "scenic landmarks and flower clusters are materialized", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureBiomeDressing(folders)

    local counts = {
        scenic = 0,
        flowers = 0,
        volcano = 0,
        lava = 0,
        mountain = 0,
        forest = 0,
        waterScenery = 0,
    }
    local flowerZones = {}

    for _, instance in ipairs(folders.BiomeDressing:GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("BiomeDressing") == true and instance.Transparency < 1 then
            local kind = instance:GetAttribute("DressingKind")
            if instance:GetAttribute("ScenicLandmark") == true then
                counts.scenic = counts.scenic + 1
                Assert.truthy(instance:GetAttribute("AvoidRouteCenters"), "scenic landmark avoids route centers: " .. instance.Name)
            end
            if instance:GetAttribute("FlowerCluster") == true then
                counts.flowers = counts.flowers + 1
                flowerZones[instance:GetAttribute("ZoneId")] = true
            end
            if kind == "Volcano" then counts.volcano = counts.volcano + 1 end
            if instance:GetAttribute("LavaVisual") == true then
                counts.lava = counts.lava + 1
                Assert.equals(instance.Material, Enum.Material.Neon, "lava marker uses bright visual material")
            end
            if kind == "Cliff" or kind == "MountainPeak" then counts.mountain = counts.mountain + 1 end
            if kind == "ForestVista" then counts.forest = counts.forest + 1 end
            if kind == "LakeShore" or kind == "RiverBend" then counts.waterScenery = counts.waterScenery + 1 end
        end
    end

    local flowerZoneCount = 0
    for _ in pairs(flowerZones) do
        flowerZoneCount = flowerZoneCount + 1
    end

    Assert.truthy(counts.scenic >= 11, "scenic landmark coverage includes volcano/mountain/forest/water/flowers")
    Assert.truthy(counts.flowers >= 4, "flower fields and clusters are visible vegetation")
    Assert.truthy(flowerZoneCount >= 4, "flower clusters cover varied biomes")
    Assert.truthy(counts.volcano >= 1, "volcano scenic marker exists")
    Assert.truthy(counts.lava >= 1, "lava-safe visual marker exists")
    Assert.truthy(counts.mountain >= 2, "mountain and cliff scenery exists")
    Assert.truthy(counts.forest >= 1, "richer forest scenery exists")
    Assert.truthy(counts.waterScenery >= 2, "lake and river scenery exists")
end })

table.insert(suite.tests, { name = "rich habitats expose swim fish herds and flying prey", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    MapLayoutService:EnsureBiomeDressing(folders)
    MapLayoutService:EnsureNPCSpawnMarkers(folders)

    local habitatCounts = { Forest = 0, Desert = 0 }
    for _, instance in ipairs(folders.BiomeDressing:GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("BiomeDressing") == true then
            local feature = instance:GetAttribute("HabitatFeature")
            if feature == "Forest" or feature == "Desert" then
                habitatCounts[feature] = habitatCounts[feature] + 1
                Assert.equals(instance:GetAttribute("ScenicLandmark"), true, "habitat feature is visible scenery")
            end
        end
    end

    local swimZones = 0
    local fishWater = 0
    for _, water in ipairs(folders.WaterSources:GetChildren()) do
        if water:IsA("BasePart") then
            if water:GetAttribute("SwimZone") == true then swimZones = swimZones + 1 end
            if water:GetAttribute("FishSpawnAllowed") == true then fishWater = fishWater + 1 end
        end
    end

    local nestingHerd = 0
    local flyingPrey = 0
    local mountainNest = MapLayoutService.ZoneTerrain.MountainNestingCliffs.center
    for _, marker in ipairs(folders.NPCSpawns:GetChildren()) do
        if marker:GetAttribute("NestingHerd") == true then
            nestingHerd = nestingHerd + 1
            Assert.equals(marker:GetAttribute("NPCKind"), "Prey", "nesting herd markers are herbivore prey")
            Assert.truthy((marker.Position - mountainNest).Magnitude <= 900 or marker:GetAttribute("ZoneId") ~= "MountainNestingCliffs", "mountain herd remains near nesting cliffs")
        end
        if marker:GetAttribute("FlyingPrey") == true then
            flyingPrey = flyingPrey + 1
            Assert.equals(marker:GetAttribute("FlightTarget"), true, "flying prey exposes flight target metadata")
            Assert.truthy(marker.Position.Y >= 60, "flying prey starts at airborne height")
        end
    end

    Assert.truthy(habitatCounts.Forest >= 2, "denser forest habitat markers exist")
    Assert.truthy(habitatCounts.Desert >= 2, "redstone desert habitat markers exist")
    Assert.truthy(swimZones >= 3, "lakes and rivers expose swim zones")
    Assert.truthy(fishWater >= 3, "lakes and rivers allow fish spawning")
    Assert.truthy(nestingHerd >= 4, "nesting sites have nearby herbivore herd markers")
    Assert.truthy(flyingPrey >= 2, "pterodactyl prey has flying NPC markers")
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
        if entry.SourceAssetId ~= "4596418748" then
            Assert.equals(entry.PlacementPattern, "natural_offset_no_grid", "no grid/square placement for " .. entry.AssetId)
            Assert.truthy(entry.AvoidRouteCenters, "route centers kept clear for " .. entry.AssetId)
            local text = string.lower(table.concat({ entry.Name or "", entry.CreatorStoreSearchQuery or "", entry.SourceCategoryPath or "" }, " "))
            local cityLike = string.find(text, "city", 1, true) or string.find(text, "car", 1, true) or string.find(text, "rubble", 1, true) or string.find(text, "ruin", 1, true) or string.find(text, "debris", 1, true)
            local swampLike = string.find(text, "swamp", 1, true) or string.find(text, "water lily", 1, true)
            if cityLike then
                Assert.equals(entry.UsedIn, "ApocalypticCity", "city prop belongs in Apocalyptic City: " .. entry.AssetId)
                cityCount = cityCount + 1
            end
            if swampLike and not cityLike then
                Assert.equals(entry.UsedIn, "SwampDelta", "swamp prop belongs in Swamp Delta: " .. entry.AssetId)
                swampCount = swampCount + 1
            end
            if (string.find(text, "rock", 1, true) or string.find(text, "cliff", 1, true) or string.find(text, "boulder", 1, true)) and not cityLike then
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
    end

    Assert.truthy(cityCount > 0, "city prop coverage exists")
    Assert.truthy(swampCount > 0, "swamp prop coverage exists")
    Assert.truthy(rockCount > 0, "rock/cliff coverage exists")
    Assert.truthy(fossilOutsideSafeCount > 0, "fossil coverage exists")
    Assert.truthy(foliageEdgeCount > 0, "foliage edge coverage exists")
end })

table.insert(suite.tests, { name = "full map terrain underlay is single and compact", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    Assert.truthy(folders.Map:GetAttribute("FullMapTerrainUnderlay"), "full map underlay marker set")
    Assert.equals(folders.Map:GetAttribute("FullMapTerrainUnderlaySize"), "2350,12,2200", "50% compact full map underlay covers all biomes and routes")
end })

table.insert(suite.tests, { name = "compact map keeps every biome in playable range", run = function()
    local nurseryCenter = MapLayoutService.ZoneTerrain.NurseryGrove.center
    local biomeCount = 0
    local maxDistance = 0

    for zoneId in pairs(ZoneConfig) do
        local zone = MapLayoutService.ZoneTerrain[zoneId]
        Assert.notNil(zone, "zone terrain preserved for " .. zoneId)
        biomeCount = biomeCount + 1
        local distance = (zone.center - nurseryCenter).Magnitude
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    Assert.equals(biomeCount, 7, "all seven biomes remain represented")
    Assert.truthy(maxDistance <= 1400, "outer biome centers are condensed below long empty traversal")
    Assert.equals(MapLayoutService.CompactLayout.scaleXZ, 0.5, "compact transform documents 50% traversal scale")
end })

TestRunner.registerSuite(suite)
return suite
