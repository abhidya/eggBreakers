local Constants = {}

Constants.ScopeFreeze = {
    -- Full staged roster is now playable (all 56 species under Workspace.dinosaur:
    -- 16 Herbivore + 28 Carnivore + 4 Omnivore + 8 Aquatic). The previous
    -- vertical-slice cap (6) is retained as a curated minimum, not an upper bound.
    MaxPlayableSpeciesBeforeVerticalSlice = 6,
    -- Upper bound for the full playable roster. The staged roster plus reviewed
    -- Creator Store dinosaur pack meshes now pushes the random hatch pool past
    -- 50 species while keeping retired primitive prototype ids out.
    MaxPlayableSpecies = 96,
    RequiredPlayableSpecies = 4,
    GrowthStages = { "Hatchling", "Juvenile", "SubAdult", "Adult" },
    RequiredZones = {
        "NurseryGrove",
        "FernPlains",
        "JungleBasin",
        "RedstoneCanyon",
        "SwampDelta",
        "ApocalypticCity",
    },
    ForbiddenUntilVerticalSliceComplete = {
        Flyers = true,
        Aquatics = true,
        Humans = true,
        Guns = true,
        ComplexGenetics = true,
        ProceduralMutations = true,
        WeatherDisasters = true,
        HugeOpenOcean = true,
        FullQuestlineCampaign = true,
        Trading = true,
        PlayerMadeMaps = true,
        ComplexCrafting = true,
        RealisticGore = true,
        PayToWinBoosts = true,
    },
}

Constants.DefaultSpeciesId = "coelophysis"
Constants.RandomStarterSpeciesId = "__random_full_roster"

Constants.RetiredPrototypeSpecies = {
    gallimimus = true,
    triceratops = true,
    velociraptor = true,
    carnotaurus = true,
}

Constants.Tags = {
    FoodSource = "FoodSource",
    WaterSource = "WaterSource",
    Damageable = "Damageable",
    Fossil = "Fossil",
    SafeZone = "SafeZone",
    NestZone = "NestZone",
}

Constants.SafeZoneId = "NurseryGrove"

return Constants
