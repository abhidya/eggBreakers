local Constants = {}

Constants.ScopeFreeze = {
    MaxPlayableSpeciesBeforeVerticalSlice = 6,
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
