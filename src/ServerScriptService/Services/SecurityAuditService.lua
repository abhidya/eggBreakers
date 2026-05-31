local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetImportAuditService = require(script.Parent.AssetImportAuditService)

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
    return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

function SecurityAuditService:_hasStringAttribute(instance, attributeName)
    local value = instance:GetAttribute(attributeName)
    return type(value) == "string" and value ~= ""
end

function SecurityAuditService:_hasAncestorAttribute(instance, attributeName, expectedValue)
    local current = instance
    while current do
        local value = current:GetAttribute(attributeName)
        if expectedValue == nil then
            if value ~= nil then return true end
        elseif value == expectedValue then
            return true
        end
        current = current.Parent
    end
    return false
end

function SecurityAuditService:_isRawScriptReviewQueue(instance)
    return self:_hasAncestorAttribute(instance, "RawImportedScriptPreserved", true)
        or self:_hasAncestorAttribute(instance, "G032RawScriptPreserved", true)
        or self:_hasAncestorAttribute(instance, "ImportedScriptReviewQueue", true)
        or self:_hasAncestorAttribute(instance, "ScriptReviewStatus", "raw_preserved_pending_adaptation")
end

function SecurityAuditService:_isReviewedAdaptedStamped(instance)
    local reviewed = instance:GetAttribute("ImportedScriptAudited") == true
        or instance:GetAttribute("ReviewedImportedScript") == true
    local adapted = instance:GetAttribute("ImportedScriptAdapted") == true
        or instance:GetAttribute("AdaptedIntoEggBreakers") == true
        or self:_hasStringAttribute(instance, "ScriptAdaptedTo")
    local stamped = instance:GetAttribute("ImportedScriptStamped") == true
        or (
            self:_hasStringAttribute(instance, "ScriptAuditPurpose")
            and self:_hasStringAttribute(instance, "ScriptSandboxStatus")
            and self:_hasStringAttribute(instance, "ImportedScriptOwner")
        )
    return reviewed and adapted and stamped
end

function SecurityAuditService:_isEnabledExecutable(instance)
    return (instance:IsA("Script") or instance:IsA("LocalScript")) and instance.Disabled ~= true
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
                local record = {
                    path = instance:GetFullName(),
                    className = instance.ClassName,
                    audited = instance:GetAttribute("ImportedScriptAudited") == true,
                    reviewed = instance:GetAttribute("ImportedScriptAudited") == true
                        or instance:GetAttribute("ReviewedImportedScript") == true,
                    adapted = instance:GetAttribute("ImportedScriptAdapted") == true
                        or instance:GetAttribute("AdaptedIntoEggBreakers") == true
                        or self:_hasStringAttribute(instance, "ScriptAdaptedTo"),
                    stamped = instance:GetAttribute("ImportedScriptStamped") == true
                        or (
                            self:_hasStringAttribute(instance, "ScriptAuditPurpose")
                            and self:_hasStringAttribute(instance, "ScriptSandboxStatus")
                            and self:_hasStringAttribute(instance, "ImportedScriptOwner")
                    ),
                    sandboxed = instance:GetAttribute("Sandboxed") == true,
                    rawReview = rawReview,
                    rawExecutableEnabled = rawReview and self:_isEnabledExecutable(instance),
                    scriptAuditScope = instance:GetAttribute("ScriptAuditScope"),
                }
                table.insert(discovered, record)

                if rawReview and record.rawExecutableEnabled then
                    table.insert(quarantineRecommended, record)
                    table.insert(failures, record.path .. " raw review queued executable script is enabled; disable before preserving for review")
                elseif rawReview then
                    table.insert(preservedForReview, record)
                elseif instance:IsA("ModuleScript") and self:_isReviewedAdaptedStamped(instance) and record.sandboxed then
                    table.insert(preserved, record)
                elseif (instance:IsA("Script") or instance:IsA("LocalScript")) and self:_isReviewedAdaptedStamped(instance) then
                    table.insert(preserved, record)
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
