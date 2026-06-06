local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args

local function usage()
    error("usage: lune run tools/audit_place_inventory.luau <place.rbxl>", 0)
end

if #args ~= 1 then
    usage()
end

local inputPath = args[1]
if not fs.isFile(inputPath) then
    error(`input file does not exist: {inputPath}`, 0)
end

local function sortedKeys(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function valueToString(value)
    if value == nil then
        return ""
    end
    return tostring(value)
end

local function isMeaningfulSourceId(value)
    if value == nil then
        return false
    end
    local text = tostring(value)
    return text ~= "" and text ~= "-1" and text ~= "0"
end

local function safeAttr(instance, name)
    local ok, attrs = pcall(function()
        return instance:GetAttributes()
    end)
    if ok and attrs then
        return attrs[name]
    end
    return nil
end

local function attrCount(instance)
    local ok, attrs = pcall(function()
        return instance:GetAttributes()
    end)
    if not ok or not attrs then
        return 0
    end
    local count = 0
    for _ in pairs(attrs) do
        count += 1
    end
    return count
end

local function fullName(instance)
    local ok, value = pcall(function()
        return instance:GetFullName()
    end)
    if ok then
        return value
    end

    local names = {}
    local current = instance
    while current do
        table.insert(names, 1, current.Name)
        current = current.Parent
    end
    return table.concat(names, ".")
end

local function pathContains(path, fragment)
    return string.find(path, fragment, 1, true) ~= nil
end

local bytes = fs.readFile(inputPath)
local dataModel = roblox.deserializePlace(bytes)
local descendants = dataModel:GetDescendants()

local classCounts = {}
local topLevel = {}
local shallowTree = {}
local sourceIds = {}
local importedRecords = {}
local placedRecords = {}
local storyboardRecords = {}
local dinoRecords = {}
local biomeCounts = {}
local sourceBySlot = {}
local sourceByBiome = {}
local scriptCount = 0
local localScriptCount = 0
local moduleScriptCount = 0
local basePartCount = 0
local meshPartCount = 0
local modelCount = 0
local instancesWithCustomAttributes = 0

for _, child in ipairs(dataModel:GetChildren()) do
    table.insert(topLevel, `{child.ClassName}:{child.Name}`)
    local grandchildren = {}
    for _, grandchild in ipairs(child:GetChildren()) do
        table.insert(grandchildren, `{grandchild.ClassName}:{grandchild.Name}`)
    end
    table.sort(grandchildren)
    local limit = math.min(#grandchildren, 30)
    table.insert(shallowTree, `{child.ClassName}:{child.Name} -> {table.concat({ table.unpack(grandchildren, 1, limit) }, ", ")}`)
end
table.sort(topLevel)
table.sort(shallowTree)

for _, instance in ipairs(descendants) do
    classCounts[instance.ClassName] = (classCounts[instance.ClassName] or 0) + 1
    if instance:IsA("Script") then
        scriptCount += 1
    elseif instance:IsA("LocalScript") then
        localScriptCount += 1
    elseif instance:IsA("ModuleScript") then
        moduleScriptCount += 1
    end
    if instance:IsA("BasePart") then
        basePartCount += 1
    end
    if instance:IsA("MeshPart") then
        meshPartCount += 1
    end
    if instance:IsA("Model") then
        modelCount += 1
    end
    if attrCount(instance) > 0 then
        instancesWithCustomAttributes += 1
    end

    local path = fullName(instance)
    local sourceId = safeAttr(instance, "SourceAssetId")
    local manifestId = safeAttr(instance, "AssetManifestId")
    local creatorStoreOnly = safeAttr(instance, "CreatorStoreOnly")
    local importedVisible = safeAttr(instance, "ImportedVisibleAsset")
    local biomeId = safeAttr(instance, "BiomeId")
    local validationState = safeAttr(instance, "ValidationState")
    local storyboardSlot = safeAttr(instance, "StoryboardSlot") or safeAttr(instance, "storyboardSlot")

    if isMeaningfulSourceId(sourceId) then
        sourceIds[tostring(sourceId)] = true
    end

    if type(biomeId) == "string" and biomeId ~= "" then
        biomeCounts[biomeId] = (biomeCounts[biomeId] or 0) + 1
        if isMeaningfulSourceId(sourceId) then
            sourceByBiome[biomeId] = sourceByBiome[biomeId] or {}
            sourceByBiome[biomeId][tostring(sourceId)] = true
        end
    end

    if type(storyboardSlot) == "string" and storyboardSlot ~= "" and isMeaningfulSourceId(sourceId) then
        sourceBySlot[storyboardSlot] = sourceBySlot[storyboardSlot] or {}
        sourceBySlot[storyboardSlot][tostring(sourceId)] = true
    end

    local isImportedPath = pathContains(path, "Workspace.Map.ImportedAssets")
        or pathContains(path, "ReplicatedStorage.ImportedAssetLibrary")
    local isPlacedPath = pathContains(path, "Workspace.Map")
        or pathContains(path, "Workspace.NPCs")
        or pathContains(path, "Workspace.dinosaur")
    local isTaggedImport = creatorStoreOnly == true
        or importedVisible == true
        or isMeaningfulSourceId(sourceId)
        or manifestId ~= nil

    if isImportedPath or isTaggedImport then
        table.insert(importedRecords, {
            path = path,
            className = instance.ClassName,
            name = instance.Name,
            sourceAssetId = valueToString(sourceId),
            assetManifestId = valueToString(manifestId),
            creatorStoreOnly = creatorStoreOnly == true,
            importedVisible = importedVisible == true,
            biomeId = valueToString(biomeId),
            storyboardSlot = valueToString(storyboardSlot),
        })
    end

    if isPlacedPath and isTaggedImport then
        table.insert(placedRecords, {
            path = path,
            className = instance.ClassName,
            name = instance.Name,
            sourceAssetId = valueToString(sourceId),
            assetManifestId = valueToString(manifestId),
            creatorStoreOnly = creatorStoreOnly == true,
            importedVisible = importedVisible == true,
            biomeId = valueToString(biomeId),
            storyboardSlot = valueToString(storyboardSlot),
        })
    end

    if pathContains(path, "Workspace.Map.Storyboards")
        or pathContains(path, "SwampDeltaOxygenFish")
        or validationState ~= nil
    then
        table.insert(storyboardRecords, {
            path = path,
            className = instance.ClassName,
            name = instance.Name,
            sourceAssetId = valueToString(sourceId),
            validationState = valueToString(validationState),
            biomeId = valueToString(biomeId),
            storyboardSlot = valueToString(storyboardSlot),
        })
    end

    if pathContains(path, "Workspace.dinosaur") or pathContains(path, "Workspace.NPCs") then
        if instance:IsA("Model") then
            table.insert(dinoRecords, {
                path = path,
                name = instance.Name,
                sourceAssetId = valueToString(sourceId),
                importedVisible = importedVisible == true,
                biomeId = valueToString(biomeId),
            })
        end
    end
end

local function printSourceMap(title, map)
    print("")
    print(title)
    for _, key in ipairs(sortedKeys(map)) do
        local count = 0
        for _ in pairs(map[key]) do
            count += 1
        end
        print(`- {key}: {count} unique source ids`)
        local ids = sortedKeys(map[key])
        local limit = math.min(#ids, 20)
        if limit > 0 then
            print(`  ids: {table.concat({ table.unpack(ids, 1, limit) }, ", ")}`)
        end
    end
end

print(`# Place Inventory Audit`)
print(`place={inputPath}`)
print(`descendants={#descendants}`)
print(`topLevel={table.concat(topLevel, ", ")}`)
print(`models={modelCount}`)
print(`baseParts={basePartCount}`)
print(`meshParts={meshPartCount}`)
print(`scripts={scriptCount}`)
print(`localScripts={localScriptCount}`)
print(`moduleScripts={moduleScriptCount}`)
print(`uniqueTaggedSourceAssetIds={#sortedKeys(sourceIds)}`)
print(`instancesWithCustomAttributes={instancesWithCustomAttributes}`)
print(`importedOrTaggedRecords={#importedRecords}`)
print(`placedTaggedRecords={#placedRecords}`)
print(`storyboardRecords={#storyboardRecords}`)
print(`dinoModelRecords={#dinoRecords}`)

print("")
print("## Shallow Tree")
for _, line in ipairs(shallowTree) do
    print(`- {line}`)
end

print("")
print("## Class Counts")
for _, className in ipairs(sortedKeys(classCounts)) do
    print(`- {className}: {classCounts[className]}`)
end

print("")
print("## Biome Attribute Counts")
for _, biome in ipairs(sortedKeys(biomeCounts)) do
    print(`- {biome}: {biomeCounts[biome]}`)
end

printSourceMap("## Source IDs by Biome", sourceByBiome)
printSourceMap("## Source IDs by Storyboard Slot", sourceBySlot)

local function printRecords(title, records, limit)
    print("")
    print(title)
    table.sort(records, function(a, b)
        return a.path < b.path
    end)
    local max = math.min(#records, limit)
    for i = 1, max do
        local record = records[i]
        print(`- path={record.path} class={record.className or ""} source={record.sourceAssetId or ""} manifest={record.assetManifestId or ""} visible={tostring(record.importedVisible)} creator={tostring(record.creatorStoreOnly)} biome={record.biomeId or ""} slot={record.storyboardSlot or ""} state={record.validationState or ""}`)
    end
    if #records > max then
        print(`- ... {#records - max} more`)
    end
end

printRecords("## Placed Tagged / Imported Records", placedRecords, 220)
printRecords("## Storyboard Records", storyboardRecords, 120)
printRecords("## Dino Model Records", dinoRecords, 160)
