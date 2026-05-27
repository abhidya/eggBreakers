local ZoneConfig = {
    NurseryGrove = { DisplayName = "Nursery Grove", Safe = true, FoodDensity = "High", Fossils = "None", Connections = { "FernPlains", "JungleBasin" } },
    FernPlains = { DisplayName = "Fern Plains", Safe = false, FoodDensity = "MediumHigh", Fossils = "Low", Connections = { "NurseryGrove", "RedstoneCanyon", "JungleBasin" } },
    JungleBasin = { DisplayName = "Jungle Basin", Safe = false, FoodDensity = "Medium", Fossils = "Medium", Connections = { "NurseryGrove", "SwampDelta", "FernPlains" } },
    RedstoneCanyon = { DisplayName = "Redstone Canyon", Safe = false, FoodDensity = "Low", Fossils = "Medium", Connections = { "FernPlains", "ApocalypticCity" } },
    SwampDelta = { DisplayName = "Swamp Delta", Safe = false, FoodDensity = "Medium", Fossils = "Medium", Connections = { "JungleBasin", "ApocalypticCity" } },
    ApocalypticCity = { DisplayName = "Apocalyptic City", DiscoveryName = "Old Eden discovered", Safe = false, FoodDensity = "Low", Fossils = "High", Connections = { "RedstoneCanyon", "SwampDelta" } },
    MountainNestingCliffs = { DisplayName = "Mountain Nesting Cliffs", Safe = false, FoodDensity = "Low", Fossils = "MediumHigh", Overlooks = { "FernPlains", "RedstoneCanyon" } },
}

return ZoneConfig
