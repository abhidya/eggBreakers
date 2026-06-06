local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function safeAttr(instance, name)
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
    if ok then
        return value
    end
    return instance.Name
end

local function childSummary(root)
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

local function countClasses(root)
    local counts = {}
    if not root then
        return counts
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        counts[descendant.ClassName] = (counts[descendant.ClassName] or 0) + 1
    end
    return counts
end

local function isTaggedAsset(instance)
    return safeAttr(instance, "SourceAssetId") ~= nil
        or safeAttr(instance, "AssetManifestId") ~= nil
        or safeAttr(instance, "CreatorStoreOnly") == true
        or safeAttr(instance, "ImportedVisibleAsset") == true
        or safeAttr(instance, "WorldAssetVerified") ~= nil
        or safeAttr(instance, "ValidationState") ~= nil
end

local function hasTaggedAncestor(instance, stopRoot)
    local current = instance.Parent
    while current and current ~= stopRoot.Parent do
        if isTaggedAsset(current) then
            return true
        end
        if current == stopRoot then
            return false
        end
        current = current.Parent
    end
    return false
end

local function sourceIdText(value)
    if value == nil then
        return nil
    end
    local text = tostring(value)
    if text == "" or text == "-1" or text == "0" then
        return nil
    end
    return text
end

local function collectTaggedRoots(root, maxRecords)
    local records = {}
    local unique = {}
    local visibleUnique = {}
    local creatorUnique = {}

    if not root then
        return {
            records = records,
            uniqueSourceAssetIds = 0,
            visibleSourceAssetIds = 0,
            creatorStoreSourceAssetIds = 0,
        }
    end

    local function consider(instance)
        if not isTaggedAsset(instance) then
            return
        end
        if hasTaggedAncestor(instance, root) then
            return
        end

        local sourceId = sourceIdText(safeAttr(instance, "SourceAssetId"))
        local importedVisible = safeAttr(instance, "ImportedVisibleAsset") == true
        local creatorStoreOnly = safeAttr(instance, "CreatorStoreOnly") == true
        if sourceId then
            unique[sourceId] = true
            if importedVisible then
                visibleUnique[sourceId] = true
            end
            if creatorStoreOnly then
                creatorUnique[sourceId] = true
            end
        end

        if #records < maxRecords then
            local tags = {}
            pcall(function()
                tags = CollectionService:GetTags(instance)
            end)
            table.insert(records, {
                path = pathOf(instance),
                name = instance.Name,
                className = instance.ClassName,
                sourceAssetId = sourceId,
                assetManifestId = safeAttr(instance, "AssetManifestId"),
                creatorStoreOnly = creatorStoreOnly,
                importedVisible = importedVisible,
                biomeId = safeAttr(instance, "BiomeId"),
                role = safeAttr(instance, "Role") or safeAttr(instance, "AssetRole") or safeAttr(instance, "FoodKind"),
                storyboardSlot = safeAttr(instance, "StoryboardSlot") or safeAttr(instance, "storyboardSlot"),
                validationState = safeAttr(instance, "ValidationState"),
                tags = tags,
                children = #instance:GetChildren(),
            })
        end
    end

    consider(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        consider(descendant)
    end

    local function setCount(set)
        local count = 0
        for _ in pairs(set) do
            count += 1
        end
        return count
    end

    table.sort(records, function(a, b)
        return a.path < b.path
    end)

    return {
        records = records,
        uniqueSourceAssetIds = setCount(unique),
        visibleSourceAssetIds = setCount(visibleUnique),
        creatorStoreSourceAssetIds = setCount(creatorUnique),
    }
end

local function requireShared(name)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if not shared then
        return nil, "ReplicatedStorage.Shared missing"
    end
    local module = shared:FindFirstChild(name)
    if not module then
        return nil, "module missing"
    end
    local ok, result = pcall(require, module)
    if not ok then
        return nil, tostring(result)
    end
    return result, nil
end

local map = Workspace:FindFirstChild("Map")
local importedAssets = map and map:FindFirstChild("ImportedAssets")
local biomeDressing = map and map:FindFirstChild("BiomeDressing")
local foodSources = map and map:FindFirstChild("FoodSources")
local waterSources = map and map:FindFirstChild("WaterSources")
local storyboards = map and map:FindFirstChild("Storyboards")
local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
local stagedDinos = Workspace:FindFirstChild("dinosaur") or game:FindFirstChild("staged:")
local npcs = Workspace:FindFirstChild("NPCs")

local assetManifest, manifestError = requireShared("AssetManifest")
local swampStoryboard, swampError = requireShared("SwampDeltaStoryboard")

local manifestCount = 0
if type(assetManifest) == "table" and type(assetManifest.SourceAssets) == "table" then
    manifestCount = #assetManifest.SourceAssets
end

local swampAssets = {}
if type(swampStoryboard) == "table" and type(swampStoryboard.Assets) == "table" then
    for key, asset in pairs(swampStoryboard.Assets) do
        table.insert(swampAssets, {
            key = key,
            sourceAssetId = asset.sourceAssetId,
            name = asset.name,
            query = asset.query,
            scriptRisk = asset.scriptRisk,
        })
    end
end
table.sort(swampAssets, function(a, b)
    return a.key < b.key
end)

local report = {
    placeId = game.PlaceId,
    jobId = game.JobId,
    workspaceChildren = childSummary(Workspace),
    mapChildren = childSummary(map),
    importedAssetsChildren = childSummary(importedAssets),
    importedLibraryChildren = childSummary(library),
    stagedDinoChildren = childSummary(stagedDinos),
    npcChildren = childSummary(npcs),
    storyboardsChildren = childSummary(storyboards),
    classCounts = {
        Workspace = countClasses(Workspace),
        Map = countClasses(map),
        ImportedAssetLibrary = countClasses(library),
        StagedDinos = countClasses(stagedDinos),
    },
    tagged = {
        Workspace = collectTaggedRoots(Workspace, 250),
        Map = collectTaggedRoots(map, 250),
        ImportedAssets = collectTaggedRoots(importedAssets, 250),
        ImportedAssetLibrary = collectTaggedRoots(library, 250),
        BiomeDressing = collectTaggedRoots(biomeDressing, 250),
        FoodSources = collectTaggedRoots(foodSources, 250),
        WaterSources = collectTaggedRoots(waterSources, 120),
        Storyboards = collectTaggedRoots(storyboards, 120),
        StagedDinos = collectTaggedRoots(stagedDinos, 200),
        NPCs = collectTaggedRoots(npcs, 120),
    },
    modules = {
        assetManifestSourceAssetCount = manifestCount,
        assetManifestError = manifestError,
        swampDeltaStoryboardError = swampError,
        swampDeltaValidationState = type(swampStoryboard) == "table" and swampStoryboard.ValidationState or nil,
        swampDeltaAssets = swampAssets,
    },
}

print("EGGBREAKERS_LIVE_INVENTORY_JSON_START")
print(HttpService:JSONEncode(report))
print("EGGBREAKERS_LIVE_INVENTORY_JSON_END")
