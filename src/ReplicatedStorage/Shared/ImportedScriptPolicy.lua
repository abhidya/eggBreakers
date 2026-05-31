local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImportedScriptPolicy = {}

ImportedScriptPolicy.RawReviewStatus = "raw_preserved_pending_adaptation"
ImportedScriptPolicy.ModuleQuarantineStatus = "module_preserved_pending_adaptation"
ImportedScriptPolicy.QuarantineFolderName = "ImportedScriptQuarantine"

function ImportedScriptPolicy.HasStringAttribute(instance, attributeName)
    local value = instance:GetAttribute(attributeName)
    return type(value) == "string" and value ~= ""
end

function ImportedScriptPolicy.HasAncestorAttribute(instance, attributeName, expectedValue)
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

function ImportedScriptPolicy.IsScriptContainer(instance)
    return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

function ImportedScriptPolicy.IsExecutableScript(instance)
    return instance:IsA("Script") or instance:IsA("LocalScript")
end

function ImportedScriptPolicy.IsEnabledExecutableScript(instance)
    return ImportedScriptPolicy.IsExecutableScript(instance) and instance.Disabled ~= true
end

function ImportedScriptPolicy.IsRawScriptReviewQueue(instance)
    return ImportedScriptPolicy.HasAncestorAttribute(instance, "RawImportedScriptPreserved", true)
        or ImportedScriptPolicy.HasAncestorAttribute(instance, "G032RawScriptPreserved", true)
        or ImportedScriptPolicy.HasAncestorAttribute(instance, "ImportedScriptReviewQueue", true)
        or ImportedScriptPolicy.HasAncestorAttribute(instance, "ScriptReviewStatus", ImportedScriptPolicy.RawReviewStatus)
end

function ImportedScriptPolicy.IsReviewedAdaptedStampedScript(instance)
    local reviewed = instance:GetAttribute("ImportedScriptAudited") == true
        or instance:GetAttribute("ReviewedImportedScript") == true
    local adapted = (
            instance:GetAttribute("ImportedScriptAdapted") == true
            or instance:GetAttribute("AdaptedIntoEggBreakers") == true
        )
        and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptAdaptedTo")
    local stamped = instance:GetAttribute("ImportedScriptStamped") == true
        and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptAuditPurpose")
        and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptSandboxStatus")
        and ImportedScriptPolicy.HasStringAttribute(instance, "ImportedScriptOwner")
        and instance:GetAttribute("ScriptAuditDecision") == "keep"
        and instance:GetAttribute("ScriptAuditScope") == "G032"
    return reviewed and adapted and stamped
end

function ImportedScriptPolicy.IsReleaseReadyScript(instance)
    if ImportedScriptPolicy.IsExecutableScript(instance) then
        return ImportedScriptPolicy.IsReviewedAdaptedStampedScript(instance)
    end
    return instance:IsA("ModuleScript")
        and ImportedScriptPolicy.IsReviewedAdaptedStampedScript(instance)
        and instance:GetAttribute("Sandboxed") == true
end

function ImportedScriptPolicy.IsDisabledRawRuntimeReviewScript(instance)
    return ImportedScriptPolicy.IsRawScriptReviewQueue(instance)
        and ImportedScriptPolicy.IsExecutableScript(instance)
        and instance.Disabled == true
end

function ImportedScriptPolicy.StampRawReviewRoot(instance, sourceUse)
    if not instance then return end
    instance:SetAttribute("RawImportedScriptPreserved", true)
    instance:SetAttribute("G032RawScriptPreserved", true)
    instance:SetAttribute("ImportedScriptReviewQueue", true)
    instance:SetAttribute("ImportedScriptPreservedForReview", true)
    instance:SetAttribute("ScriptReviewStatus", ImportedScriptPolicy.RawReviewStatus)
    instance:SetAttribute("ScriptAuditScope", "G032")
    if type(sourceUse) == "string" and sourceUse ~= "" then
        instance:SetAttribute("ImportedScriptSourceUse", sourceUse)
    end
end

function ImportedScriptPolicy.StampRawRuntimeForReview(instance, sourceUse, root)
    if not ImportedScriptPolicy.IsExecutableScript(instance) then return false end
    instance.Disabled = true
    ImportedScriptPolicy.StampRawReviewRoot(root or instance.Parent, sourceUse)
    instance:SetAttribute("RawImportedScriptPreserved", true)
    instance:SetAttribute("G032RawScriptPreserved", true)
    instance:SetAttribute("ImportedScriptReviewQueue", true)
    instance:SetAttribute("ImportedScriptPreservedForReview", true)
    instance:SetAttribute("ScriptReviewStatus", ImportedScriptPolicy.RawReviewStatus)
    instance:SetAttribute("ScriptAuditScope", "G032")
    if type(sourceUse) == "string" and sourceUse ~= "" then
        instance:SetAttribute("ImportedScriptSourceUse", sourceUse)
    end
    return true
end

function ImportedScriptPolicy.EnsureQuarantineFolder()
    local folder = ReplicatedStorage:FindFirstChild(ImportedScriptPolicy.QuarantineFolderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = ImportedScriptPolicy.QuarantineFolderName
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function ImportedScriptPolicy.QuarantineRawModule(instance, sourceUse)
    if not instance:IsA("ModuleScript") then return false end
    if ImportedScriptPolicy.IsReleaseReadyScript(instance) then
        instance:SetAttribute("ImportedScriptPreserved", true)
        return true
    end

    local quarantineFolder = ImportedScriptPolicy.EnsureQuarantineFolder()
    instance:SetAttribute("ImportedScriptQuarantined", true)
    instance:SetAttribute("ImportedScriptPreservedForReview", true)
    instance:SetAttribute("ScriptReviewStatus", ImportedScriptPolicy.ModuleQuarantineStatus)
    instance:SetAttribute("ScriptAuditScope", "G032")
    if type(sourceUse) == "string" and sourceUse ~= "" then
        instance:SetAttribute("ImportedScriptSourceUse", sourceUse)
    end
    instance:SetAttribute("QuarantinedFrom", instance:GetFullName())
    instance.Parent = quarantineFolder
    return true
end

function ImportedScriptPolicy.PreserveOrQuarantineCloneScript(instance, sourceUse, root)
    if not ImportedScriptPolicy.IsScriptContainer(instance) then
        return false
    end
    if ImportedScriptPolicy.IsReleaseReadyScript(instance) then
        instance:SetAttribute("ImportedScriptPreserved", true)
        return true
    end
    if ImportedScriptPolicy.IsExecutableScript(instance) then
        return ImportedScriptPolicy.StampRawRuntimeForReview(instance, sourceUse, root)
    end
    return ImportedScriptPolicy.QuarantineRawModule(instance, sourceUse)
end

function ImportedScriptPolicy.BuildRecord(instance)
    return {
        path = instance:GetFullName(),
        className = instance.ClassName,
        audited = instance:GetAttribute("ImportedScriptAudited") == true,
        reviewed = instance:GetAttribute("ImportedScriptAudited") == true
            or instance:GetAttribute("ReviewedImportedScript") == true,
        adapted = (
                instance:GetAttribute("ImportedScriptAdapted") == true
                or instance:GetAttribute("AdaptedIntoEggBreakers") == true
            )
            and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptAdaptedTo"),
        stamped = instance:GetAttribute("ImportedScriptStamped") == true
            and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptAuditPurpose")
            and ImportedScriptPolicy.HasStringAttribute(instance, "ScriptSandboxStatus")
            and ImportedScriptPolicy.HasStringAttribute(instance, "ImportedScriptOwner")
            and instance:GetAttribute("ScriptAuditDecision") == "keep"
            and instance:GetAttribute("ScriptAuditScope") == "G032",
        sandboxed = instance:GetAttribute("Sandboxed") == true,
        quarantined = instance:GetAttribute("ImportedScriptQuarantined") == true,
        rawReview = ImportedScriptPolicy.IsRawScriptReviewQueue(instance),
        rawExecutableEnabled = ImportedScriptPolicy.IsRawScriptReviewQueue(instance)
            and ImportedScriptPolicy.IsEnabledExecutableScript(instance),
        releaseReadyScript = ImportedScriptPolicy.IsReleaseReadyScript(instance),
        scriptAdaptedTo = instance:GetAttribute("ScriptAdaptedTo"),
        scriptAuditDecision = instance:GetAttribute("ScriptAuditDecision"),
        scriptAuditScope = instance:GetAttribute("ScriptAuditScope"),
    }
end

return ImportedScriptPolicy
