local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

local MapLayoutService = {}
MapLayoutService.MapFolderName = "Map"
MapLayoutService.InvisibleFolderName = "InvisibleGameplayVolumes"

MapLayoutService.FullMapUnderlay = {
    name = "FullMapSafeTerrainUnderlay",
    center = Vector3.new(-450, -10, -250),
    size = Vector3.new(4700, 12, 4300),
    topY = -4,
    material = Enum.Material.Ground,
}

MapLayoutService.ZoneTerrain = {
    NurseryGrove = {
        center = Vector3.new(-2000, 0, 0),
        size = Vector3.new(560, 18, 560),
        topY = 9,
        material = Enum.Material.Grass,
    },
    FernPlains = {
        center = Vector3.new(-1150, 0, 0),
        size = Vector3.new(680, 18, 560),
        topY = 9,
        material = Enum.Material.Grass,
    },
    JungleBasin = {
        center = Vector3.new(-1450, 0, 950),
        size = Vector3.new(680, 18, 560),
        topY = 9,
        material = Enum.Material.LeafyGrass,
    },
    RedstoneCanyon = {
        center = Vector3.new(-200, 0, -650),
        size = Vector3.new(760, 18, 520),
        topY = 9,
        material = Enum.Material.Sandstone,
    },
    SwampDelta = {
        center = Vector3.new(-150, 0, 950),
        size = Vector3.new(760, 14, 540),
        topY = 7,
        material = Enum.Material.Mud,
    },
    ApocalypticCity = {
        center = Vector3.new(1050, 0, 0),
        size = Vector3.new(860, 18, 700),
        topY = 9,
        material = Enum.Material.Asphalt,
    },
    MountainNestingCliffs = {
        center = Vector3.new(-100, 58, -1700),
        size = Vector3.new(760, 34, 620),
        topY = 75,
        material = Enum.Material.Rock,
    },
}

MapLayoutService.FullMapTerrainUnderlay = {
    name = "FullMapTerrainUnderlay",
    center = Vector3.new(-450, -10, -250),
    size = Vector3.new(4700, 12, 4400),
    material = Enum.Material.Ground,
}

MapLayoutService.RouteTerrain = {
    { name = "NurseryToFernBabySafe", center = Vector3.new(-1575, 0, 0), size = Vector3.new(900, 18, 180), material = Enum.Material.Grass, babySafe = true },
    { name = "NurseryToJungleBabySafe", center = Vector3.new(-1765, 0, 475), size = Vector3.new(220, 18, 960), material = Enum.Material.LeafyGrass, babySafe = true },
    { name = "FernToJungle", center = Vector3.new(-1300, 0, 475), size = Vector3.new(260, 18, 960), material = Enum.Material.Grass },
    { name = "FernToRedstoneCanyon", center = Vector3.new(-675, 0, -325), size = Vector3.new(950, 18, 220), material = Enum.Material.Sandstone },
    { name = "JungleToSwampDelta", center = Vector3.new(-800, 0, 950), size = Vector3.new(1320, 14, 220), material = Enum.Material.LeafyGrass },
    { name = "RedstoneCanyonGateToCity", center = Vector3.new(430, 0, -325), size = Vector3.new(1320, 18, 220), material = Enum.Material.Sandstone, cityRoute = true },
    { name = "SwampDeltaCausewayToCity", center = Vector3.new(450, 0, 475), size = Vector3.new(1360, 14, 240), material = Enum.Material.Mud, cityRoute = true },
    { name = "CityCrossRoute", center = Vector3.new(1050, 0, 0), size = Vector3.new(900, 18, 190), material = Enum.Material.Asphalt, cityRoute = true },
    { name = "MountainNestApproach", center = Vector3.new(-140, 6, -1040), size = Vector3.new(360, 18, 300), material = Enum.Material.Rock },
    { name = "MountainNestLowerRamp", center = Vector3.new(-140, 17, -1190), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestMidRamp", center = Vector3.new(-140, 33, -1340), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestUpperRamp", center = Vector3.new(-140, 51, -1500), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestSaddle", center = Vector3.new(-140, 63, -1620), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
}

MapLayoutService.FoodPlacements = {
    { name = "NurseryStarterFern_01", zone = "NurseryGrove", diet = "Herbivore", nutrition = 30, position = Vector3.new(-2025, 12, -42), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_02", zone = "NurseryGrove", diet = "Herbivore", nutrition = 30, position = Vector3.new(-1970, 12, 38), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "FernPlainsGrazingPatch_01", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1220, 12, -160), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "FernPlainsGrazingPatch_02", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1100, 12, 165), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "JungleBasinBroadleaf_01", zone = "JungleBasin", diet = "Herbivore", nutrition = 20, position = Vector3.new(-1540, 12, 1035), size = Vector3.new(9, 3, 9), kind = "PlantPatch", cooldown = 75 },
    { name = "RedstoneSparseScrub_01", zone = "RedstoneCanyon", diet = "Herbivore", nutrition = 14, position = Vector3.new(-355, 13, -770), size = Vector3.new(8, 3, 8), kind = "SparsePlant", cooldown = 90 },
    { name = "SwampDeltaMarshPlant_01", zone = "SwampDelta", diet = "Herbivore", nutrition = 18, position = Vector3.new(-260, 10, 1080), size = Vector3.new(9, 3, 9), kind = "MarshPlant", cooldown = 80 },
    { name = "CarnivoreTutorialCarcass_01", zone = "FernPlains", diet = "Carnivore", nutrition = 34, position = Vector3.new(-930, 12, -120), size = Vector3.new(8, 3, 5), kind = "TutorialCarcass", cooldown = 120 },
    { name = "RedstonePreyCarcass_01", zone = "RedstoneCanyon", diet = "Carnivore", nutrition = 42, position = Vector3.new(-125, 13, -760), size = Vector3.new(9, 3, 5), kind = "PreyCarcass", cooldown = 150 },
    { name = "SwampPreyCarcass_01", zone = "SwampDelta", diet = "Carnivore", nutrition = 38, position = Vector3.new(55, 10, 1065), size = Vector3.new(9, 3, 5), kind = "PreyCarcass", cooldown = 150 },
    { name = "OldEdenHighRiskCarcass_01", zone = "ApocalypticCity", diet = "Carnivore", nutrition = 55, position = Vector3.new(1110, 12, -210), size = Vector3.new(10, 3, 6), kind = "HighRiskCarcass", cooldown = 180 },
    { name = "OldEdenOvergrowthReward_01", zone = "ApocalypticCity", diet = "Herbivore", nutrition = 28, position = Vector3.new(1285, 12, 245), size = Vector3.new(9, 3, 9), kind = "HighRiskPlant", cooldown = 120 },
}

MapLayoutService.ShallowWater = {
    { name = "FernPlainsPond", center = Vector3.new(-1080, 10, 205), size = Vector3.new(190, 5, 120) },
    { name = "SwampDeltaChannel", center = Vector3.new(-80, 8, 950), size = Vector3.new(760, 4, 115) },
    { name = "CityCanalShallow", center = Vector3.new(820, 10, 300), size = Vector3.new(430, 4, 90) },
}

MapLayoutService.FoodSourcePlacements = {
    { name = "NurseryStarterFernPatch_A", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1985, 13, -34), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(70, 150, 67) },
    { name = "NurseryStarterFernPatch_B", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1918, 13, 58), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(82, 160, 74) },
    { name = "FernPlainsGrazingPatch_A", zone = "FernPlains", diet = "Herbivore", nutrition = 40, respawnSeconds = 60, position = Vector3.new(-1515, 12, -155), size = Vector3.new(12, 2, 10), color = Color3.fromRGB(78, 170, 72) },
    { name = "FernPlainsGrazingPatch_B", zone = "FernPlains", diet = "Herbivore", nutrition = 40, respawnSeconds = 60, position = Vector3.new(-1260, 12, 210), size = Vector3.new(14, 2, 10), color = Color3.fromRGB(68, 145, 60) },
    { name = "JungleBasinLeafCluster", zone = "JungleBasin", diet = "Herbivore", nutrition = 30, respawnSeconds = 80, position = Vector3.new(-640, 13, -430), size = Vector3.new(10, 2, 10), color = Color3.fromRGB(44, 132, 65) },
    { name = "NurseryTutorialMeatCache", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1870, 13, -92), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(126, 62, 48), tutorialSafe = true },
    { name = "FernPlainsPreyCarcass_A", zone = "FernPlains", diet = "Carnivore", nutrition = 45, respawnSeconds = 120, position = Vector3.new(-1080, 12, -255), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(116, 58, 46) },
    { name = "RedstonePreyCarcass_A", zone = "RedstoneCanyon", diet = "Carnivore", nutrition = 55, respawnSeconds = 150, position = Vector3.new(260, 18, -940), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(120, 64, 52) },
    { name = "OldEdenRiskCarcass", zone = "ApocalypticCity", diet = "Carnivore", nutrition = 65, respawnSeconds = 180, position = Vector3.new(1035, 14, 92), size = Vector3.new(9, 1.5, 5), color = Color3.fromRGB(112, 56, 46), highRisk = true },
}

function MapLayoutService:GetOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

function MapLayoutService:EnsureMapFolders()
    local map = self:GetOrCreateFolder(Workspace, self.MapFolderName)
    local zonesFolder = self:GetOrCreateFolder(map, "Zones")
    local invisible = self:GetOrCreateFolder(map, self.InvisibleFolderName)
    local landmarks = self:GetOrCreateFolder(map, "Landmarks")
    local foodSources = self:GetOrCreateFolder(map, "FoodSources")
    local waterSources = self:GetOrCreateFolder(map, "WaterSources")
    local npcSpawns = self:GetOrCreateFolder(map, "NPCSpawns")
    local nests = self:GetOrCreateFolder(map, "Nests")
    local fossils = self:GetOrCreateFolder(map, "Fossils")
    local routes = self:GetOrCreateFolder(map, "Routes")

    for zoneId in pairs(ZoneConfig) do
        self:GetOrCreateFolder(zonesFolder, zoneId)
    end
    for _, landmarkName in ipairs(MapLayout.Landmarks) do
        self:GetOrCreateFolder(landmarks, landmarkName)
    end
    return {
        Map = map,
        Zones = zonesFolder,
        InvisibleGameplayVolumes = invisible,
        Landmarks = landmarks,
        FoodSources = foodSources,
        WaterSources = waterSources,
        NPCSpawns = npcSpawns,
        Nests = nests,
        Fossils = fossils,
        Routes = routes,
    }
end

function MapLayoutService:FillTerrainBlock(terrain, center, size, material)
    terrain:FillBlock(CFrame.new(center), size, material)
end

function MapLayoutService:EnsureRouteMarker(folders, route)
    local marker = folders.Routes:FindFirstChild(route.name)
    if not marker then
        marker = Instance.new("Folder")
        marker.Name = route.name
        marker.Parent = folders.Routes
    end
    marker:SetAttribute("TerrainBacked", true)
    marker:SetAttribute("BabySafeRoute", route.babySafe == true)
    marker:SetAttribute("CityRoute", route.cityRoute == true)
    return marker
end

function MapLayoutService:EnsureShallowWaterMarker(folders, water)
    local marker = folders.WaterSources:FindFirstChild(water.name)
    if not marker then
        marker = Instance.new("Folder")
        marker.Name = water.name
        marker.Parent = folders.WaterSources
    end
    marker:SetAttribute("ShallowWater", true)
    marker:SetAttribute("SwimmableDepthStuds", water.size.Y)
    return marker
end

function MapLayoutService:EnsureFoodSourcePlacements(folders)
    for _, placement in ipairs(self.FoodPlacements) do
        local zoneFolder = folders.FoodSources:FindFirstChild(placement.zone)
        if not zoneFolder then
            zoneFolder = Instance.new("Folder")
            zoneFolder.Name = placement.zone
            zoneFolder.Parent = folders.FoodSources
        end
        local food = zoneFolder:FindFirstChild(placement.name)
        if not food then
            food = Instance.new("Part")
            food.Name = placement.name
            food.Anchored = true
            food.CanCollide = false
            food.CanTouch = false
            food.CanQuery = true
            food.Shape = Enum.PartType.Ball
            food.Material = placement.diet == "Carnivore" and Enum.Material.Leather or Enum.Material.Grass
            food.Color = placement.diet == "Carnivore" and Color3.fromRGB(120, 55, 45) or Color3.fromRGB(64, 135, 54)
            food.Size = placement.size
            food.Position = placement.position
            food:SetAttribute("CreatorStoreOnly", true)
            food:SetAttribute("ImportedVisibleAsset", true)
            food:SetAttribute("AssetManifestId", placement.diet == "Carnivore" and "CS-739396590" or "CS-4596418748")
            food:SetAttribute("Decorative", false)
            food.Parent = zoneFolder
        end
        food:SetAttribute("ZoneId", placement.zone)
        food:SetAttribute("Diet", placement.diet)
        food:SetAttribute("Nutrition", placement.nutrition)
        food:SetAttribute("FoodKind", placement.kind)
        food:SetAttribute("Depleted", food:GetAttribute("Depleted") == true)
        food:SetAttribute("RespawnCooldownSeconds", placement.cooldown)
        food:SetAttribute("DangerousZone", placement.zone ~= "NurseryGrove" and placement.zone ~= "FernPlains")
        food:SetAttribute("StarterFood", placement.kind == "StarterPlant" or placement.kind == "TutorialCarcass")
        CollectionService:AddTag(food, "FoodSource")
    end
end

function MapLayoutService:EnsureCityDiscoveryTriggers(folders)
    folders = folders or self:EnsureMapFolders()
    local triggerFolder = self:GetOrCreateFolder(folders.InvisibleGameplayVolumes, "CityDiscoveryTriggers")
    local zone = self.ZoneTerrain.ApocalypticCity
    local triggers = {
        { name = "_INVISIBLE_CityDiscovery_RedstoneGate", position = Vector3.new(620, zone.topY + 5, -325), size = Vector3.new(90, 14, 180) },
        { name = "_INVISIBLE_CityDiscovery_SwampCauseway", position = Vector3.new(620, zone.topY + 5, 475), size = Vector3.new(90, 14, 180) },
        { name = "_INVISIBLE_CityDiscovery_CityCore", position = Vector3.new(zone.center.X, zone.topY + 5, zone.center.Z), size = Vector3.new(220, 14, 220) },
    }
    for _, spec in ipairs(triggers) do
        local trigger = triggerFolder:FindFirstChild(spec.name)
        if not trigger then
            trigger = Instance.new("Part")
            trigger.Name = spec.name
            trigger.Anchored = true
            trigger.CanCollide = false
            trigger.CanTouch = true
            trigger.CanQuery = false
            trigger.Transparency = 1
            trigger.Parent = triggerFolder
        end
        trigger.Position = spec.position
        trigger.Size = spec.size
        trigger:SetAttribute("GameplayVolume", true)
        trigger:SetAttribute("CityDiscoveryTrigger", true)
        trigger:SetAttribute("ZoneId", "ApocalypticCity")
    end
    return triggerFolder
end

function MapLayoutService:EnsureFallSafetyVolume(folders)
    local safety = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_FallSafetyCatch")
    if not safety then
        safety = Instance.new("Part")
        safety.Name = "_INVISIBLE_FallSafetyCatch"
        safety.Anchored = true
        safety.CanCollide = true
        safety.CanTouch = true
        safety.CanQuery = false
        safety.Transparency = 1
        safety.Size = Vector3.new(4600, 4, 4200)
        safety.Position = Vector3.new(-450, -16, -250)
        safety:SetAttribute("GameplayVolume", true)
        safety:SetAttribute("FallSafety", true)
        safety.Parent = folders.InvisibleGameplayVolumes
    end
    return safety
end

function MapLayoutService:EnsureTerrainContinuity(folders)
    local terrain = Workspace.Terrain

    self:FillTerrainBlock(terrain, self.FullMapTerrainUnderlay.center, self.FullMapTerrainUnderlay.size, self.FullMapTerrainUnderlay.material)
    folders.Map:SetAttribute("FullMapTerrainUnderlay", true)
    folders.Map:SetAttribute("FullMapTerrainUnderlaySize", string.format("%d,%d,%d", self.FullMapTerrainUnderlay.size.X, self.FullMapTerrainUnderlay.size.Y, self.FullMapTerrainUnderlay.size.Z))

    for zoneId, zone in pairs(self.ZoneTerrain) do
        self:FillTerrainBlock(terrain, zone.center, zone.size, zone.material)
        local zoneFolder = folders.Zones:FindFirstChild(zoneId)
        if zoneFolder then
            zoneFolder:SetAttribute("TerrainBacked", true)
            zoneFolder:SetAttribute("GroundTopY", zone.topY)
        end
    end

    for _, route in ipairs(self.RouteTerrain) do
        self:FillTerrainBlock(terrain, route.center, route.size, route.material)
        self:EnsureRouteMarker(folders, route)
    end

    for _, water in ipairs(self.ShallowWater) do
        self:FillTerrainBlock(terrain, water.center, water.size, Enum.Material.Water)
        self:EnsureShallowWaterMarker(folders, water)
    end
end


function MapLayoutService:EnsureFoodSource(folders, source)
    local CollectionService = game:GetService("CollectionService")
    local existing = folders.FoodSources:FindFirstChild(source.name)
    if not existing then
        existing = Instance.new("Part")
        existing.Name = source.name
        existing.Anchored = true
        existing.Shape = Enum.PartType.Block
        existing.Material = source.diet == "Herbivore" and Enum.Material.Grass or Enum.Material.Slate
        existing.Parent = folders.FoodSources
    end
    existing.Position = source.position
    existing.Size = source.size
    existing.Color = source.color
    existing.CanCollide = false
    existing.CanTouch = true
    existing.CanQuery = true
    existing.Transparency = 0
    existing:SetAttribute("ZoneId", source.zone)
    existing:SetAttribute("Diet", source.diet)
    existing:SetAttribute("Nutrition", source.nutrition)
    existing:SetAttribute("RespawnSeconds", source.respawnSeconds)
    existing:SetAttribute("Depleted", false)
    existing:SetAttribute("TutorialSafe", source.tutorialSafe == true)
    existing:SetAttribute("HighRisk", source.highRisk == true)
    existing:SetAttribute("CreatorStoreOnly", true)
    existing:SetAttribute("PlacementRole", source.diet == "Herbivore" and "PlantFood" or "CarnivoreCarcassFood")
    if not CollectionService:HasTag(existing, "FoodSource") then
        CollectionService:AddTag(existing, "FoodSource")
    end
    return existing
end

function MapLayoutService:EnsureFoodSources()
    local folders = self:EnsureMapFolders()
    for _, source in ipairs(self.FoodSourcePlacements) do
        self:EnsureFoodSource(folders, source)
    end
    return folders.FoodSources
end

function MapLayoutService:EnsureSpawnSafety()
    local folders = self:EnsureMapFolders()
    local spawnFolder = self:GetOrCreateFolder(folders.Map, "SpawnLocations")
    local spawn = spawnFolder:FindFirstChild("_INVISIBLE_EggSpawn_Nursery")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Name = "_INVISIBLE_EggSpawn_Nursery"
        spawn.Anchored = true
        spawn.CanCollide = true
        spawn.CanTouch = false
        spawn.CanQuery = true
        spawn.Transparency = 1
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Size = Vector3.new(18, 2, 18)
        spawn.Position = Vector3.new(-2000, 12, 0)
        spawn:SetAttribute("GameplayVolume", true)
        spawn:SetAttribute("ZoneId", "NurseryGrove")
        spawn.Parent = spawnFolder
    end

    self:EnsureTerrainContinuity(folders)
    self:EnsureFoodSourcePlacements(folders)
    self:EnsureFoodSources()
    self:EnsureCityDiscoveryTriggers(folders)
    self:EnsureFallSafetyVolume(folders)
    return spawn
end

function MapLayoutService:ValidateLayoutFolders()
    local folders = self:EnsureMapFolders()
    self:EnsureSpawnSafety()
    local missing = {}
    for zoneId in pairs(ZoneConfig) do
        if not folders.Zones:FindFirstChild(zoneId) then table.insert(missing, zoneId) end
    end
    for _, route in ipairs(self.RouteTerrain) do
        if not folders.Routes:FindFirstChild(route.name) then table.insert(missing, route.name) end
    end
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_FallSafetyCatch") then
        table.insert(missing, "_INVISIBLE_FallSafetyCatch")
    end
    local cityTriggers = folders.InvisibleGameplayVolumes:FindFirstChild("CityDiscoveryTriggers")
    if not cityTriggers or not cityTriggers:FindFirstChild("_INVISIBLE_CityDiscovery_CityCore") then
        table.insert(missing, "CityDiscoveryTriggers")
    end
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name) then
        table.insert(missing, self.FullMapUnderlay.name)
    end
    return #missing == 0, missing
end

return MapLayoutService
