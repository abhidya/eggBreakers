local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

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


table.insert(suite.tests, { name = "starter species have multiple biome routed player spawns", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    Assert.notNil(spawnFolder, "SpawnLocations folder exists")

    local starterSpecies = { "gallimimus", "triceratops", "velociraptor", "carnotaurus" }
    for _, speciesId in ipairs(starterSpecies) do
        local species = SpeciesConfig[speciesId]
        local biomes = species.SpawnBiomes
        local allowed = {
            [biomes.Primary] = true,
            [biomes.Secondary] = true,
            [biomes.Nursery] = true,
        }
        local count = 0
        local zones = {}
        for _, spawn in ipairs(spawnFolder:GetChildren()) do
            if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") == speciesId then
                count = count + 1
                local zoneId = spawn:GetAttribute("ZoneId")
                zones[zoneId] = true
                Assert.truthy(allowed[zoneId], speciesId .. " spawn stays in configured biome: " .. tostring(zoneId))
                Assert.truthy(spawn:IsA("SpawnLocation"), speciesId .. " spawn is SpawnLocation")
                Assert.equals(spawn.Neutral, true, speciesId .. " spawn is neutral")
            end
        end
        Assert.truthy(count >= 3, speciesId .. " has multiple spawn points")
        Assert.truthy(zones[biomes.Primary], speciesId .. " has primary biome spawn")
        Assert.truthy(zones[biomes.Nursery], speciesId .. " has nursery spawn")
    end
end })

table.insert(suite.tests, { name = "species spawn resolver returns requested biome when available", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local spawn, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("carnotaurus", "RedstoneCanyon", 1)
    Assert.notNil(spawn, "carnotaurus spawn resolves")
    Assert.equals(spawn:GetAttribute("SpeciesId"), "carnotaurus", "spawn is for requested species")
    Assert.equals(spawn:GetAttribute("ZoneId"), "RedstoneCanyon", "resolver honors preferred biome")
    Assert.notNil(spawnCFrame, "spawn cframe returned")
end })

TestRunner.registerSuite(suite)
return suite
