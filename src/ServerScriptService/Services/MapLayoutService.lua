local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

MapLayoutService.ShallowWater = {
    { name = "FernPlainsPond", center = Vector3.new(-1080, 10, 205), size = Vector3.new(190, 5, 120) },
    { name = "SwampDeltaChannel", center = Vector3.new(-80, 8, 950), size = Vector3.new(760, 4, 115) },
    { name = "CityCanalShallow", center = Vector3.new(820, 10, 300), size = Vector3.new(430, 4, 90) },
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

function MapLayoutService:EnsureFullMapUnderlayMarker(folders)
    local underlay = self.FullMapUnderlay
    local marker = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. underlay.name)
    if not marker then
        marker = Instance.new("Part")
        marker.Name = "_INVISIBLE_" .. underlay.name
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanTouch = false
        marker.CanQuery = false
        marker.Transparency = 1
        marker.Size = underlay.size
        marker.Position = underlay.center
        marker.Parent = folders.InvisibleGameplayVolumes
    end
    marker:SetAttribute("GameplayVolume", true)
    marker:SetAttribute("TerrainUnderlay", true)
    marker:SetAttribute("GroundTopY", underlay.topY)
    return marker
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
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name) then
        table.insert(missing, self.FullMapUnderlay.name)
    end
    return #missing == 0, missing
end

return MapLayoutService
