local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function attr(instance, name)
    local ok, value = pcall(function()
        return instance:GetAttribute(name)
    end)
    return ok and value or nil
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

local function summarize(root)
    local out = {
        roots = 0,
        visible = 0,
        creatorStoreOnly = 0,
        withSource = 0,
        missingSource = 0,
        sourceIds = {},
        manifestIds = {},
    }
    if not root then
        out.uniqueSourceAssetIds = 0
        out.sourceAssetIds = {}
        out.manifestIdList = {}
        return out
    end
    local function consider(instance)
        if not isTagged(instance) or hasTaggedAncestor(instance, root) then
            return
        end
        out.roots += 1
        if attr(instance, "ImportedVisibleAsset") == true then
            out.visible += 1
        end
        if attr(instance, "CreatorStoreOnly") == true then
            out.creatorStoreOnly += 1
        end
        local sourceId = sourceText(instance)
        if sourceId then
            out.withSource += 1
            out.sourceIds[sourceId] = true
        else
            out.missingSource += 1
        end
        local manifestId = attr(instance, "AssetManifestId")
        if manifestId ~= nil then
            out.manifestIds[tostring(manifestId)] = true
        end
    end
    consider(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        consider(descendant)
    end
    out.uniqueSourceAssetIds = countSet(out.sourceIds)
    out.sourceAssetIds = setToArray(out.sourceIds)
    out.manifestIdList = setToArray(out.manifestIds)
    out.sourceIds = nil
    out.manifestIds = nil
    return out
end

local function byBiome(root)
    local out = {}
    if not root then
        return out
    end
    local function biomeFor(instance)
        local path = instance:GetFullName()
        return attr(instance, "BiomeId")
            or path:match("Workspace%.Map%.FoodSources%.([^%.]+)")
            or path:match("Workspace%.Map%.BiomeDressing%.([^%.]+)")
            or path:match("Workspace%.Map%.WaterSources%.([^%.]+)")
            or path:match("Workspace%.Map%.NPCSpawns%.([^%.]+)")
            or path:match("Workspace%.Map%.([^%.]+)")
            or "Unscoped"
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if isTagged(descendant) and not hasTaggedAncestor(descendant, root) then
            local biome = biomeFor(descendant)
            out[biome] = out[biome] or {
                roots = 0,
                visible = 0,
                withSource = 0,
                missingSource = 0,
                sourceIds = {},
                manifestIds = {},
            }
            local bucket = out[biome]
            bucket.roots += 1
            if attr(descendant, "ImportedVisibleAsset") == true then
                bucket.visible += 1
            end
            local sourceId = sourceText(descendant)
            if sourceId then
                bucket.withSource += 1
                bucket.sourceIds[sourceId] = true
            else
                bucket.missingSource += 1
            end
            local manifestId = attr(descendant, "AssetManifestId")
            if manifestId ~= nil then
                bucket.manifestIds[tostring(manifestId)] = true
            end
        end
    end
    for _, bucket in pairs(out) do
        bucket.uniqueSourceAssetIds = countSet(bucket.sourceIds)
        bucket.sourceAssetIds = setToArray(bucket.sourceIds)
        bucket.manifestIdList = setToArray(bucket.manifestIds)
        bucket.sourceIds = nil
        bucket.manifestIds = nil
    end
    return out
end

local function childCount(root)
    if not root then
        return 0
    end
    return #root:GetChildren()
end

local function requireShared(name)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local module = shared and shared:FindFirstChild(name)
    if not module then
        return nil
    end
    local ok, result = pcall(require, module)
    return ok and result or nil
end

local map = Workspace:FindFirstChild("Map")
local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
local storyboards = map and map:FindFirstChild("Storyboards")
local npcs = Workspace:FindFirstChild("NPCs")
local stagedDinos = Workspace:FindFirstChild("dinosaur") or game:FindFirstChild("staged:")

local mapSummary = summarize(map)
local storyboard = requireShared("SwampDeltaStoryboard")
local missingStoryboard = {}
if type(storyboard) == "table" and type(storyboard.Assets) == "table" then
    local live = {}
    for _, id in ipairs(mapSummary.sourceAssetIds) do
        live[id] = true
    end
    for key, asset in pairs(storyboard.Assets) do
        local id = tostring(asset.sourceAssetId)
        if not live[id] then
            table.insert(missingStoryboard, {
                key = key,
                sourceAssetId = id,
                name = asset.name,
                query = asset.query,
            })
        end
    end
    table.sort(missingStoryboard, function(a, b)
        return a.key < b.key
    end)
end

local report = {
    workspaceChildCount = childCount(Workspace),
    mapChildCount = childCount(map),
    npcChildCount = childCount(npcs),
    stagedDinoSpeciesCount = childCount(stagedDinos),
    storyboardsChildCount = childCount(storyboards),
    summaries = {
        Map = mapSummary,
        ImportedAssetLibrary = summarize(library),
        Storyboards = summarize(storyboards),
        NPCs = summarize(npcs),
        StagedDinos = summarize(stagedDinos),
    },
    byBiome = byBiome(map),
    missingSwampStoryboardAssetsFromMap = missingStoryboard,
}

print("EGGBREAKERS_LIVE_COUNTS_JSON_START")
print(HttpService:JSONEncode(report))
print("EGGBREAKERS_LIVE_COUNTS_JSON_END")
