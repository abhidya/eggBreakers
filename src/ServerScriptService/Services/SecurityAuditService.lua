local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetImportAuditService = require(script.Parent.AssetImportAuditService)
local ImportedScriptPolicy = require(ReplicatedStorage.Shared.ImportedScriptPolicy)

local SecurityAuditService = {}

local IMPORTED_LIBRARY_NAMES = {
    ImportedAssets = true,
    ImportedAssetLibrary = true,
}


function SecurityAuditService:GetImportedAssetStateCounts(options)
    return AssetImportAuditService:AuditAndRepair(options).counts
end

function SecurityAuditService:ValidateImportedAssetReleaseGate(minimum)
    return AssetImportAuditService:ValidateReleaseCounts(minimum)
end

function SecurityAuditService:AssertRejected(ok, before, after)
    return ok == false and before == after
end

function SecurityAuditService:ExploitResult(ok, changed)
    return { rejected = ok == false, noStateChange = changed == false, passed = ok == false and changed == false }
end

function SecurityAuditService:_isImportedRoot(instance)
    return instance and IMPORTED_LIBRARY_NAMES[instance.Name] == true
end

function SecurityAuditService:_isImportedDescendant(instance)
    local current = instance
    while current do
        if self:_isImportedRoot(current) then
            return true
        end
        current = current.Parent
    end
    return false
end

function SecurityAuditService:_isScriptContainer(instance)
    return ImportedScriptPolicy.IsScriptContainer(instance)
end

function SecurityAuditService:_hasStringAttribute(instance, attributeName)
    return ImportedScriptPolicy.HasStringAttribute(instance, attributeName)
end

function SecurityAuditService:_hasAncestorAttribute(instance, attributeName, expectedValue)
    return ImportedScriptPolicy.HasAncestorAttribute(instance, attributeName, expectedValue)
end

function SecurityAuditService:_isRawScriptReviewQueue(instance)
    return ImportedScriptPolicy.IsRawScriptReviewQueue(instance)
end

function SecurityAuditService:_isReviewedAdaptedStamped(instance)
    return ImportedScriptPolicy.IsReviewedAdaptedStampedScript(instance)
end

function SecurityAuditService:_isEnabledExecutable(instance)
    return ImportedScriptPolicy.IsEnabledExecutableScript(instance)
end

function SecurityAuditService:_scanRoots()
    local roots = {}
    local map = Workspace:FindFirstChild("Map")
    if map then
        table.insert(roots, map)
    else
        table.insert(roots, Workspace)
    end

    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        table.insert(roots, library)
    end

    return roots
end

function SecurityAuditService:ScanImportedScripts()
    local failures = {}
    local discovered = {}
    local preserved = {}
    local preservedForReview = {}
    local quarantineRecommended = {}

    for _, root in ipairs(self:_scanRoots()) do
        for _, instance in ipairs(root:GetDescendants()) do
            if self:_isScriptContainer(instance) and self:_isImportedDescendant(instance) then
                local rawReview = self:_isRawScriptReviewQueue(instance)
                local record = ImportedScriptPolicy.BuildRecord(instance)
                table.insert(discovered, record)

                if record.releaseReadyScript then
                    table.insert(preserved, record)
                elseif rawReview and instance:IsA("ModuleScript") then
                    table.insert(quarantineRecommended, record)
                    table.insert(failures, record.path .. " raw queued ModuleScript must be reviewed, adapted, stamped, and Sandboxed=true before preservation")
                elseif rawReview and record.rawExecutableEnabled then
                    table.insert(quarantineRecommended, record)
                    table.insert(failures, record.path .. " raw review queued executable script is enabled; disable before preserving for review")
                elseif rawReview then
                    table.insert(preservedForReview, record)
                else
                    table.insert(quarantineRecommended, record)
                    if instance:IsA("Script") or instance:IsA("LocalScript") then
                        table.insert(failures, record.path .. " is executable imported code; review/adapt/stamp it or quarantine it outside runtime roots")
                    elseif not self:_isReviewedAdaptedStamped(instance) then
                        table.insert(failures, record.path .. " imported ModuleScript lacks reviewed/adapted/stamped metadata")
                    elseif not record.sandboxed then
                        table.insert(failures, record.path .. " imported ModuleScript lacks Sandboxed=true")
                    end
                end
            end
        end
    end

    return {
        passed = #failures == 0,
        failures = failures,
        discovered = discovered,
        preserved = preserved,
        preservedForReview = preservedForReview,
        quarantineRecommended = quarantineRecommended,
    }
end

return SecurityAuditService
