local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)

local suite = { name = "CollisionValidation", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "routes not blocked and required connections exist", run = function()
    local ok, missing = MapLayoutService:ValidateLayoutFolders()
    Assert.truthy(ok, "missing layout folders: " .. table.concat(missing, ", "))
end })

table.insert(suite.tests, { name = "invisible gameplay helpers are isolated", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFallSafetyVolume(folders)
    local safety = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_FallSafetyCatch")
    Assert.notNil(folders.InvisibleGameplayVolumes, "InvisibleGameplayVolumes folder exists")
    Assert.equals(folders.InvisibleGameplayVolumes.Name, MapLayoutService.InvisibleFolderName, "helper folder name")
    Assert.notNil(safety, "fall safety helper exists")
    Assert.equals(safety.Parent, folders.InvisibleGameplayVolumes, "fall safety helper stored in approved folder")
    Assert.equals(safety.Transparency, 1, "fall safety helper is invisible")
end })

table.insert(suite.tests, { name = "terrain-backed zones and safe routes are continuous", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)

    for zoneId in pairs(ZoneConfig) do
        local zoneFolder = folders.Zones:FindFirstChild(zoneId)
        Assert.notNil(zoneFolder, "missing zone folder " .. zoneId)
        Assert.truthy(zoneFolder:GetAttribute("TerrainBacked"), "zone lacks terrain backing " .. zoneId)
    end

    local babySafe = folders.Routes:FindFirstChild("NurseryToFernBabySafe")
    local nurseryToJungle = folders.Routes:FindFirstChild("NurseryToJungleBabySafe")
    local canyonCity = folders.Routes:FindFirstChild("RedstoneCanyonGateToCity")
    local swampCity = folders.Routes:FindFirstChild("SwampDeltaCausewayToCity")
    Assert.truthy(babySafe and babySafe:GetAttribute("BabySafeRoute"), "Nursery to Fern baby-safe route missing")
    Assert.truthy(nurseryToJungle and nurseryToJungle:GetAttribute("BabySafeRoute"), "Nursery to Jungle baby-safe route missing")
    Assert.truthy(canyonCity and canyonCity:GetAttribute("CityRoute"), "canyon city route missing")
    Assert.truthy(swampCity and swampCity:GetAttribute("CityRoute"), "swamp city route missing")
    Assert.notNil(folders.Routes:FindFirstChild("MountainNestSaddle"), "mountain nesting cliff route missing")

    local underlay = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. MapLayoutService.FullMapUnderlay.name)
    Assert.notNil(underlay, "full-map safe terrain underlay marker missing")
    Assert.truthy(underlay:GetAttribute("TerrainUnderlay"), "underlay marker lacks TerrainUnderlay attribute")
    Assert.equals(underlay:GetAttribute("GroundTopY"), MapLayoutService.FullMapUnderlay.topY, "underlay top Y marker")
end })

table.insert(suite.tests, { name = "water sources remain shallow", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)

    for _, water in ipairs(MapLayoutService.ShallowWater) do
        local marker = folders.WaterSources:FindFirstChild(water.name)
        Assert.notNil(marker, "missing shallow water marker " .. water.name)
        Assert.truthy(marker:GetAttribute("ShallowWater"), "water source is not marked shallow " .. water.name)
        Assert.truthy(marker:GetAttribute("SwimmableDepthStuds") <= 5, "water source too deep " .. water.name)
    end
end })

return TestRunner.registerSuite(suite)
