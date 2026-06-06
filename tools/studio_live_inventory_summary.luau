local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function attr(instance, name)
    local ok, value = pcall(function()
        return instance:GetAttribute(name)
    end)
    if ok then
        return value
    end
    return nil
end

local function pathOf(instance)
    local ok, value = pcall(function()
        return instance:GetFullName()
    end)
    return ok and value or instance.Name
end

local function sourceText(instance)
    local value = attr(instance, "SourceAssetId")
    if value == nil then
        return nil
    end
    local text = tostring(value)
    if text == "" or text == "-1" or text == "0" then
        return nil
    end
    return text
end

local function childNames(root)
    local result = {}
    if not root then
        return result
    end
    for _, child in ipairs(root:GetChildren()) do
        table.insert(result, {
            name = child.Name,
            className = child.ClassName,
            children = #child:GetChildren(),
        })
    end
    table.sort(result, function(a, b)
        return a.name < b.name
    end)
    return result
end

local function countSet(set)
    local count = 0
    for _ in pairs(set) do
        count += 1
    end
    return count
end

local function setToArray(set)
    local result = {}
    for value in pairs(set) do
        table.insert(result, value)
    end
    table.sort(result)
    return result
end

local function makeBucket()
    return {
        roots = 0,
        withSource = 0,
        visible = 0,
        creatorStoreOnly = 0,
        unique = {},
        records = {},
    }
end

local function addRecord(bucket, instance, sourceId, limit)
    bucket.roots += 1
    if sourceId then
        bucket.withSource += 1
        bucket.unique[sourceId] = true
    end
    if attr(instance, "ImportedVisibleAsset") == true then
        bucket.visible += 1
    end
    if attr(instance, "CreatorStoreOnly") == true then
        bucket.creatorStoreOnly += 1
    end
    if #bucket.records < limit then
        table.insert(bucket.records, {
            path = pathOf(instance),
            name = instance.Name,
            className = instance.ClassName,
            sourceAssetId = sourceId,
            assetManifestId = attr(instance, "AssetManifestId"),
            importedVisible = attr(instance, "ImportedVisibleAsset") == true,
            creatorStoreOnly = attr(instance, "CreatorStoreOnly") == true,
            role = attr(instance, "Role") or attr(instance, "AssetRole") or attr(instance, "FoodKind"),
            biomeId = attr(instance, "BiomeId"),
            validationState = attr(instance, "ValidationState"),
        })
    end
end

local function isTagged(instance)
    return attr(instance, "SourceAssetId") ~= nil
        or attr(instance, "AssetManifestId") ~= nil
        or attr(instance, "ImportedVisibleAsset") == true
        or attr(instance, "CreatorStoreOnly") == true
        or attr(instance, "ValidationState") ~= nil
end

local function hasTaggedAncestor(instance, root)
    local current = instance.Parent
    while current and current ~= root.Parent do
        if isTagged(current) then
            return true
        end
        if current == root then
            return false
        end
        current = current.Parent
    end
    return false
end

local function summarizeTaggedRoots(root, recordLimit)
    local bucket = makeBucket()
    if not root then
        return bucket
    end
    local function consider(instance)
        if isTagged(instance) and not hasTaggedAncestor(instance, root) then
            addRecord(bucket, instance, sourceText(instance), recordLimit)
        end
    end
    consider(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        consider(descendant)
    end
    bucket.uniqueSourceAssetIds = countSet(bucket.unique)
    bucket.sourceAssetIds = setToArray(bucket.unique)
    bucket.unique = nil
    table.sort(bucket.records, function(a, b)
        return a.path < b.path
    end)
    return bucket
end

local function summarizeByBiome(root)
    local byBiome = {}
    if not root then
        return byBiome
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if isTagged(descendant) and not hasTaggedAncestor(descendant, root) then
            local path = pathOf(descendant)
            local biome = attr(descendant, "BiomeId")
            if not biome then
                biome = path:match("Workspace%.Map%.FoodSources%.([^%.]+)")
                    or path:match("Workspace%.Map%.BiomeDressing%.([^%.]+)")
                    or path:match("Workspace%.Map%.WaterSources%.([^%.]+)")
                    or path:match("Workspace%.Map%.NPCSpawns%.([^%.]+)")
                    or path:match("Workspace%.Map%.([^%.]+)")
                    or "Unscoped"
            end
            byBiome[biome] = byBiome[biome] or makeBucket()
            addRecord(byBiome[biome], descendant, sourceText(descendant), 24)
        end
    end
    for _, bucket in pairs(byBiome) do
        bucket.uniqueSourceAssetIds = countSet(bucket.unique)
        bucket.sourceAssetIds = setToArray(bucket.unique)
        bucket.unique = nil
        table.sort(bucket.records, function(a, b)
            return a.path < b.path
        end)
    end
    return byBiome
end

local function requireShared(name)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if not shared then
        return nil
    end
    local module = shared:FindFirstChild(name)
    if not module then
        return nil
    end
    local ok, result = pcall(require, module)
    return ok and result or nil
end

local map = Workspace:FindFirstChild("Map")
local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
local storyboards = map and map:FindFirstChild("Storyboards")
local stagedDinos = Workspace:FindFirstChild("dinosaur") or game:FindFirstChild("staged:")
local npcFolder = Workspace:FindFirstChild("NPCs")

local storyboard = requireShared("SwampDeltaStoryboard")
local storyboardAssets = {}
local storyboardMissingFromMap = {}
if type(storyboard) == "table" and type(storyboard.Assets) == "table" then
    local mapSummary = summarizeTaggedRoots(map, 0)
    local mapSources = {}
    for _, id in ipairs(mapSummary.sourceAssetIds or {}) do
        mapSources[id] = true
    end
    for key, asset in pairs(storyboard.Assets) do
        local id = tostring(asset.sourceAssetId)
        local row = {
            key = key,
            sourceAssetId = id,
            name = asset.name,
            query = asset.query,
            presentInMap = mapSources[id] == true,
        }
        table.insert(storyboardAssets, row)
        if not row.presentInMap then
            table.insert(storyboardMissingFromMap, row)
        end
    end
    table.sort(storyboardAssets, function(a, b)
        return a.key < b.key
    end)
    table.sort(storyboardMissingFromMap, function(a, b)
        return a.key < b.key
    end)
end

local assetManifest = requireShared("AssetManifest")
local manifestCount = type(assetManifest) == "table" and type(assetManifest.SourceAssets) == "table" and #assetManifest.SourceAssets or 0

local report = {
    mode = "runtime-summary",
    workspaceChildren = childNames(Workspace),
    mapChildren = childNames(map),
    libraryChildren = childNames(library),
    stagedDinoChildren = childNames(stagedDinos),
    npcChildren = childNames(npcFolder),
    storyboardsChildren = childNames(storyboards),
    manifestSourceAssetCount = manifestCount,
    tagged = {
        Map = summarizeTaggedRoots(map, 80),
        ImportedAssetLibrary = summarizeTaggedRoots(library, 80),
        Storyboards = summarizeTaggedRoots(storyboards, 40),
        NPCs = summarizeTaggedRoots(npcFolder, 40),
        StagedDinos = summarizeTaggedRoots(stagedDinos, 20),
    },
    byBiome = summarizeByBiome(map),
    swampDeltaStoryboard = {
        validationState = type(storyboard) == "table" and storyboard.ValidationState or nil,
        assets = storyboardAssets,
        missingFromMap = storyboardMissingFromMap,
    },
}

print("EGGBREAKERS_LIVE_SUMMARY_JSON_START")
print(HttpService:JSONEncode(report))
print("EGGBREAKERS_LIVE_SUMMARY_JSON_END")
