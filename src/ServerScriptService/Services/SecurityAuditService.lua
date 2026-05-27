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
    local quarantineRecommended = {}

    for _, root in ipairs(self:_scanRoots()) do
        for _, instance in ipairs(root:GetDescendants()) do
            if self:_isScriptContainer(instance) and self:_isImportedDescendant(instance) then
                local record = {
                    path = instance:GetFullName(),
                    className = instance.ClassName,
                    audited = instance:GetAttribute("ImportedScriptAudited") == true,
                    sandboxed = instance:GetAttribute("Sandboxed") == true,
                }
                table.insert(discovered, record)

                if instance:IsA("ModuleScript") and record.audited and record.sandboxed then
                    table.insert(preserved, record)
                else
                    table.insert(quarantineRecommended, record)
                    if instance:IsA("Script") or instance:IsA("LocalScript") then
                        table.insert(failures, record.path .. " is executable imported code; remove or quarantine it outside runtime roots")
                    elseif not record.audited then
                        table.insert(failures, record.path .. " imported ModuleScript lacks ImportedScriptAudited=true")
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
        quarantineRecommended = quarantineRecommended,
    }
end

return SecurityAuditService
