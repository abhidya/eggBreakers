local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local map = Workspace:FindFirstChild("Map")
local storyboards = map and map:FindFirstChild("Storyboards")
local tagged = CollectionService:GetTagged("StoryAssetPlacement")

local function sortedKeys(set)
    local keys = {}
    for key in pairs(set) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function childNames(parent)
    local names = {}
    if parent then
        for _, child in ipairs(parent:GetChildren()) do
            table.insert(names, child.Name)
        end
    end
    table.sort(names)
    return names
end

local byBeat = {}
local byZone = {}
local sourceIds = {}
local records = {}
local fallback = 0
local importedTemplates = 0

for _, instance in ipairs(tagged) do
    if instance:IsDescendantOf(Workspace) then
        local beat = tostring(instance:GetAttribute("StoryBeatId") or "")
        local zone = tostring(instance:GetAttribute("ZoneId") or "")
        local sourceId = tostring(instance:GetAttribute("SourceAssetId") or "")
        local storyboardSourceId = tostring(instance:GetAttribute("StoryboardSourceAssetId") or "")
        if sourceId ~= "" and sourceId ~= "nil" then
            sourceIds[sourceId] = true
        end
        if storyboardSourceId ~= "" and storyboardSourceId ~= "nil" then
            sourceIds[storyboardSourceId] = true
        end
        byBeat[beat] = (byBeat[beat] or 0) + 1
        byZone[zone] = (byZone[zone] or 0) + 1
        if instance:GetAttribute("AssetBackedStoryboardProxy") == true then
            fallback = fallback + 1
        else
            importedTemplates = importedTemplates + 1
        end
        table.insert(records, {
            name = instance.Name,
            beat = beat,
            zone = zone,
            slot = tostring(instance:GetAttribute("StoryboardSlot") or ""),
            sourceAssetId = sourceId,
            storyboardSourceAssetId = storyboardSourceId,
            sourceTemplate = tostring(instance:GetAttribute("StoryAssetSourceTemplate") or ""),
            state = tostring(instance:GetAttribute("StoryAssetPlacementState") or ""),
            needsPlayerAngleScreenshot = instance:GetAttribute("NeedsPlayerAngleScreenshot") == true,
        })
    end
end

table.sort(records, function(a, b)
    return a.name < b.name
end)

print(HttpService:JSONEncode({
    mapStoryAssetPlacementsBuilt = map and map:GetAttribute("StoryAssetPlacementsBuilt") == true,
    mapStoryAssetPlacementCount = map and map:GetAttribute("StoryAssetPlacementCount") or 0,
    mapStoryAssetImportedTemplateCount = map and map:GetAttribute("StoryAssetImportedTemplateCount") or 0,
    mapStoryAssetFallbackProxyCount = map and map:GetAttribute("StoryAssetFallbackProxyCount") or 0,
    storyboards = childNames(storyboards),
    taggedStoryAssetPlacements = #records,
    importedTemplates = importedTemplates,
    fallbackProxies = fallback,
    uniqueStorySourceAssetIds = #sortedKeys(sourceIds),
    sourceAssetIds = sortedKeys(sourceIds),
    byBeat = byBeat,
    byZone = byZone,
    records = records,
}))
