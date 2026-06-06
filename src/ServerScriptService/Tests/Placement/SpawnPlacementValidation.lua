local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local WaterService = require(ServerScriptService.Services.WaterService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local CollectionService = game:GetService("CollectionService")

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

        MapLayoutService.RaycastTerrainSurfaceY = function(_, _x, _z)
            return -40
        end
        local clampedPosition, clampedGroundY, clampedSource = MapLayoutService:ResolveGroundedPartPosition(Vector3.new(-2000, -30, 0), Vector3.new(18, 2, 18), "NurseryGrove", 0)
        local nurseryTopY = MapLayoutService:GetGroundTopYForZone("NurseryGrove")
        Assert.equals(clampedGroundY, nurseryTopY, "underlay terrain hit clamps back to zone ground")
        Assert.equals(clampedPosition.Y, nurseryTopY + 1, "underlay terrain hit cannot bury spawn below zone")
        Assert.equals(clampedSource, "ZoneTopClampedTerrain", "clamped terrain source is explicit")
    end)
    MapLayoutService.RaycastTerrainSurfaceY = oldRaycastTerrainSurfaceY
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "generated food decor prey and water clamp above live terrain", run = function()
    local oldRaycastTerrainSurfaceY = MapLayoutService.RaycastTerrainSurfaceY
    local oldNPCSpawnPlacements = MapLayoutService.NPCSpawnPlacements
    local oldBiomeDressingPlacements = MapLayoutService.BiomeDressingPlacements
    local probeRoot = Instance.new("Folder")
    probeRoot.Name = "BelowTerrainPlacementProbeRoot"
    probeRoot.Parent = workspace

    local folders = {
        WaterSources = Instance.new("Folder"),
        FoodSources = Instance.new("Folder"),
        BiomeDressing = Instance.new("Folder"),
        NPCSpawns = Instance.new("Folder"),
    }
    for name, folder in pairs(folders) do
        folder.Name = name
        folder.Parent = probeRoot
    end

    local ok, err = pcall(function()
        MapLayoutService.RaycastTerrainSurfaceY = function(_, _x, _z)
            return 48
        end

        local drinkableWater = MapLayoutService:EnsureShallowWaterMarker(folders, {
            name = "DrinkableClampProbeWater",
            zone = "NurseryGrove",
            center = Vector3.new(-2000, -30, 0),
            size = Vector3.new(32, 3, 24),
            tutorialSafe = true,
        })
        Assert.equals(drinkableWater:GetAttribute("GroundTopY"), 48, "drinkable water records live ground")
        Assert.truthy(drinkableWater.Position.Y + drinkableWater.Size.Y / 2 >= 48, "drinkable water surface is not below terrain")
        Assert.equals(drinkableWater.CanTouch, true, "drinkable water can be touched")
        Assert.equals(drinkableWater.CanQuery, true, "drinkable water can be queried")
        Assert.equals(drinkableWater:GetAttribute("ShallowDrinkable"), true, "drinkable water stamped shallow")
        Assert.truthy(CollectionService:HasTag(drinkableWater, "DrinkableWater"), "drinkable water tag applied immediately")
        Assert.truthy(WaterService:IsValidDrinkableWater(drinkableWater), "drinkable water passes service gate")

        local swimWater = MapLayoutService:EnsureShallowWaterMarker(folders, {
            name = "SwimClampProbeWater",
            zone = "NurseryGrove",
            center = Vector3.new(-1992, -30, 20),
            size = Vector3.new(36, 5, 28),
            swimZone = true,
            fishSpawnAllowed = true,
        })
        Assert.falsy(CollectionService:HasTag(swimWater, "DrinkableWater"), "swim/fish water is not drinkable")
        Assert.truthy(CollectionService:HasTag(swimWater, "SwimWater"), "swim/fish water is tagged separately")

        local food = MapLayoutService:EnsureFoodSource(folders, {
            name = "BelowTerrainFoodProbe",
            zone = "NurseryGrove",
            diet = "Herbivore",
            nutrition = 24,
            respawnSeconds = 45,
            position = Vector3.new(-1988, -40, 12),
            size = Vector3.new(8, 2, 8),
            color = Color3.fromRGB(78, 160, 72),
        })
        Assert.equals(food.Position.Y, 49, "food query center lifts above live terrain")
        Assert.equals(food:GetAttribute("GroundTopY"), 48, "food records live ground")
        Assert.equals(food:GetAttribute("PlacementSurfaceSource"), "Terrain", "food records terrain source")
        Assert.equals(food:GetAttribute("FloatingAllowed"), false, "food may not float")
        Assert.truthy(food.Position.Y - food.Size.Y / 2 >= 48, "food bottom is not below terrain")

        MapLayoutService.BiomeDressingPlacements = {
            {
                name = "BelowTerrainGateProbe",
                zone = "NurseryGrove",
                kind = "Boulder",
                position = Vector3.new(-1976, -60, 24),
                size = Vector3.new(22, 8, 16),
                color = Color3.fromRGB(132, 108, 88),
                material = Enum.Material.Rock,
                habitatFeature = "BiomeGate",
                scenicLandmark = true,
                biomeGate = true,
            },
        }
        MapLayoutService:EnsureBiomeDressing(folders)
        local gate = folders.BiomeDressing.NurseryGrove:FindFirstChild("BelowTerrainGateProbe")
        Assert.notNil(gate, "probe biome gate materialized")
        Assert.equals(gate.Position.Y, 52, "decor gate center lifts above live terrain")
        Assert.equals(gate:GetAttribute("GroundTopY"), 48, "decor gate records live ground")
        Assert.equals(gate:GetAttribute("BiomeGate"), true, "decor gate keeps story gate contract")
        Assert.truthy(gate.Position.Y - gate.Size.Y / 2 >= 48, "decor gate bottom is not below terrain")

        MapLayoutService.NPCSpawnPlacements = {
            {
                name = "BelowTerrainPreySpawnProbe",
                position = Vector3.new(-1964, -80, 36),
                kind = "Prey",
                zone = "NurseryGrove",
                tutorialSafe = true,
            },
        }
        MapLayoutService:EnsureNPCSpawnMarkers(folders)
        local prey = folders.NPCSpawns:FindFirstChild("BelowTerrainPreySpawnProbe")
        Assert.notNil(prey, "probe prey spawn materialized")
        Assert.equals(prey.Position.Y, 52, "prey spawn marker lifts above live terrain")
        Assert.equals(prey:GetAttribute("GroundTopY"), 48, "prey spawn records live ground")
        Assert.equals(prey:GetAttribute("PlacementSurfaceSource"), "Terrain", "prey spawn records terrain source")
        Assert.equals(prey:GetAttribute("FloatingAllowed"), false, "ground prey spawn may not float")
        Assert.equals(prey:GetAttribute("PotentialCarnivoreFood"), true, "prey spawn remains food-variety candidate")
    end)

    MapLayoutService.RaycastTerrainSurfaceY = oldRaycastTerrainSurfaceY
    MapLayoutService.NPCSpawnPlacements = oldNPCSpawnPlacements
    MapLayoutService.BiomeDressingPlacements = oldBiomeDressingPlacements
    probeRoot:Destroy()
    if not ok then error(err) end
end })


table.insert(suite.tests, { name = "starter species have multiple biome routed player spawns", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    Assert.notNil(spawnFolder, "SpawnLocations folder exists")

    local starterSpecies = { "coelophysis", "parasaurolophus", "utahraptor", "citipati" }
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

table.insert(suite.tests, { name = "citipati routed spawns stay inside their story biomes", run = function()
    local checked = {}
    for _, spec in ipairs(MapLayoutService.PlayerSpawnPlacements) do
        if spec.speciesId == "citipati" and (spec.zone == "JungleBasin" or spec.zone == "FernPlains") then
            local zone = MapLayoutService.ZoneTerrain[spec.zone]
            Assert.notNil(zone, "zone terrain exists for " .. spec.zone)
            local dx = math.abs(spec.position.X - zone.center.X)
            local dz = math.abs(spec.position.Z - zone.center.Z)
            Assert.truthy(dx <= zone.size.X * 0.5, spec.name .. " X stays within " .. spec.zone)
            Assert.truthy(dz <= zone.size.Z * 0.5, spec.name .. " Z stays within " .. spec.zone)
            checked[spec.zone] = true
        end
    end

    Assert.equals(checked.JungleBasin, true, "citipati has JungleBasin story spawn")
    Assert.equals(checked.FernPlains, true, "citipati has FernPlains story spawn")
end })

table.insert(suite.tests, { name = "citipati materialized spawns resolve inside story biomes", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    Assert.notNil(spawnFolder, "SpawnLocations folder exists")

    local actualByZone = {}
    for _, spawn in ipairs(spawnFolder:GetChildren()) do
        if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") == "citipati" then
            local zoneId = spawn:GetAttribute("ZoneId")
            local zone = MapLayoutService.ZoneTerrain[zoneId]
            Assert.notNil(zone, "citipati spawn zone terrain exists " .. tostring(zoneId))
            local dx = math.abs(spawn.Position.X - zone.center.X)
            local dz = math.abs(spawn.Position.Z - zone.center.Z)
            Assert.truthy(dx <= zone.size.X * 0.5 + 1, spawn.Name .. " materialized X stays within " .. zoneId)
            Assert.truthy(dz <= zone.size.Z * 0.5 + 1, spawn.Name .. " materialized Z stays within " .. zoneId)
            actualByZone[zoneId] = true
        end
    end

    local spawn, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("citipati", "JungleBasin", 1)
    Assert.notNil(spawn, "citipati JungleBasin spawn resolves")
    Assert.equals(spawn:GetAttribute("SpeciesId"), "citipati", "resolver returns citipati spawn")
    Assert.equals(spawn:GetAttribute("ZoneId"), "JungleBasin", "resolver honors Citipati JungleBasin story biome")
    Assert.truthy(spawnCFrame.UpVector:Dot(Vector3.new(0, 1, 0)) >= 0.99, "resolved Citipati spawn remains upright")
    Assert.equals(actualByZone.JungleBasin, true, "materialized Citipati JungleBasin spawn exists")
    Assert.equals(actualByZone.FernPlains, true, "materialized Citipati FernPlains spawn exists")
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

table.insert(suite.tests, { name = "map has drinkable water varied food decor and prey gates", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()

    local drinkableWater = 0
    for _, water in ipairs(folders.WaterSources:GetChildren()) do
        if water:IsA("BasePart") then
            Assert.equals(water.CanTouch, true, water.Name .. " water can be touched")
            Assert.equals(water.CanQuery, true, water.Name .. " water can be queried")
            if CollectionService:HasTag(water, "DrinkableWater") then
                drinkableWater = drinkableWater + 1
                Assert.equals(water:GetAttribute("ShallowDrinkable"), true, water.Name .. " drinkable attr")
                Assert.truthy(WaterService:IsValidDrinkableWater(water), water.Name .. " passes drinkable gate")
            end
        end
    end

    local foodCount = 0
    local carnivoreFood = 0
    local vegetationTypes = {}
    for _, food in ipairs(folders.FoodSources:GetDescendants()) do
        if food:IsA("BasePart") and food:GetAttribute("FoodSource") ~= false and food:GetAttribute("Diet") ~= nil then
            foodCount = foodCount + 1
            if food:GetAttribute("Diet") == "Carnivore" then
                carnivoreFood = carnivoreFood + 1
            end
            local vegetationType = food:GetAttribute("VegetationType")
            if type(vegetationType) == "string" and vegetationType ~= "" then
                vegetationTypes[vegetationType] = true
            end
            local groundTopY = food:GetAttribute("GroundTopY")
            if type(groundTopY) == "number" then
                Assert.truthy(food.Position.Y - food.Size.Y / 2 >= groundTopY - 0.01, food.Name .. " food bottom is above ground")
            end
            Assert.truthy(type(food:GetAttribute("PlacementSurfaceSource")) == "string", food.Name .. " food records placement source")
        end
    end

    local visibleDecor = 0
    local elevatedCanopies = 0
    local decorZones = {}
    for _, decor in ipairs(folders.BiomeDressing:GetDescendants()) do
        if decor:IsA("BasePart") and decor:GetAttribute("PlacementRole") == "HiddenTreeCanopy" then
            local groundTopY = decor:GetAttribute("GroundTopY")
            if type(groundTopY) == "number" and decor.Position.Y - decor.Size.Y / 2 >= groundTopY + 4 then
                elevatedCanopies = elevatedCanopies + 1
            end
        end
        if decor:IsA("BasePart") and decor:GetAttribute("BiomeDressing") == true and decor.Transparency < 1 then
            visibleDecor = visibleDecor + 1
            local zoneId = decor:GetAttribute("ZoneId")
            if type(zoneId) == "string" then
                decorZones[zoneId] = true
            end
            local groundTopY = decor:GetAttribute("GroundTopY")
            if type(groundTopY) == "number" then
                Assert.truthy(decor.Position.Y - decor.Size.Y / 2 >= groundTopY - 0.25, decor.Name .. " decor bottom is above ground")
            end
        end
    end

    local decorZoneCount = 0
    for _ in pairs(decorZones) do
        decorZoneCount = decorZoneCount + 1
    end
    local vegetationTypeCount = 0
    for _ in pairs(vegetationTypes) do
        vegetationTypeCount = vegetationTypeCount + 1
    end

    local preySpawns = 0
    for _, spawn in ipairs(folders.NPCSpawns:GetChildren()) do
        if spawn:IsA("BasePart") and spawn:GetAttribute("NPCSpawn") == true then
            local groundTopY = spawn:GetAttribute("GroundTopY")
            Assert.truthy(type(groundTopY) == "number", spawn.Name .. " prey/NPC spawn records ground")
            if spawn:GetAttribute("FloatingAllowed") ~= true then
                Assert.truthy(spawn.Position.Y - spawn.Size.Y / 2 >= groundTopY - 0.01, spawn.Name .. " spawn bottom is above ground")
            end
            local kind = spawn:GetAttribute("NPCKind")
            if kind == "Prey" or kind == "AerialPrey" or kind == "FlyingPrey" then
                preySpawns = preySpawns + 1
            end
        end
    end

    Assert.truthy(drinkableWater >= 3, "map exposes multiple drinkable water sources")
    Assert.truthy(foodCount >= 24, "map exposes dense food waypoints")
    Assert.truthy(carnivoreFood >= 8, "map exposes carnivore food variety")
    Assert.truthy(vegetationTypeCount >= 5, "map exposes varied vegetation food")
    Assert.truthy(visibleDecor >= 25, "map exposes visible decor/vegetation")
    Assert.truthy(elevatedCanopies >= 7, "tree canopies stay elevated above trunks")
    Assert.truthy(decorZoneCount >= 7, "decor covers every major biome")
    Assert.truthy(preySpawns >= 8, "map exposes prey/flying-prey spawn variety")
end })

table.insert(suite.tests, { name = "species spawn resolver returns requested biome when available", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local spawn, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("utahraptor", "RedstoneCanyon", 1)
    Assert.notNil(spawn, "utahraptor spawn resolves")
    Assert.equals(spawn:GetAttribute("SpeciesId"), "utahraptor", "spawn is for requested species")
    Assert.equals(spawn:GetAttribute("ZoneId"), "RedstoneCanyon", "resolver honors preferred biome")
    Assert.notNil(spawnCFrame, "spawn cframe returned")
end })

table.insert(suite.tests, { name = "utahraptor player spawns are upright source expectations", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local folders = MapLayoutService:EnsureMapFolders()
    local spawnFolder = folders.Map:FindFirstChild("SpawnLocations")
    local count = 0
    for _, spawn in ipairs(spawnFolder:GetChildren()) do
        if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") == "utahraptor" then
            count = count + 1
            Assert.equals(spawn:GetAttribute("SourceExpectedUpright"), true, spawn.Name .. " source expectation is upright")
            Assert.equals(spawn:GetAttribute("PitchDegrees"), 0, spawn.Name .. " has no upside-down pitch")
            Assert.equals(spawn:GetAttribute("RollDegrees"), 0, spawn.Name .. " has no upside-down roll")
            local _, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies("utahraptor", spawn:GetAttribute("ZoneId"), count)
            Assert.truthy(spawnCFrame.UpVector:Dot(Vector3.new(0, 1, 0)) >= 0.99, spawn.Name .. " resolved CFrame remains upright")
        end
    end
    Assert.truthy(count >= 3, "utahraptor retains multiple upright spawn configs")
end })

TestRunner.registerSuite(suite)
return suite
