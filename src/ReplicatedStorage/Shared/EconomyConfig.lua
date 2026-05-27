local EconomyConfig = {}

EconomyConfig.DNARewards = {
    FirstHatch = 25,
    CompleteTutorial = 50,
    ReachJuvenile = 40,
    ReachSubAdult = 80,
    ReachAdult = 150,
    DiscoverBiome = 25,
    DiscoverApocalypticCity = 100,
    SurviveTenMinutes = 50,
    HelpGroupMemberSurviveNearby = 25,
}

EconomyConfig.FossilRewards = {
    Common = 1,
    RareCity = 3,
    NestingCliff = 2,
    DailySurvivalBonus = 5,
}

EconomyConfig.UnlockCosts = {
    Starter = 0,
    AdditionalSmall = 250,
    Medium = 600,
    Large = 1500,
    Apex = 3000,
}

EconomyConfig.Cosmetics = {
    CommonSkinDNA = 100,
    RareSkinFossils = 20,
    CityRuinSkinFossils = 50,
    NestDecorationFossilsMin = 10,
    NestDecorationFossilsMax = 40,
    CallVariantDNAMin = 250,
    CallVariantDNAMax = 750,
}

return EconomyConfig
