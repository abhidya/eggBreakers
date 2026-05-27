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
    { name = "NurseryTutorialMeatCache", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1870, 13, -92), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
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
    { name = "NurseryStarterFern_03", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2045, 12, 30), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_04", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1934, 12, -52), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_05", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2008, 12, 86), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_06", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2078, 12, -12), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_07", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2014, 12, -96), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_08", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1962, 12, 112), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_09", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1888, 12, 18), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryTutorialMeatCache_02", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1908, 13, -54), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_03", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1844, 13, -128), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_04", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1818, 13, 22), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_05", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1948, 13, -132), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "FernPlainsGrazingPatch_03", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1160, 12, 40), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "FernPlainsPreyCarcass_02", zone = "FernPlains", diet = "Carnivore", nutrition = 36, position = Vector3.new(-1002, 12, -210), size = Vector3.new(8, 3, 5), kind = "PreyCarcass", cooldown = 120 },
}

MapLayoutService.ShallowWater = {
    { name = "NurseryTutorialWater", center = Vector3.new(-1960, 10, -18), size = Vector3.new(64, 3, 42), tutorialSafe = true },
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
    { name = "NurseryStarterFernPatch_C", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2058, 13, 70), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(74, 156, 68) },
    { name = "NurseryStarterFernPatch_D", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1935, 13, -86), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(88, 164, 76) },
    { name = "NurseryStarterFernPatch_E", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2092, 13, -38), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(84, 166, 78) },
    { name = "NurseryStarterFernPatch_F", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2030, 13, -118), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(74, 152, 72) },
    { name = "NurseryStarterFernPatch_G", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1978, 13, 128), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(92, 170, 84) },
    { name = "NurseryStarterFernPatch_H", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1888, 13, 82), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(78, 158, 72) },
    { name = "NurseryTutorialMeatCache_B", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1835, 13, -48), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(132, 64, 50), tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_C", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1816, 13, 44), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(134, 66, 50), tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_D", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1962, 13, -142), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(128, 62, 48), tutorialSafe = true },
    { name = "FernPlainsPreyCarcass_B", zone = "FernPlains", diet = "Carnivore", nutrition = 45, respawnSeconds = 120, position = Vector3.new(-1015, 12, -185), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(116, 58, 46) },
    { name = "SwampPreyCarcass_B", zone = "SwampDelta", diet = "Carnivore", nutrition = 42, respawnSeconds = 150, position = Vector3.new(-35, 10, 1015), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(110, 58, 50) },
}


MapLayoutService.BiomeDressingPlacements = {
    {
        name = "NurserySafeTree_A",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2225, 9, -225),
        trunkSize = Vector3.new(7, 26, 7),
        canopySize = Vector3.new(34, 24, 34),
        trunkColor = Color3.fromRGB(112, 75, 45),
        canopyColor = Color3.fromRGB(72, 142, 65),
    },
    {
        name = "NurseryTutorialTree_A",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2180, 9, -60),
        trunkSize = Vector3.new(6, 22, 6),
        canopySize = Vector3.new(28, 20, 28),
        trunkColor = Color3.fromRGB(118, 78, 48),
        canopyColor = Color3.fromRGB(76, 150, 70),
    },
    {
        name = "FernPlainsTree_A",
        zone = "FernPlains",
        kind = "Tree",
        position = Vector3.new(-1390, 9, -245),
        trunkSize = Vector3.new(8, 30, 8),
        canopySize = Vector3.new(42, 26, 42),
        trunkColor = Color3.fromRGB(104, 70, 42),
        canopyColor = Color3.fromRGB(58, 130, 54),
    },
    {
        name = "JungleCanopyTree_A",
        zone = "JungleBasin",
        kind = "Tree",
        position = Vector3.new(-1188, 9, 1188),
        trunkSize = Vector3.new(10, 38, 10),
        canopySize = Vector3.new(54, 34, 54),
        trunkColor = Color3.fromRGB(93, 65, 40),
        canopyColor = Color3.fromRGB(38, 112, 56),
    },
    {
        name = "SwampCypressTree_A",
        zone = "SwampDelta",
        kind = "Tree",
        position = Vector3.new(-486, 7, 1169),
        trunkSize = Vector3.new(9, 34, 9),
        canopySize = Vector3.new(38, 28, 38),
        trunkColor = Color3.fromRGB(88, 66, 48),
        canopyColor = Color3.fromRGB(46, 103, 65),
    },
    {
        name = "NurserySafeTree_B",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2128, 9, -188),
        trunkSize = Vector3.new(6, 24, 6),
        canopySize = Vector3.new(32, 22, 32),
        trunkColor = Color3.fromRGB(112, 72, 44),
        canopyColor = Color3.fromRGB(66, 136, 62),
    },
    {
        name = "NurseryFoodShadeTree_C",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-1955, 9, -38),
        trunkSize = Vector3.new(6, 23, 6),
        canopySize = Vector3.new(30, 22, 30),
        trunkColor = Color3.fromRGB(116, 76, 45),
        canopyColor = Color3.fromRGB(70, 146, 66),
    },
    {
        name = "FernPlainsTree_B",
        zone = "FernPlains",
        kind = "Tree",
        position = Vector3.new(-1285, 9, 70),
        trunkSize = Vector3.new(7, 29, 7),
        canopySize = Vector3.new(40, 25, 40),
        trunkColor = Color3.fromRGB(102, 68, 42),
        canopyColor = Color3.fromRGB(62, 134, 58),
    },
    {
        name = "JungleCanopyTree_B",
        zone = "JungleBasin",
        kind = "Tree",
        position = Vector3.new(-1375, 9, 1060),
        trunkSize = Vector3.new(10, 36, 10),
        canopySize = Vector3.new(52, 34, 52),
        trunkColor = Color3.fromRGB(90, 62, 39),
        canopyColor = Color3.fromRGB(42, 118, 58),
    },
    {
        name = "SwampCypressTree_B",
        zone = "SwampDelta",
        kind = "Tree",
        position = Vector3.new(-170, 7, 1095),
        trunkSize = Vector3.new(8, 32, 8),
        canopySize = Vector3.new(36, 26, 36),
        trunkColor = Color3.fromRGB(84, 64, 46),
        canopyColor = Color3.fromRGB(48, 110, 68),
    },
    {
        name = "RedstoneCanyonBoulder_A",
        zone = "RedstoneCanyon",
        kind = "Boulder",
        position = Vector3.new(132, 17, -835),
        size = Vector3.new(30, 18, 24),
        color = Color3.fromRGB(156, 83, 54),
        material = Enum.Material.Sandstone,
    },
    {
        name = "MountainNestRock_A",
        zone = "MountainNestingCliffs",
        kind = "Rock",
        position = Vector3.new(238, 82, -1947),
        size = Vector3.new(32, 20, 28),
        color = Color3.fromRGB(106, 102, 96),
        material = Enum.Material.Rock,
    },
    {
        name = "OldEdenRubblePile_A",
        zone = "ApocalypticCity",
        kind = "Rubble",
        position = Vector3.new(1438, 13, -284),
        size = Vector3.new(34, 10, 24),
        color = Color3.fromRGB(94, 89, 83),
        material = Enum.Material.Concrete,
    },
}

MapLayoutService.NPCSpawnPlacements = {
    { name = "NurseryPrey_01", position = Vector3.new(-1905, 14, 95), kind = "Prey", zone = "NurseryGrove", tutorialSafe = true },
    { name = "NurseryPrey_02", position = Vector3.new(-2075, 14, -115), kind = "Prey", zone = "NurseryGrove", tutorialSafe = true },
    { name = "FernPrey_01", position = Vector3.new(-1250, 14, 120), kind = "Prey", zone = "FernPlains" },
    { name = "FernPrey_02", position = Vector3.new(-1120, 14, -165), kind = "Prey", zone = "FernPlains" },
    { name = "JunglePrey_01", position = Vector3.new(-1460, 14, 1010), kind = "Prey", zone = "JungleBasin" },
    { name = "SwampPrey_01", position = Vector3.new(-230, 11, 1040), kind = "Prey", zone = "SwampDelta" },
    { name = "RedstonePredator_01", position = Vector3.new(-280, 16, -720), kind = "Predator", zone = "RedstoneCanyon", dangerous = true },
    { name = "CityPredator_01", position = Vector3.new(980, 14, -160), kind = "Predator", zone = "ApocalypticCity", dangerous = true },
    { name = "MountainPrey_01", position = Vector3.new(-90, 79, -1660), kind = "Prey", zone = "MountainNestingCliffs" },
    { name = "FernPredator_01", position = Vector3.new(-980, 14, -260), kind = "Predator", zone = "FernPlains", dangerous = true },
    { name = "JunglePredator_01", position = Vector3.new(-1340, 14, 1110), kind = "Predator", zone = "JungleBasin", dangerous = true },
    { name = "SwampPredator_01", position = Vector3.new(65, 11, 1010), kind = "Predator", zone = "SwampDelta", dangerous = true },
}


MapLayoutService.CompactLayout = {
    origin = Vector3.new(-2000, 0, 0),
    scaleXZ = 0.45,
    minimumTerrainXZ = 240,
    minimumRouteXZ = 96,
    minimumWaterXZ = 42,
}

function MapLayoutService:CompactPosition(vector)
    local layout = self.CompactLayout
    return Vector3.new(
        layout.origin.X + (vector.X - layout.origin.X) * layout.scaleXZ,
        vector.Y,
        layout.origin.Z + (vector.Z - layout.origin.Z) * layout.scaleXZ
    )
end

function MapLayoutService:CompactSize(size, minimumXZ)
    local scale = self.CompactLayout.scaleXZ
    return Vector3.new(
        math.max(minimumXZ or 0, size.X * scale),
        size.Y,
        math.max(minimumXZ or 0, size.Z * scale)
    )
end

function MapLayoutService:ApplyCompactLayout()
    if self._compactLayoutApplied then return end
    self._compactLayoutApplied = true

    self.FullMapUnderlay.center = self:CompactPosition(self.FullMapUnderlay.center)
    self.FullMapUnderlay.size = self:CompactSize(self.FullMapUnderlay.size, 1800)
    self.FullMapTerrainUnderlay.center = self:CompactPosition(self.FullMapTerrainUnderlay.center)
    self.FullMapTerrainUnderlay.size = self:CompactSize(self.FullMapTerrainUnderlay.size, 1800)

    for _, zone in pairs(self.ZoneTerrain) do
        zone.center = self:CompactPosition(zone.center)
        zone.size = self:CompactSize(zone.size, self.CompactLayout.minimumTerrainXZ)
    end

    for _, route in ipairs(self.RouteTerrain) do
        route.center = self:CompactPosition(route.center)
        route.size = self:CompactSize(route.size, self.CompactLayout.minimumRouteXZ)
    end

    for _, water in ipairs(self.ShallowWater) do
        water.center = self:CompactPosition(water.center)
        water.size = self:CompactSize(water.size, self.CompactLayout.minimumWaterXZ)
    end

    for _, placement in ipairs(self.FoodPlacements) do
        placement.position = self:CompactPosition(placement.position)
    end

    for _, source in ipairs(self.FoodSourcePlacements) do
        source.position = self:CompactPosition(source.position)
    end

    for _, spec in ipairs(self.BiomeDressingPlacements) do
        spec.position = self:CompactPosition(spec.position)
    end

    for _, spec in ipairs(self.NPCSpawnPlacements) do
        spec.position = self:CompactPosition(spec.position)
    end
end

MapLayoutService:ApplyCompactLayout()

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
    local biomeDressing = self:GetOrCreateFolder(map, "BiomeDressing")

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
        BiomeDressing = biomeDressing,
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
    if marker and not marker:IsA("BasePart") then
        marker:Destroy()
        marker = nil
    end
    if not marker then
        marker = Instance.new("Part")
        marker.Name = water.name
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanTouch = true
        marker.CanQuery = true
        marker.Material = Enum.Material.Glass
        marker.Color = Color3.fromRGB(58, 137, 184)
        marker.Transparency = 0.35
        marker.Parent = folders.WaterSources
    end
    marker.Position = water.center
    marker.Size = water.size
    marker:SetAttribute("ShallowWater", true)
    marker:SetAttribute("WaterSource", true)
    marker:SetAttribute("ProceduralWaterSource", true)
    marker:SetAttribute("TutorialSafe", water.tutorialSafe == true)
    marker:SetAttribute("SwimmableDepthStuds", water.size.Y)
    marker:SetAttribute("InteractionHint", "Drink water")
    marker:SetAttribute("VisibleGameplayAffordance", true)
    marker:SetAttribute("GameplayQuery", true)
    if not CollectionService:HasTag(marker, "WaterSource") then
        CollectionService:AddTag(marker, "WaterSource")
    end
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
            food:SetAttribute("CreatorStoreOnly", nil)
            food:SetAttribute("ImportedVisibleAsset", nil)
            food:SetAttribute("AssetManifestId", nil)
            food:SetAttribute("ProceduralGameplayVisual", true)
            food:SetAttribute("Decorative", false)
            food.Parent = zoneFolder
        end
        food:SetAttribute("ZoneId", placement.zone)
        food:SetAttribute("Diet", placement.diet)
        food:SetAttribute("Nutrition", placement.nutrition)
        food:SetAttribute("FoodKind", placement.kind)
        food:SetAttribute("CreatorStoreOnly", nil)
        food:SetAttribute("ImportedVisibleAsset", nil)
        food:SetAttribute("AssetManifestId", nil)
        food:SetAttribute("ProceduralGameplayVisual", true)
        food:SetAttribute("Depleted", food:GetAttribute("Depleted") == true)
        food:SetAttribute("RespawnCooldownSeconds", placement.cooldown)
        food:SetAttribute("DangerousZone", placement.zone ~= "NurseryGrove" and placement.zone ~= "FernPlains")
        local isTutorialFood = placement.tutorialSafe == true or placement.kind == "StarterPlant" or placement.kind == "TutorialCarcass"
        food:SetAttribute("StarterFood", isTutorialFood)
        food:SetAttribute("TutorialSafe", isTutorialFood)
        food:SetAttribute("InteractionHint", placement.diet == "Carnivore" and "Eat carcass" or "Eat plant")
        food:SetAttribute("VisibleGameplayAffordance", true)
        food:SetAttribute("GameplayQuery", true)
        CollectionService:AddTag(food, "FoodSource")
    end
end

function MapLayoutService:EnsureCityDiscoveryTriggers(folders)
    folders = folders or self:EnsureMapFolders()
    local triggerFolder = self:GetOrCreateFolder(folders.InvisibleGameplayVolumes, "CityDiscoveryTriggers")
    local zone = self.ZoneTerrain.ApocalypticCity
    local triggers = {
        { name = "_INVISIBLE_CityDiscovery_RedstoneGate", position = self:CompactPosition(Vector3.new(620, zone.topY + 5, -325)), size = Vector3.new(90, 14, 180) },
        { name = "_INVISIBLE_CityDiscovery_SwampCauseway", position = self:CompactPosition(Vector3.new(620, zone.topY + 5, 475)), size = Vector3.new(90, 14, 180) },
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
        safety.Parent = folders.InvisibleGameplayVolumes
    end
    safety.Size = Vector3.new(self.FullMapUnderlay.size.X, 4, self.FullMapUnderlay.size.Z)
    safety.Position = Vector3.new(self.FullMapUnderlay.center.X, -16, self.FullMapUnderlay.center.Z)
    safety:SetAttribute("GameplayVolume", true)
    safety:SetAttribute("FallSafety", true)
    return safety
end

function MapLayoutService:EnsureTerrainContinuity(folders)
    local terrain = Workspace.Terrain

    self:FillTerrainBlock(terrain, self.FullMapTerrainUnderlay.center, self.FullMapTerrainUnderlay.size, self.FullMapTerrainUnderlay.material)
    folders.Map:SetAttribute("FullMapTerrainUnderlay", true)
    folders.Map:SetAttribute("FullMapTerrainUnderlaySize", string.format("%d,%d,%d", self.FullMapTerrainUnderlay.size.X, self.FullMapTerrainUnderlay.size.Y, self.FullMapTerrainUnderlay.size.Z))
    local underlay = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name)
    if not underlay then
        underlay = Instance.new("Part")
        underlay.Name = "_INVISIBLE_" .. self.FullMapUnderlay.name
        underlay.Anchored = true
        underlay.CanCollide = true
        underlay.CanTouch = false
        underlay.CanQuery = false
        underlay.Transparency = 1
        underlay.Parent = folders.InvisibleGameplayVolumes
    end
    underlay.Position = self.FullMapUnderlay.center
    underlay.Size = self.FullMapUnderlay.size
    underlay.Material = self.FullMapUnderlay.material
    underlay:SetAttribute("GameplayVolume", true)
    underlay:SetAttribute("TerrainUnderlay", true)
    underlay:SetAttribute("GroundTopY", self.FullMapUnderlay.topY)

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
    local zoneFolder = folders.FoodSources:FindFirstChild(source.zone)
    if not zoneFolder then
        zoneFolder = Instance.new("Folder")
        zoneFolder.Name = source.zone
        zoneFolder.Parent = folders.FoodSources
    end
    local existing = zoneFolder:FindFirstChild(source.name) or folders.FoodSources:FindFirstChild(source.name)
    if not existing then
        existing = Instance.new("Part")
        existing.Name = source.name
        existing.Anchored = true
        existing.Shape = Enum.PartType.Block
        existing.Material = source.diet == "Herbivore" and Enum.Material.Grass or Enum.Material.Slate
    end
    existing.Parent = zoneFolder
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
    existing:SetAttribute("RespawnCooldownSeconds", source.respawnSeconds)
    existing:SetAttribute("Depleted", false)
    existing:SetAttribute("TutorialSafe", source.tutorialSafe == true)
    existing:SetAttribute("HighRisk", source.highRisk == true)
    existing:SetAttribute("InteractionHint", source.diet == "Carnivore" and "Eat carcass" or "Eat plant")
    existing:SetAttribute("VisibleGameplayAffordance", true)
    existing:SetAttribute("GameplayQuery", true)
    existing:SetAttribute("CreatorStoreOnly", nil)
    existing:SetAttribute("ImportedVisibleAsset", nil)
    existing:SetAttribute("AssetManifestId", nil)
    existing:SetAttribute("ProceduralGameplayVisual", true)
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


function MapLayoutService:ApplyDressingAttributes(part, spec, role)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 0
    part:SetAttribute("ZoneId", spec.zone)
    part:SetAttribute("BiomeDressing", true)
    part:SetAttribute("Decorative", true)
    part:SetAttribute("CreatorStoreOnly", nil)
    part:SetAttribute("ImportedVisibleAsset", nil)
    part:SetAttribute("AssetManifestId", nil)
    part:SetAttribute("ProceduralGameplayVisual", true)
    part:SetAttribute("PlacementRole", role)
    part:SetAttribute("DressingKind", spec.kind)
    part:SetAttribute("AvoidRouteCenters", true)
    part:SetAttribute("GroundTopY", self.ZoneTerrain[spec.zone] and self.ZoneTerrain[spec.zone].topY or nil)
    part:SetAttribute("FloatingAllowed", role == "VisibleTreeCanopy")
    if not CollectionService:HasTag(part, "BiomeDressing") then
        CollectionService:AddTag(part, "BiomeDressing")
    end
    if spec.kind == "Tree" and not CollectionService:HasTag(part, "TreeProp") then
        CollectionService:AddTag(part, "TreeProp")
    end
end

function MapLayoutService:EnsureBiomeDressing(folders)
    folders = folders or self:EnsureMapFolders()
    for _, spec in ipairs(self.BiomeDressingPlacements) do
        local zoneFolder = folders.BiomeDressing:FindFirstChild(spec.zone)
        if not zoneFolder then
            zoneFolder = Instance.new("Folder")
            zoneFolder.Name = spec.zone
            zoneFolder.Parent = folders.BiomeDressing
        end

        if spec.kind == "Tree" then
            local trunk = zoneFolder:FindFirstChild(spec.name .. "_Trunk")
            if not trunk then
                trunk = Instance.new("Part")
                trunk.Name = spec.name .. "_Trunk"
                trunk.Material = Enum.Material.Wood
                trunk.Parent = zoneFolder
            end
            trunk.Size = spec.trunkSize
            trunk.Position = spec.position + Vector3.new(0, spec.trunkSize.Y / 2, 0)
            trunk.Color = spec.trunkColor
            self:ApplyDressingAttributes(trunk, spec, "VisibleTreeTrunk")

            local canopy = zoneFolder:FindFirstChild(spec.name .. "_Canopy")
            if not canopy then
                canopy = Instance.new("Part")
                canopy.Name = spec.name .. "_Canopy"
                canopy.Shape = Enum.PartType.Ball
                canopy.Material = Enum.Material.Grass
                canopy.Parent = zoneFolder
            end
            canopy.Size = spec.canopySize
            canopy.Position = spec.position + Vector3.new(0, spec.trunkSize.Y + spec.canopySize.Y * 0.32, 0)
            canopy.Color = spec.canopyColor
            self:ApplyDressingAttributes(canopy, spec, "VisibleTreeCanopy")
        else
            local prop = zoneFolder:FindFirstChild(spec.name)
            if not prop then
                prop = Instance.new("Part")
                prop.Name = spec.name
                prop.Shape = Enum.PartType.Block
                prop.Parent = zoneFolder
            end
            prop.Size = spec.size
            prop.Position = spec.position
            prop.Color = spec.color
            prop.Material = spec.material
            self:ApplyDressingAttributes(prop, spec, "VisibleBiomeProp")
        end
    end
    return folders.BiomeDressing
end

function MapLayoutService:EnsureNPCSpawnMarkers(folders)
    for _, spec in ipairs(self.NPCSpawnPlacements) do
        local marker = folders.NPCSpawns:FindFirstChild(spec.name)
        if not marker then
            marker = Instance.new("Part")
            marker.Name = spec.name
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.Transparency = 1
            marker.Size = Vector3.new(8, 2, 8)
            marker.Parent = folders.NPCSpawns
        end
        marker.Position = spec.position
        marker:SetAttribute("NPCSpawn", true)
        marker:SetAttribute("NPCKind", spec.kind)
        marker:SetAttribute("ZoneId", spec.zone)
        marker:SetAttribute("SafeBabyArea", spec.tutorialSafe == true)
        marker:SetAttribute("DangerousNPC", spec.dangerous == true)
    end
    return folders.NPCSpawns
end

function MapLayoutService:EnsureTutorialCombatTarget(folders)
    local target = folders.Map:FindFirstChild("TutorialPracticeTarget")
    if not target then
        target = Instance.new("Part")
        target.Name = "TutorialPracticeTarget"
        target.Anchored = true
        target.Shape = Enum.PartType.Ball
        target.Material = Enum.Material.Neon
        target.Color = Color3.fromRGB(235, 82, 64)
        target.Parent = folders.Map
    end
    target.Position = self:CompactPosition(Vector3.new(-1976, 14, 10))
    target.Size = Vector3.new(6, 6, 6)
    target.CanCollide = false
    target.CanTouch = true
    target.CanQuery = true
    target.Transparency = 0.08
    target:SetAttribute("Health", math.max(1, target:GetAttribute("Health") or 40))
    target:SetAttribute("MaxHealth", 40)
    target:SetAttribute("TutorialSafe", true)
    target:SetAttribute("ZoneId", "NurseryGrove")
    target:SetAttribute("InteractionHint", "Attack practice target")
    if not CollectionService:HasTag(target, "Damageable") then
        CollectionService:AddTag(target, "Damageable")
    end
    return target
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
        spawn.Parent = spawnFolder
    end
    spawn.Position = self:CompactPosition(Vector3.new(-2000, 12, 0))
    spawn:SetAttribute("GameplayVolume", true)
    spawn:SetAttribute("ZoneId", "NurseryGrove")

    self:EnsureTerrainContinuity(folders)
    self:EnsureFoodSourcePlacements(folders)
    self:EnsureFoodSources()
    self:EnsureBiomeDressing(folders)
    self:EnsureNPCSpawnMarkers(folders)
    self:EnsureTutorialCombatTarget(folders)
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
    if not folders.BiomeDressing or #folders.BiomeDressing:GetChildren() == 0 then
        table.insert(missing, "BiomeDressing")
    end
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name) then
        table.insert(missing, self.FullMapUnderlay.name)
    end
    return #missing == 0, missing
end

return MapLayoutService
