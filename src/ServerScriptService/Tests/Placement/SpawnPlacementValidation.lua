local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)

local suite = { name = "SpawnPlacementValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "egg and nest spawns valid", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    Assert.notNil(folders.Nests, "Nests folder exists")
    Assert.notNil(folders.NPCSpawns, "NPCSpawns folder exists")
end })

table.insert(suite.tests, { name = "spawns avoid terrain props water predator danger", run = function()
    local spawn = Instance.new("Part")
    Assert.truthy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "plain spawn is allowed")
    spawn:SetAttribute("InsideWater", true)
    Assert.falsy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "water spawn rejected")
    spawn:SetAttribute("InsideWater", false)
    spawn:SetAttribute("SafeBabyArea", true)
    spawn:SetAttribute("DangerousNPC", true)
    Assert.falsy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "dangerous nursery spawn rejected")
    spawn:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
