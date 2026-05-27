local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)

local AssetImportAuditService = {}

AssetImportAuditService.ImportedLibraryName = "ImportedAssetLibrary"
AssetImportAuditService.WorkspaceImportedPath = { "Map", "ImportedAssets" }
AssetImportAuditService.QuarantineFolderName = "ImportedScriptQuarantine"

local SCRIPT_CLASS_NAMES = {
    Script = true,
    LocalScript = true,
    ModuleScript = true,
}

local EXECUTABLE_CLASS_NAMES = {
    Script = true,
    LocalScript = true,
}

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
    local catalogedSourceIds = {}
    local importedSourceIds = {}
    local auditedSourceIds = {}
    local taggedSourceIds = {}
    local placedSourceIds = {}
    local releaseReadySourceIds = {}

    for _, entry in ipairs(AssetManifest.Entries) do
        addUnique(catalogedSourceIds, entry.SourceAssetId)
    end

    local quarantineFolder = nil
    if mutate then
        quarantineFolder = self:_ensureQuarantineFolder()
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

			addUnique(importedSourceIds, sourceAssetId)
			if tagged then addUnique(taggedSourceIds, sourceAssetId) end
			if visible or rootInfo.placed then addUnique(placedSourceIds, sourceAssetId) end
            if instance:GetAttribute("ScriptsAudited") == true or (entry and entry.ScriptsAudited == true and not scriptsPresent) then
                addUnique(auditedSourceIds, sourceAssetId)
            end
            if tagged and (visible or rootInfo.placed) and not scriptsPresent then
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
                releaseReady = tagged and (visible or rootInfo.placed) and not scriptsPresent,
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
        scriptObjectsFound = #scriptRecords,
        scriptsQuarantined = #quarantinedScripts,
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
        "| Script Objects Found | " .. tostring(counts.scriptObjectsFound) .. " |",
        "| Scripts Quarantined | " .. tostring(counts.scriptsQuarantined) .. " |",
        "",
        "## Release Rule",
        "",
        "Release validation fails unless imported, audited, tagged, placed, and release-ready live assets independently reach the required unique SourceAssetId target. Manifest/catalog rows alone do not count as imported.",
    }
    return table.concat(lines, "\n") .. "\n"
end

return AssetImportAuditService
