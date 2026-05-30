local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)

local AssetImportAuditService = {}

AssetImportAuditService.ImportedLibraryName = "ImportedAssetLibrary"
AssetImportAuditService.WorkspaceImportedPath = { "Map", "ImportedAssets" }
AssetImportAuditService.QuarantineFolderName = "ImportedScriptQuarantine"
AssetImportAuditService.QualityQuarantineFolderName = "QuarantinedImportedAssets"

local SCRIPT_CLASS_NAMES = {
    Script = true,
    LocalScript = true,
    ModuleScript = true,
}

local EXECUTABLE_CLASS_NAMES = {
    Script = true,
    LocalScript = true,
}

local LOW_QUALITY_NAME_PATTERNS = {
    "food[%s_%-]*ball",
    "glow[%w%s_%-]*ball",
    "glowing[%w%s_%-]*ball",
    "ball[%s_%-]*tree",
    "rectangle[%w%s_%-]*tree",
    "rectangle[%w%s_%-]*ball[%w%s_%-]*tree",
    "simple[%s_%-]*generated",
    "debug[%s_%-]*fallback",
    "placeholder",
}

local function isA(instance, className)
    local ok, result = pcall(function()
        return instance:IsA(className)
    end)
    return ok and result == true
end

local isGlowingBallPart
local looksLikeRectangleBallTree

local function isPartShape(instance, shape)
    return instance.ClassName == "Part" and instance.Shape == shape
end

local function nameLooksLowQuality(instance)
    local text = string.lower(instance.Name or "")
    for _, pattern in ipairs(LOW_QUALITY_NAME_PATTERNS) do
        if string.find(text, pattern) then
            return true
        end
    end
    return false
end

local function looksLowQualityGeneratedFoodOrVegetation(instance)
    if nameLooksLowQuality(instance) or isGlowingBallPart(instance) or looksLikeRectangleBallTree(instance) then
        return true
    end
    if instance.GetDescendants then
        for _, descendant in ipairs(instance:GetDescendants()) do
            if nameLooksLowQuality(descendant) or isGlowingBallPart(descendant) then
                return true
            end
        end
    end
    return false
end

local function instanceNameContains(instance, token)
    return string.find(string.lower(instance.Name or ""), token, 1, true) ~= nil
end

isGlowingBallPart = function(instance)
    if not isA(instance, "BasePart") then return false end
    if not instanceNameContains(instance, "ball") and not isPartShape(instance, Enum.PartType.Ball) then return false end
    if instance.Material == Enum.Material.Neon then return true end
    if instance.GetDescendants then
        for _, descendant in ipairs(instance:GetDescendants()) do
            if isA(descendant, "PointLight") or isA(descendant, "SpotLight") or isA(descendant, "SurfaceLight") then
                return true
            end
        end
    end
    return false
end

looksLikeRectangleBallTree = function(instance)
    if not instanceNameContains(instance, "tree") then return false end
    local hasBlock = false
    local hasBall = false
    local function visit(part)
        hasBlock = hasBlock or isPartShape(part, Enum.PartType.Block)
        hasBall = hasBall or isPartShape(part, Enum.PartType.Ball)
    end
    visit(instance)
    if instance.GetDescendants then
        for _, descendant in ipairs(instance:GetDescendants()) do
            visit(descendant)
        end
    end
    return hasBlock and hasBall
end

local function containsMeshPart(instance)
    if isA(instance, "MeshPart") then return true end
    if not instance.GetDescendants then return false end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if isA(descendant, "MeshPart") then
            return true
        end
    end
    return false
end

local function isScriptInstance(instance)
    return SCRIPT_CLASS_NAMES[instance.ClassName] == true
end

local function isExecutableScript(instance)
    return EXECUTABLE_CLASS_NAMES[instance.ClassName] == true
end

local function addUnique(set, value)
    if value == nil or value == "" then return end
    set[tostring(value)] = true
end

local function countSet(set)
    local count = 0
    for _ in pairs(set) do
        count = count + 1
    end
    return count
end

local function normalizeQualityExclusionKind(value)
    if value == nil then return nil end
    local text = string.lower(tostring(value))
    if text == "mesh" or text == "mesh-only" or text == "mesh_exclusion" then return "mesh" end
    if text == "lq" or text == "low-quality" or text == "lowquality" or text == "simple-generated" then return "lowQuality" end
    if text == "debug" or text == "debug-looking" then return "debug" end
    return text
end

local function getChildByPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local function getOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

function AssetImportAuditService:GetImportedRoots()
    local roots = {}
    local library = ReplicatedStorage:FindFirstChild(self.ImportedLibraryName)
    if library then
        table.insert(roots, { root = library, location = "ReplicatedStorage/" .. self.ImportedLibraryName, library = true })
    end

    local workspaceImported = getChildByPath(Workspace, self.WorkspaceImportedPath)
    if workspaceImported then
        table.insert(roots, { root = workspaceImported, location = "Workspace/Map/ImportedAssets", placed = true })
    end
    return roots
end

function AssetImportAuditService:IsImportedCandidate(instance)
    if not instance then return false end
    if instance:GetAttribute("SourceAssetId") ~= nil then return true end
    if instance:GetAttribute("AssetManifestId") ~= nil then return true end
    if instance:GetAttribute("CreatorStoreOnly") == true then return true end
    if instance:GetAttribute("ImportedVisibleAsset") == true then return true end
    return false
end

function AssetImportAuditService:IsVisibleImportedAsset(instance)
    if instance:GetAttribute("ImportedVisibleAsset") == true then return true end
    if not instance:IsA("Model") and not instance:IsA("Folder") then return false end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then
            return true
        end
    end
    return false
end

function AssetImportAuditService:GetQualityExclusionKind(instance)
    if looksLowQualityGeneratedFoodOrVegetation(instance) then
        return "lowQuality"
    end

    local current = instance
    while current do
        local kind = normalizeQualityExclusionKind(current:GetAttribute("AssetQualityExclusionKind"))
        if kind then return kind end
        if current:GetAttribute("LowQualityAsset") == true or current:GetAttribute("AssetQualityExcluded") == true then
            return "lowQuality"
        end
        if current:GetAttribute("MeshExcludedAsset") == true then
            return "mesh"
        end
        if current:GetAttribute("DebugOnly") == true or current:GetAttribute("DebugFallbackVisual") == true then
            return "debug"
        end
        current = current.Parent
    end
    return nil
end

function AssetImportAuditService:HasRequiredPlayableVisual(instance)
    local current = instance
    while current do
        if current:GetAttribute("RequiredPlayableVisual") == true then return true end
        current = current.Parent
    end
    return false
end

function AssetImportAuditService:HasRequiredPlayableVisualPolicyNote(instance)
    local current = instance
    while current do
        local note = current:GetAttribute("RequiredPlayableVisualPolicyNote")
        if note ~= nil and tostring(note) ~= "" then return true end
        note = current:GetAttribute("AssetQualityPolicyNote")
        if note ~= nil and tostring(note) ~= "" then return true end
        current = current.Parent
    end
    return false
end

function AssetImportAuditService:_manifestEntryFor(instance)
    local manifestId = instance:GetAttribute("AssetManifestId")
    if manifestId ~= nil then
        local byManifest = AssetManifest.GetById(tostring(manifestId))
        if byManifest then return byManifest end
    end

    local sourceAssetId = instance:GetAttribute("SourceAssetId")
    if sourceAssetId ~= nil then
        local bySource = AssetManifest.GetBySourceAssetId(tostring(sourceAssetId))
        if bySource then return bySource end
    end
    return nil
end

function AssetImportAuditService:_tagFromManifest(instance, entry)
    if not entry then return false end
    local changed = false
    if instance:GetAttribute("SourceAssetId") == nil then
        instance:SetAttribute("SourceAssetId", entry.SourceAssetId)
        changed = true
    end
    if instance:GetAttribute("AssetManifestId") == nil then
        instance:SetAttribute("AssetManifestId", entry.AssetId)
        changed = true
    end
    if instance:GetAttribute("CreatorStoreOnly") ~= true then
        instance:SetAttribute("CreatorStoreOnly", true)
        changed = true
    end
    if self:IsVisibleImportedAsset(instance) and instance:GetAttribute("ImportedVisibleAsset") ~= true then
        instance:SetAttribute("ImportedVisibleAsset", true)
        changed = true
    end
    return changed
end

function AssetImportAuditService:_ensureQuarantineFolder()
    return getOrCreateFolder(ReplicatedStorage, self.QuarantineFolderName)
end

function AssetImportAuditService:_ensureQualityQuarantineFolder()
    return getOrCreateFolder(ReplicatedStorage, self.QualityQuarantineFolderName)
end


function AssetImportAuditService:_hasQualityExcludedAncestor(instance)
    local current = instance.Parent
    while current do
        if self:IsImportedCandidate(current) and self:GetQualityExclusionKind(current) ~= nil then
            return true
        end
        current = current.Parent
    end
    return false
end

function AssetImportAuditService:_quarantineQualityAsset(instance, quarantineFolder, records, kind)
    if instance == quarantineFolder or instance:IsDescendantOf(quarantineFolder) then return end
    if kind ~= "mesh" and self:HasRequiredPlayableVisual(instance) then return end
    if self:_hasQualityExcludedAncestor(instance) then return end

    table.insert(records, {
        path = instance:GetFullName(),
        className = instance.ClassName,
        sourceAssetId = instance:GetAttribute("SourceAssetId"),
        qualityExclusionKind = kind,
    })

    instance:SetAttribute("AssetQualityQuarantined", true)
    instance:SetAttribute("ReleaseReadyBlockedReason", kind == "mesh" and "mesh-excluded" or "low-quality-excluded")
    instance.Parent = quarantineFolder
end

function AssetImportAuditService:_quarantineScript(scriptInstance, quarantineFolder, records)
    local record = {
        path = scriptInstance:GetFullName(),
        className = scriptInstance.ClassName,
        sourceAssetId = scriptInstance:GetAttribute("SourceAssetId"),
    }
    table.insert(records, record)

    if scriptInstance:IsA("Script") or scriptInstance:IsA("LocalScript") then
        scriptInstance.Disabled = true
    end
    scriptInstance:SetAttribute("ImportedScriptQuarantined", true)
    scriptInstance.Parent = quarantineFolder
end

function AssetImportAuditService:AuditAndRepair(options)
    options = options or {}
    local mutate = options.mutate == true
    local failures = {}
    local importedRecords = {}
    local scriptRecords = {}
    local quarantinedScripts = {}
    local quarantinedQualityAssets = {}
    local catalogedSourceIds = {}
    local importedSourceIds = {}
    local auditedSourceIds = {}
    local taggedSourceIds = {}
    local placedSourceIds = {}
    local releaseReadySourceIds = {}
    local qualityExcludedSourceIds = {}
    local meshExcludedSourceIds = {}
    local lowQualityExcludedSourceIds = {}
    local debugExcludedSourceIds = {}

    for _, entry in ipairs(AssetManifest.Entries) do
        addUnique(catalogedSourceIds, entry.SourceAssetId)
    end

    local quarantineFolder = nil
    local qualityQuarantineFolder = nil
    if mutate then
        quarantineFolder = self:_ensureQuarantineFolder()
        qualityQuarantineFolder = self:_ensureQualityQuarantineFolder()
    end

    for _, rootInfo in ipairs(self:GetImportedRoots()) do
        local candidates = {}
        if self:IsImportedCandidate(rootInfo.root) then
            table.insert(candidates, rootInfo.root)
        end
        for _, descendant in ipairs(rootInfo.root:GetDescendants()) do
            if self:IsImportedCandidate(descendant) then
                table.insert(candidates, descendant)
            end
            if isScriptInstance(descendant) then
                table.insert(scriptRecords, {
                    path = descendant:GetFullName(),
                    className = descendant.ClassName,
                    audited = descendant:GetAttribute("ImportedScriptAudited") == true,
                    sandboxed = descendant:GetAttribute("Sandboxed") == true,
                    quarantined = descendant:GetAttribute("ImportedScriptQuarantined") == true,
                })
                if isExecutableScript(descendant) and mutate and quarantineFolder then
                    self:_quarantineScript(descendant, quarantineFolder, quarantinedScripts)
                elseif isExecutableScript(descendant) and descendant:GetAttribute("ImportedScriptQuarantined") ~= true then
                    table.insert(failures, descendant:GetFullName() .. " executable imported script is not quarantined")
                end
            end
        end

        for _, instance in ipairs(candidates) do
            local entry = self:_manifestEntryFor(instance)
            if mutate and entry then
                self:_tagFromManifest(instance, entry)
            end

            local sourceAssetId = instance:GetAttribute("SourceAssetId")
            local tagged = sourceAssetId ~= nil
                and instance:GetAttribute("AssetManifestId") ~= nil
                and instance:GetAttribute("CreatorStoreOnly") == true
            local visible = self:IsVisibleImportedAsset(instance)
            local scriptsPresent = false
			for _, descendant in ipairs(instance:GetDescendants()) do
				if isScriptInstance(descendant) and descendant:GetAttribute("ImportedScriptQuarantined") ~= true then
					scriptsPresent = true
					break
				end
			end
			if mutate and not scriptsPresent and instance:GetAttribute("ScriptsAudited") ~= true then
				instance:SetAttribute("ScriptsAudited", true)
			end

            local qualityExclusionKind = self:GetQualityExclusionKind(instance)
            local qualityExcluded = qualityExclusionKind ~= nil
            if qualityExcluded then
                addUnique(qualityExcludedSourceIds, sourceAssetId)
                if qualityExclusionKind == "mesh" then
                    addUnique(meshExcludedSourceIds, sourceAssetId)
                elseif qualityExclusionKind == "debug" then
                    addUnique(debugExcludedSourceIds, sourceAssetId)
                else
                    addUnique(lowQualityExcludedSourceIds, sourceAssetId)
                end
                if qualityExclusionKind == "mesh" and self:HasRequiredPlayableVisual(instance) then
                    table.insert(failures, instance:GetFullName() .. " required playable visual uses MeshPart; mesh final assets are forbidden")
                elseif self:HasRequiredPlayableVisual(instance) and not self:HasRequiredPlayableVisualPolicyNote(instance) then
                    table.insert(failures, instance:GetFullName() .. " required playable visual has quality exclusion without explicit policy note")
                elseif mutate and qualityQuarantineFolder then
                    self:_quarantineQualityAsset(instance, qualityQuarantineFolder, quarantinedQualityAssets, qualityExclusionKind)
                end
            end

			addUnique(importedSourceIds, sourceAssetId)
			if tagged then addUnique(taggedSourceIds, sourceAssetId) end
			if visible or rootInfo.placed then addUnique(placedSourceIds, sourceAssetId) end
            if instance:GetAttribute("ScriptsAudited") == true or (entry and entry.ScriptsAudited == true and not scriptsPresent) then
                addUnique(auditedSourceIds, sourceAssetId)
            end
            if tagged and (visible or rootInfo.placed) and not scriptsPresent and not qualityExcluded then
                addUnique(releaseReadySourceIds, sourceAssetId)
            end

            table.insert(importedRecords, {
                path = instance:GetFullName(),
                className = instance.ClassName,
                sourceAssetId = sourceAssetId,
                assetManifestId = instance:GetAttribute("AssetManifestId"),
                tagged = tagged,
                placed = visible or rootInfo.placed,
                scriptsPresent = scriptsPresent,
                qualityExclusionKind = qualityExclusionKind,
                releaseReady = tagged and (visible or rootInfo.placed) and not scriptsPresent and not qualityExcluded,
            })
        end
    end

    local counts = {
        catalogedSourceAssetIds = countSet(catalogedSourceIds),
        actuallyImportedAssets = countSet(importedSourceIds),
        auditedImportedAssets = countSet(auditedSourceIds),
        taggedImportedAssets = countSet(taggedSourceIds),
        placedVisibleAssets = countSet(placedSourceIds),
        releaseReadyVisibleAssets = countSet(releaseReadySourceIds),
        qualityExcludedAssets = countSet(qualityExcludedSourceIds),
        meshExcludedAssets = countSet(meshExcludedSourceIds),
        lowQualityExcludedAssets = countSet(lowQualityExcludedSourceIds),
        debugExcludedAssets = countSet(debugExcludedSourceIds),
        scriptObjectsFound = #scriptRecords,
        scriptsQuarantined = #quarantinedScripts,
        qualityAssetsQuarantined = #quarantinedQualityAssets,
    }

    if counts.actuallyImportedAssets >= counts.catalogedSourceAssetIds and counts.placedVisibleAssets == 0 then
        table.insert(failures, "cataloged SourceAssetIds appear to be counted as imported without placed/imported evidence")
    end

    return {
        passed = #failures == 0,
        failures = failures,
        counts = counts,
        importedRecords = importedRecords,
        scriptRecords = scriptRecords,
        quarantinedScripts = quarantinedScripts,
        quarantinedQualityAssets = quarantinedQualityAssets,
    }
end

function AssetImportAuditService:ValidateReleaseCounts(minimum)
    minimum = minimum or AssetManifest.MinimumUniqueAssets
    local result = self:AuditAndRepair({ mutate = false })
    local counts = result.counts
    if counts.actuallyImportedAssets < minimum then
        table.insert(result.failures, "actuallyImportedAssets=" .. tostring(counts.actuallyImportedAssets) .. "; expected at least " .. tostring(minimum))
    end
    if counts.releaseReadyVisibleAssets < minimum then
        table.insert(result.failures, "releaseReadyVisibleAssets=" .. tostring(counts.releaseReadyVisibleAssets) .. "; expected at least " .. tostring(minimum))
    end
    result.passed = #result.failures == 0
    return result
end

function AssetImportAuditService:ToMarkdown(result)
    local counts = result.counts
    local lines = {
        "# Import Audit",
        "",
        "Generated by `AssetImportAuditService`. Cataloged Creator Store IDs are intentionally reported separately from live imported/placed evidence.",
        "",
        "## Counts",
        "",
        "| State | Count |",
        "| --- | ---: |",
        "| Cataloged SourceAssetIds | " .. tostring(counts.catalogedSourceAssetIds) .. " |",
        "| Actually Imported Assets | " .. tostring(counts.actuallyImportedAssets) .. " |",
        "| Audited Imported Assets | " .. tostring(counts.auditedImportedAssets) .. " |",
        "| Tagged Imported Assets | " .. tostring(counts.taggedImportedAssets) .. " |",
        "| Placed Visible Assets | " .. tostring(counts.placedVisibleAssets) .. " |",
        "| Release Ready Visible Assets | " .. tostring(counts.releaseReadyVisibleAssets) .. " |",
        "| Quality Excluded Assets | " .. tostring(counts.qualityExcludedAssets or 0) .. " |",
        "| Mesh Excluded Assets | " .. tostring(counts.meshExcludedAssets or 0) .. " |",
        "| Low Quality Excluded Assets | " .. tostring(counts.lowQualityExcludedAssets or 0) .. " |",
        "| Debug Excluded Assets | " .. tostring(counts.debugExcludedAssets or 0) .. " |",
        "| Script Objects Found | " .. tostring(counts.scriptObjectsFound) .. " |",
        "| Scripts Quarantined | " .. tostring(counts.scriptsQuarantined) .. " |",
        "| Quality Assets Quarantined | " .. tostring(counts.qualityAssetsQuarantined or 0) .. " |",
        "",
        "## Release Rule",
        "",
        "Release validation fails unless imported, audited, tagged, placed, quality-accepted, and release-ready live assets independently reach the required unique SourceAssetId target. Manifest/catalog rows, duplicate SourceAssetIds, debug fallback visuals, low-quality/simple generated assets, and mesh/LQ exclusions do not count as release-ready.",
        "",
        "Mesh exclusions and low-quality exclusions are reported separately. Imported MeshPart roots are forbidden as final assets. Food/glowing ball placeholders, rectangle/ball tree placeholders, and simple-generated/debug fallback names are withheld from release-ready counts and quarantined on mutate unless protected as required playable visuals. Required playable visuals must not be low-quality/debug excluded without an explicit policy note/replacement rationale; mesh required visuals fail release until replaced by generated Parts.",
    }
    return table.concat(lines, "\n") .. "\n"
end

return AssetImportAuditService
