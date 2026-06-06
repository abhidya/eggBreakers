local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local PerformanceAuditService = require(game:GetService("ServerScriptService").Services.PerformanceAuditService)

local suite = { name = "AssetCollisionBudgetTest", category = "Performance", tests = {} }

local function stampG032RuntimeKeepScript(scriptObject)
    scriptObject:SetAttribute("ImportedScriptAudited", true)
    scriptObject:SetAttribute("ImportedScriptAdapted", true)
    scriptObject:SetAttribute("ScriptAdaptedTo", "eggBreakers runtime import adapter")
    scriptObject:SetAttribute("ImportedScriptStamped", true)
    scriptObject:SetAttribute("ImportedScriptOwner", "PerformanceAuditService")
    scriptObject:SetAttribute("ScriptAuditPurpose", "adapted G032 runtime behavior only")
    scriptObject:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
    scriptObject:SetAttribute("ScriptAuditDecision", "keep")
    scriptObject:SetAttribute("ScriptAuditScope", "G032")
end

local function withIsolatedImportedRuntimeFixture(callback)
    local realMap = Workspace:FindFirstChild("Map")
    if realMap then
        realMap.Name = "_RealMap_PerformanceImportedRuntime"
    end
    local realLibrary = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if realLibrary then
        realLibrary.Name = "_RealImportedAssetLibrary_PerformanceImportedRuntime"
    end

    local map = Instance.new("Folder")
    map.Name = "Map"
    map.Parent = Workspace
    local importedAssets = Instance.new("Folder")
    importedAssets.Name = "ImportedAssets"
    importedAssets.Parent = map

    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local ok, result = pcall(callback, importedAssets, library)

    map:Destroy()
    library:Destroy()
    if realMap then
        realMap.Name = "Map"
    end
    if realLibrary then
        realLibrary.Name = "ImportedAssetLibrary"
    end

    if not ok then error(result, 2) end
    return result
end

table.insert(suite.tests, { name = "decorative collision touch query disabled where safe", run = function()
    local result = PerformanceAuditService:Scan()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
end })

table.insert(suite.tests, { name = "asset collision budgets are explicit", run = function()
    Assert.truthy(PerformanceAuditService.MaxDecorativeCollidableParts <= 40, "decorative collision cap must stay tight")
    Assert.truthy(PerformanceAuditService.MaxImportedPartsWithTouch <= 25, "touch-enabled imported part cap must stay tight")
end })

table.insert(suite.tests, { name = "G032 keep runtime script fixture is counted as allowed", run = function()
    withIsolatedImportedRuntimeFixture(function(importedAssets)
        local fixture = Instance.new("Model")
        fixture.Name = "G032AllowedRuntimeFixture"
        fixture.Parent = importedAssets

        local scriptObject = Instance.new("Script")
        scriptObject.Name = "AdaptedRuntimeBehavior"
        stampG032RuntimeKeepScript(scriptObject)
        scriptObject.Parent = fixture

        local result = PerformanceAuditService:Scan()
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(result.importedRuntimeScriptCount, 0, "G032 keep runtime script is not counted as disallowed")
        Assert.equals(result.allowedImportedRuntimeScriptCount, 1, "G032 keep runtime script is counted as allowed")
    end)
end })

return TestRunner.registerSuite(suite)
