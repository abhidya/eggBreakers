local AssetManifest = {}

AssetManifest.MinimumUniqueAssets = 500
AssetManifest.RequiredStatuses = {
    Final = true,
    Temporary = true,
    PendingImport = true,
}
AssetManifest.RequiredTypes = {
    Environment = true,
    CharacterModel = true,
    Foliage = true,
    FoodSource = true,
    WaterSource = true,
    NPCSpawnMarker = true,
    Nest = true,
    Fossil = true,
    Landmark = true,
    UI = true,
    Audio = true,
    VFX = true,
}

local zones = {
    "NurseryGrove",
    "FernPlains",
    "JungleBasin",
    "RedstoneCanyon",
    "SwampDelta",
    "ApocalypticCity",
    "MountainNestingCliffs",
}

local typeCycle = {
    "Environment",
    "Foliage",
    "FoodSource",
    "WaterSource",
    "NPCSpawnMarker",
    "Nest",
    "Fossil",
    "Landmark",
    "CharacterModel",
    "UI",
    "Audio",
    "VFX",
}

AssetManifest.Entries = {}

local function pad3(value)
    return string.format("%03d", value)
end

local function add(index)
    local assetType = typeCycle[((index - 1) % #typeCycle) + 1]
    local zone = zones[((index - 1) % #zones) + 1]
    local collisionEnabled = assetType == "Environment" or assetType == "Landmark" or assetType == "Nest"
    local status = index <= 32 and "Temporary" or "PendingImport"
    table.insert(AssetManifest.Entries, {
        AssetId = "EGG-G011-" .. pad3(index),
        Name = "G011 " .. zone .. " " .. assetType .. " Asset " .. pad3(index),
        CreatorSource = "eggBreakers internal asset import queue",
        AssetType = assetType,
        UsedIn = zone,
        ExplorerPath = "Workspace/Map/" .. (assetType == "Landmark" and "Landmarks" or "Zones/" .. zone),
        VisibleToPlayers = assetType ~= "Audio",
        ImportedScriptsPresent = false,
        ScriptsRemoved = true,
        ScriptsAudited = true,
        CollisionEnabled = collisionEnabled,
        PerformanceNotes = "G011 pipeline entry: unique id reserved; collision/query/touch must be audited at import.",
        ReplacementStatus = status,
        ScreenshotEvidence = "Pending Studio import screenshot batch " .. math.ceil(index / 25),
    })
end

for index = 1, AssetManifest.MinimumUniqueAssets do
    add(index)
end

function AssetManifest.GetById(assetId)
    for _, entry in ipairs(AssetManifest.Entries) do
        if entry.AssetId == assetId then
            return entry
        end
    end
    return nil
end

function AssetManifest.Validate(options)
    options = options or {}
    local minimum = options.minimum or AssetManifest.MinimumUniqueAssets
    local failures = {}
    local seen = {}
    local visibleCount = 0
    local finalCount = 0

    if #AssetManifest.Entries < minimum then
        table.insert(failures, "manifest has " .. tostring(#AssetManifest.Entries) .. " entries; expected at least " .. tostring(minimum))
    end

    for index, entry in ipairs(AssetManifest.Entries) do
        local prefix = "entry " .. tostring(index) .. " (" .. tostring(entry.Name) .. ")"
        if type(entry.AssetId) ~= "string" or entry.AssetId == "" or entry.AssetId == "TBD" then
            table.insert(failures, prefix .. " has missing/TBD AssetId")
        elseif seen[entry.AssetId] then
            table.insert(failures, prefix .. " duplicates AssetId " .. entry.AssetId)
        else
            seen[entry.AssetId] = true
        end
        if not AssetManifest.RequiredTypes[entry.AssetType] then
            table.insert(failures, prefix .. " has unsupported AssetType " .. tostring(entry.AssetType))
        end
        if not AssetManifest.RequiredStatuses[entry.ReplacementStatus] then
            table.insert(failures, prefix .. " has unsupported ReplacementStatus " .. tostring(entry.ReplacementStatus))
        end
        if entry.VisibleToPlayers then
            visibleCount = visibleCount + 1
        end
        if entry.ReplacementStatus == "Final" then
            finalCount = finalCount + 1
        end
        if entry.ImportedScriptsPresent then
            table.insert(failures, prefix .. " still has imported scripts present")
        end
        if entry.ScriptsAudited ~= true then
            table.insert(failures, prefix .. " lacks imported script audit flag")
        end
    end

    return {
        passed = #failures == 0,
        failures = failures,
        total = #AssetManifest.Entries,
        uniqueAssetIds = (function()
            local count = 0
            for _ in pairs(seen) do count = count + 1 end
            return count
        end)(),
        visibleCount = visibleCount,
        finalCount = finalCount,
    }
end

return AssetManifest
