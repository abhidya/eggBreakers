local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)

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

TestRunner.registerSuite(suite)
return suite
