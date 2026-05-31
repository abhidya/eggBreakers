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

table.insert(suite.tests, { name = "map placement resolves against live terrain height", run = function()
    local oldRaycastTerrainSurfaceY = MapLayoutService.RaycastTerrainSurfaceY
    local ok, err = pcall(function()
        MapLayoutService.RaycastTerrainSurfaceY = function(_, _x, _z)
            return 48
        end

        local playerPosition, playerGroundY, playerSource = MapLayoutService:ResolveGroundedPartPosition(Vector3.new(-2000, 12, 0), Vector3.new(18, 2, 18), "NurseryGrove", 0)
        Assert.equals(playerPosition.Y, 49, "player spawn center rests on live terrain")
        Assert.equals(playerGroundY, 48, "player spawn records terrain ground")
        Assert.equals(playerSource, "Terrain", "player spawn source is live terrain")

        local npcPosition, npcGroundY = MapLayoutService:ResolveNPCSpawnMarkerPosition({
            position = Vector3.new(-1950, 14, 50),
            zone = "NurseryGrove",
            kind = "Prey",
        }, Vector3.new(8, 2, 8))
        Assert.equals(npcPosition.Y, 52, "ground NPC marker is lifted above live terrain")
        Assert.equals(npcGroundY, 48, "NPC marker records terrain ground")

        local aerialPosition = MapLayoutService:ResolveNPCSpawnMarkerPosition({
            position = Vector3.new(-1090, 60, -437),
            zone = "RedstoneCanyon",
            kind = "AerialPrey",
        }, Vector3.new(8, 2, 8))
        Assert.equals(aerialPosition.Y, 80, "aerial marker preserves flight room over live terrain")

        local waterCenter = MapLayoutService:ResolveWaterCenter({
            center = Vector3.new(-2000, 10, 70),
            size = Vector3.new(160, 5, 90),
            zone = "NurseryGrove",
        })
        Assert.between(waterCenter.Y, 45.64, 45.66, "water volume top is brought to terrain surface")
    end)
    MapLayoutService.RaycastTerrainSurfaceY = oldRaycastTerrainSurfaceY
    if not ok then error(err) end
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

local function assertNoOverlap(instances, minDistance, label)
    for i = 1, #instances do
        for j = i + 1, #instances do
            local a = instances[i]
            local b = instances[j]
            local distance = (a.Position - b.Position).Magnitude
            Assert.truthy(distance >= minDistance, label .. " overlap: " .. a.Name .. " near " .. b.Name .. " at " .. tostring(math.floor(distance + 0.5)) .. " studs")
        end
    end
end

table.insert(suite.tests, { name = "spawn markers are non-overlapping and ground-aware", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    local playerSpawns = {}
    for _, spawn in ipairs(spawnFolder:GetChildren()) do
        if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") ~= "starter_fallback" then
            table.insert(playerSpawns, spawn)
            Assert.equals(spawn:GetAttribute("AvoidOverlap"), true, spawn.Name .. " overlap rule")
            Assert.truthy(type(spawn:GetAttribute("GroundTopY")) == "number", spawn.Name .. " ground-aware")
            Assert.falsy(spawn:GetAttribute("FloatingAllowed"), spawn.Name .. " is not allowed to float")
        end
    end

    local npcSpawns = folders.NPCSpawns:GetChildren()
    assertNoOverlap(playerSpawns, 14, "player spawn")
    assertNoOverlap(npcSpawns, 10, "NPC spawn")
end })

table.insert(suite.tests, { name = "species spawn resolver returns requested biome when available", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local spawn, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("carnotaurus", "RedstoneCanyon", 1)
    Assert.notNil(spawn, "carnotaurus spawn resolves")
    Assert.equals(spawn:GetAttribute("SpeciesId"), "carnotaurus", "spawn is for requested species")
    Assert.equals(spawn:GetAttribute("ZoneId"), "RedstoneCanyon", "resolver honors preferred biome")
    Assert.notNil(spawnCFrame, "spawn cframe returned")
end })

table.insert(suite.tests, { name = "carnotaurus player spawns are upright source expectations", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    local count = 0
    for _, spawn in ipairs(spawnFolder:GetChildren()) do
        if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") == "carnotaurus" then
            count = count + 1
            Assert.equals(spawn:GetAttribute("SourceExpectedUpright"), true, spawn.Name .. " source expectation is upright")
            Assert.equals(spawn:GetAttribute("PitchDegrees"), 0, spawn.Name .. " has no upside-down pitch")
            Assert.equals(spawn:GetAttribute("RollDegrees"), 0, spawn.Name .. " has no upside-down roll")
            local _, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("carnotaurus", spawn:GetAttribute("ZoneId"), count)
            Assert.truthy(spawnCFrame.UpVector:Dot(Vector3.new(0, 1, 0)) >= 0.99, spawn.Name .. " resolved CFrame remains upright")
        end
    end
    Assert.truthy(count >= 3, "carnotaurus retains multiple upright spawn configs")
end })

TestRunner.registerSuite(suite)
return suite
