local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)

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
    if not AssetManifest.GetById(manifestId) then
        table.insert(failures, instance:GetFullName() .. " references unknown AssetManifestId " .. tostring(manifestId))
    end
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
