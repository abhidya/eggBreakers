local Constants = {}

Constants.ScopeFreeze = {
    -- Full staged roster is now playable (all 56 species under Workspace.dinosaur:
    -- 16 Herbivore + 28 Carnivore + 4 Omnivore + 8 Aquatic). The previous
    -- vertical-slice cap (6) is retained as a curated minimum, not an upper bound.
    MaxPlayableSpeciesBeforeVerticalSlice = 6,
    -- Upper bound for the full playable roster. Workspace.dinosaur holds 56 rigs
    -- that de-duplicate to 48 distinct staged species; merged with the curated 8
    -- (of which 4 ids -- gallimimus, velociraptor, oviraptor, pteranodon -- have no
    -- staged-name twin) => 52 playable today. Headroom kept for future species.
    MaxPlayableSpecies = 64,
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
