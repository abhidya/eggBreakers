local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(script.Parent.AssetImportAuditService)

local AssetAuditService = {}
AssetAuditService.ForbiddenVisibleNameSignals = { "Placeholder", "Temp", "TODO", "Graybox", "Blockout", "TestCube", "ReplaceMe" }
AssetAuditService.AllowedInvisibleParents = { "InvisibleGameplayVolumes", "NPCSpawns", "Nests", "Fossils", "SpawnLocations" }

function AssetAuditService:IsVisibleInstance(instance)
    if not instance:IsA("BasePart") then return false end
    return instance.Transparency < 1
end

function AssetAuditService:IsInvisibleHelper(instance)
    if not instance:IsA("BasePart") then return false end
    if instance.Transparency ~= 1 then return false end
    if self:IsCreatorStoreDerived(instance) then return true end
    if string.sub(instance.Name, 1, 11) ~= "_INVISIBLE_" then return false end
    local parentName = instance.Parent and instance.Parent.Name or ""
    for _, allowed in ipairs(self.AllowedInvisibleParents) do
        if parentName == allowed then return true end
    end
    return false
end

function AssetAuditService:IsCreatorStoreDerived(instance)
    local current = instance
    while current do
        if current:GetAttribute("CreatorStoreOnly") then return true end
        current = current.Parent
    end
    return false
end

function AssetAuditService:HasForbiddenVisibleName(instance)
    for _, signal in ipairs(self.ForbiddenVisibleNameSignals) do
        if string.find(string.lower(instance.Name), string.lower(signal), 1, true) then return true end
    end
    return false
end

function AssetAuditService:ValidateManifest(minimum)
    return AssetManifest.Validate({ minimum = minimum or AssetManifest.MinimumUniqueAssets })
end

function AssetAuditService:ValidateManifestReference(instance, failures)
    local manifestId = instance:GetAttribute("AssetManifestId")
    if manifestId == nil then
        table.insert(failures, instance:GetFullName() .. " visible imported asset lacks AssetManifestId attribute")
        return
    end
    local entry = AssetManifest.GetById(manifestId)
    if not entry then
        table.insert(failures, instance:GetFullName() .. " references unknown AssetManifestId " .. tostring(manifestId))
        return
    end

    local sourceAssetId = instance:GetAttribute("SourceAssetId")
    if sourceAssetId ~= nil and tostring(sourceAssetId) ~= entry.SourceAssetId then
        table.insert(failures, instance:GetFullName() .. " SourceAssetId does not match manifest entry " .. tostring(manifestId))
    end
    if instance:GetAttribute("ImportedScriptsPresent") == true then
        table.insert(failures, instance:GetFullName() .. " still contains imported scripts after catalog audit")
    end
    if entry.ImportedScriptsPresent or entry.ScriptsAudited ~= true then
        table.insert(failures, instance:GetFullName() .. " references unaudited imported script state in manifest")
    end
    if not AssetManifest.AllowedScriptSandboxStatuses[entry.ScriptSandboxStatus] then
        table.insert(failures, instance:GetFullName() .. " references unsupported manifest script sandbox status")
    end
end


function AssetAuditService:GetAssetStateCounts(options)
    return AssetImportAuditService:AuditAndRepair(options).counts
end

function AssetAuditService:ValidateReleaseImportReadiness(minimum)
    return AssetImportAuditService:ValidateReleaseCounts(minimum)
end

function AssetAuditService:ScanWorkspace()
    local failures = {}
    local visibleCount = 0
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if self:IsVisibleInstance(instance) then
            visibleCount = visibleCount + 1
            if self:HasForbiddenVisibleName(instance) then
                table.insert(failures, instance:GetFullName() .. " has forbidden placeholder-like name")
            end
            if instance:IsA("Part") and instance.Shape == Enum.PartType.Block and not self:IsCreatorStoreDerived(instance) then
                table.insert(failures, instance:GetFullName() .. " is visible default block Part not marked Creator Store-derived")
            end
            if instance:GetAttribute("ImportedVisibleAsset") == true then
                self:ValidateManifestReference(instance, failures)
            end
        elseif instance:IsA("BasePart") and instance.Transparency == 1 and not self:IsInvisibleHelper(instance) then
            table.insert(failures, instance:GetFullName() .. " invisible helper violates naming/storage rule")
        end
    end
    return { visibleCount = visibleCount, failures = failures, passed = #failures == 0 }
end

return AssetAuditService
