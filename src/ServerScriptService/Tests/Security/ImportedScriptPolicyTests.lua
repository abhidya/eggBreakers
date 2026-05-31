local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "ImportedScriptPolicyTests.server", category = "Security", tests = {} }

local function stampReviewedAdaptedScript(scriptObject)
    scriptObject:SetAttribute("ImportedScriptAudited", true)
    scriptObject:SetAttribute("ImportedScriptAdapted", true)
    scriptObject:SetAttribute("ImportedScriptStamped", true)
    scriptObject:SetAttribute("ImportedScriptOwner", "SecurityAuditService")
    scriptObject:SetAttribute("ScriptAuditPurpose", "adapted local ambience only")
    scriptObject:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
end

local function withImportedLibrary(callback)
    local existing = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if existing then
        existing.Name = "_RealImportedAssetLibrary_ImportedScriptPolicy"
    end

    local map = Workspace:FindFirstChild("Map")
    local realMapAssets = map and map:FindFirstChild("ImportedAssets")
    if realMapAssets then
        realMapAssets.Name = "_RealImportedAssets_ImportedScriptPolicy"
    end

    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local ok, result = pcall(callback, library)

    library:Destroy()

    if existing then
        existing.Name = "ImportedAssetLibrary"
    end
    if realMapAssets then
        realMapAssets.Name = "ImportedAssets"
    end

    if not ok then
        error(result, 2)
    end
    return result
end

table.insert(suite.tests, { name = "unaudited imported runtime scripts require quarantine", run = function()
    withImportedLibrary(function(library)
        local scriptAsset = Instance.new("Script")
        scriptAsset.Name = "ImportedVendorRuntime"
        scriptAsset:SetAttribute("TestImportedScriptPolicy", true)
        scriptAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(result.passed, "runtime Script under ImportedAssetLibrary must fail audit")
        Assert.equals(#result.quarantineRecommended, 1, "runtime imported script recommended for quarantine")
    end)
end })

table.insert(suite.tests, { name = "reviewed adapted sandboxed module scripts may be preserved", run = function()
    withImportedLibrary(function(library)
        local moduleAsset = Instance.new("ModuleScript")
        moduleAsset.Name = "ImportedSafeUtility"
        moduleAsset:SetAttribute("TestImportedScriptPolicy", true)
        moduleAsset:SetAttribute("Sandboxed", true)
        stampReviewedAdaptedScript(moduleAsset)
        moduleAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(#result.preserved, 1, "reviewed adapted sandboxed module preserved")
        Assert.equals(#result.quarantineRecommended, 0, "no quarantine for reviewed adapted sandboxed module")
    end)
end })

table.insert(suite.tests, { name = "sandboxed module scripts without adaptation stamp require quarantine", run = function()
    withImportedLibrary(function(library)
        local moduleAsset = Instance.new("ModuleScript")
        moduleAsset.Name = "ImportedSandboxedButUnadaptedUtility"
        moduleAsset:SetAttribute("ImportedScriptAudited", true)
        moduleAsset:SetAttribute("Sandboxed", true)
        moduleAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(result.passed, "sandboxed unadapted module must still fail audit")
        Assert.equals(#result.quarantineRecommended, 1, "unadapted module recommended for quarantine")
    end)
end })

table.insert(suite.tests, { name = "reviewed adapted stamped runtime scripts may be preserved", run = function()
    withImportedLibrary(function(library)
        local scriptAsset = Instance.new("Script")
        scriptAsset.Name = "ImportedReviewedRuntime"
        scriptAsset:SetAttribute("TestImportedScriptPolicy", true)
        stampReviewedAdaptedScript(scriptAsset)
        scriptAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(#result.preserved, 1, "reviewed adapted stamped runtime script preserved")
        Assert.equals(#result.quarantineRecommended, 0, "no quarantine for reviewed adapted stamped runtime")
    end)
end })

table.insert(suite.tests, { name = "reviewed runtime scripts without adaptation stamp require quarantine", run = function()
    withImportedLibrary(function(library)
        local scriptAsset = Instance.new("Script")
        scriptAsset.Name = "ImportedReviewedButUnadaptedRuntime"
        scriptAsset:SetAttribute("TestImportedScriptPolicy", true)
        scriptAsset:SetAttribute("ImportedScriptAudited", true)
        scriptAsset:SetAttribute("ImportedScriptStamped", true)
        scriptAsset:SetAttribute("ImportedScriptOwner", "SecurityAuditService")
        scriptAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(result.passed, "unadapted reviewed runtime script must still fail audit")
        Assert.equals(#result.quarantineRecommended, 1, "unadapted runtime script recommended for quarantine")
    end)
end })

TestRunner.registerSuite(suite)
return suite
