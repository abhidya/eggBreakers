local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "ImportedScriptPolicyTests.server", category = "Security", tests = {} }

local function withImportedLibrary(callback)
    local existing = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    local library = existing or Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local ok, result = pcall(callback, library)

    if existing then
        for _, child in ipairs(library:GetChildren()) do
            if child:GetAttribute("TestImportedScriptPolicy") == true then
                child:Destroy()
            end
        end
    else
        library:Destroy()
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

table.insert(suite.tests, { name = "audited sandboxed module scripts may be preserved", run = function()
    withImportedLibrary(function(library)
        local moduleAsset = Instance.new("ModuleScript")
        moduleAsset.Name = "ImportedSafeUtility"
        moduleAsset:SetAttribute("TestImportedScriptPolicy", true)
        moduleAsset:SetAttribute("ImportedScriptAudited", true)
        moduleAsset:SetAttribute("Sandboxed", true)
        moduleAsset.Parent = library

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(#result.preserved, 1, "audited sandboxed module preserved")
        Assert.equals(#result.quarantineRecommended, 0, "no quarantine for audited sandboxed module")
    end)
end })

TestRunner.registerSuite(suite)
return suite
