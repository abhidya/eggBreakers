local SwampDeltaStoryboard = {}

SwampDeltaStoryboard.BeatId = "G020_Beat5_SwampDelta_OxygenFish"
SwampDeltaStoryboard.DisplayName = "Swamp Delta Oxygen/Fish"
SwampDeltaStoryboard.SourceDocument = "docs/G020/CacheBackedStoryboards.md"
SwampDeltaStoryboard.CacheManifest = "asset-brain/v1/manifest.json"
SwampDeltaStoryboard.ValidationState = "cache_only_pending_studio_asset_inspection"

SwampDeltaStoryboard.Assets = {
    SwampTree = {
        sourceAssetId = "543827347",
        name = "Dead Swamp Tree",
        query = "swamp tree",
        source = "project_asset_manifest+live_mcp_curate_assets",
        scriptRisk = "NoScripts",
    },
    LilyPad = {
        sourceAssetId = "708797531",
        name = "Water Lily",
        query = "water lily",
        source = "live_mcp_curate_assets",
        scriptRisk = "NoScripts",
    },
    Fish = {
        sourceAssetId = "1725227984",
        name = "Fish",
        query = "fish",
        source = "live_mcp_curate_assets",
        scriptRisk = "NoScripts",
    },
    SpinosaurusSilhouette = {
        sourceAssetId = "5434115710",
        name = "Spinosaurus ( OLD )",
        query = "spinosaurus",
        source = "live_mcp_curate_assets",
        scriptRisk = "NoScripts",
    },
}

SwampDeltaStoryboard.RejectedOrDeferred = {
    {
        sourceAssetId = "458900702",
        name = "Venusaur Doll",
        reason = "semantic false positive for water lily; not a swamp traversal prop",
    },
    {
        sourceAssetId = "75850368020021",
        name = "Bridge over a Pond of Water Lilies by Claude Monet",
        reason = "likely image/art object rather than usable 3D lily-pad geometry",
    },
    {
        sourceAssetId = "12261121165",
        name = "Swimming Fish",
        reason = "candidate remains deferred until script audit",
    },
    {
        sourceAssetId = "2989814926",
        name = "Spinosaurus npc",
        reason = "NPC variant remains deferred until script audit",
    },
    {
        sourceAssetId = "8920161016",
        name = "Spinosaurus NPC (WORKS ON BOTH R6 & R15)",
        reason = "NPC variant remains deferred until script audit",
    },
}

SwampDeltaStoryboard.SafeNodes = {
    { name = "SwampDelta_LilySafeNode_A", position = Vector3.new(-116, 10.45, 942), radius = 12, oxygenRelief = 8 },
    { name = "SwampDelta_LilySafeNode_B", position = Vector3.new(-34, 10.45, 970), radius = 14, oxygenRelief = 8 },
    { name = "SwampDelta_LilySafeNode_C", position = Vector3.new(48, 10.45, 934), radius = 11, oxygenRelief = 8 },
}

SwampDeltaStoryboard.FishSources = {
    { name = "SwampDelta_FishCache_A", waterName = "SwampRiverFishRun", offset = Vector3.new(-190, 0, -8) },
    { name = "SwampDelta_FishCache_B", waterName = "SwampRiverFishRun", offset = Vector3.new(15, 0, 10) },
    { name = "SwampDelta_FishCache_C", waterName = "SwampRiverFishRun", offset = Vector3.new(230, 0, -12) },
}

SwampDeltaStoryboard.ApexWarning = {
    name = "SwampDelta_SpinosaurusWakeSilhouette",
    position = Vector3.new(72, 13, 996),
    size = Vector3.new(26, 10, 6),
    yawDegrees = -18,
}

SwampDeltaStoryboard.PlayerAngleReview = {
    spaceId = "swamp_delta_oxygen_fish",
    entry = Vector3.new(-452, 13, 950),
    center = Vector3.new(-80, 12, 950),
    lookAt = Vector3.new(-10, 11, 958),
    quadrants = { "NW", "NE", "SW", "SE" },
    requiredVerdict = "player_angle_signed_off",
}

return SwampDeltaStoryboard
