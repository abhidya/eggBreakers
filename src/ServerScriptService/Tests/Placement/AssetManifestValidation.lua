local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetAuditService = require(game:GetService("ServerScriptService").Services.AssetAuditService)

local suite = { name = "AssetManifestValidation", category = "Placement", tests = {} }

local function withTemporaryManifestEntry(scriptSandboxStatus, callback)
    local entry = {
        AssetId = "TestManifestScriptState_" .. scriptSandboxStatus,
        SourceAssetId = "900000" .. tostring(#AssetManifest.Entries + 1),
        ImportedScriptsPresent = true,
        ScriptsAudited = true,
        ScriptSandboxStatus = scriptSandboxStatus,
    }
    table.insert(AssetManifest.Entries, entry)
    local ok, result = pcall(callback, entry)
    table.remove(AssetManifest.Entries)
    if not ok then error(result, 2) end
    return result
end

local function makeVisibleImportedManifestReference(entry)
    local model = Instance.new("Model")
    model.Name = "ManifestReference" .. entry.ScriptSandboxStatus
    model:SetAttribute("ImportedVisibleAsset", true)
    model:SetAttribute("ImportedScriptsPresent", true)
    model:SetAttribute("AssetManifestId", entry.AssetId)
    model:SetAttribute("SourceAssetId", entry.SourceAssetId)
    return model
end

local function stampReviewedAdaptedScript(scriptObject)
    scriptObject:SetAttribute("ImportedScriptAudited", true)
    scriptObject:SetAttribute("ImportedScriptAdapted", true)
    scriptObject:SetAttribute("ScriptAdaptedTo", "eggBreakers imported asset adapter")
    scriptObject:SetAttribute("ImportedScriptStamped", true)
    scriptObject:SetAttribute("ImportedScriptOwner", "AssetAuditService")
    scriptObject:SetAttribute("ScriptAuditPurpose", "adapted manifest reference fixture")
    scriptObject:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
    scriptObject:SetAttribute("ScriptAuditDecision", "keep")
    scriptObject:SetAttribute("ScriptAuditScope", "G032")
end

table.insert(suite.tests, { name = "asset import manifest has 500 unique Creator Store source ids", run = function()
    local result = AssetManifest.Validate({ minimum = 500 })
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.equals(result.total, 500, "G011 manifest entry count")
    Assert.equals(result.uniqueAssetIds, 500, "G011 unique local AssetId count")
    Assert.equals(result.uniqueSourceAssetIds, 500, "G011 unique Creator Store SourceAssetId count")
    Assert.truthy(result.finalCount >= 500, "G011 entries are final Creator Store catalog records")
end })

table.insert(suite.tests, { name = "Creator Store source ids reject cloned duplicates", run = function()
    local first = AssetManifest.Entries[1]
    Assert.notNil(first.SourceAssetId, "first entry has source asset id")
    Assert.notNil(AssetManifest.GetBySourceAssetId(first.SourceAssetId), "source id lookup works")
    for _, entry in ipairs(AssetManifest.Entries) do
        Assert.truthy(string.match(entry.SourceAssetId, "^%d+$") ~= nil, "source id is numeric for " .. entry.AssetId)
        Assert.truthy(string.find(entry.SourceAssetUrl, "create.roblox.com/store/asset/", 1, true) ~= nil, "source URL is Creator Store for " .. entry.AssetId)
        Assert.equals(entry.ImportMethod, "CreatorStoreToolboxServiceV2", "catalog method recorded for " .. entry.AssetId)
    end
end })

table.insert(suite.tests, { name = "visible workspace assets must not be placeholder primitives", run = function()
    local result = AssetAuditService:ScanWorkspace()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
end })

table.insert(suite.tests, { name = "manifest references allow sandboxed ModuleScript state", run = function()
    withTemporaryManifestEntry("Sandboxed", function(entry)
        local fixture = makeVisibleImportedManifestReference(entry)
        local moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = "SandboxedManifestUtility"
        stampReviewedAdaptedScript(moduleScript)
        moduleScript:SetAttribute("Sandboxed", true)
        moduleScript.Parent = fixture

        local failures = {}
        AssetAuditService:ValidateManifestReference(fixture, failures)
        Assert.equals(#failures, 0, table.concat(failures, "; "))
    end)
end })

table.insert(suite.tests, { name = "manifest references allow reviewed adapted runtime state", run = function()
    withTemporaryManifestEntry("ReviewedAdapted", function(entry)
        local fixture = makeVisibleImportedManifestReference(entry)
        local scriptObject = Instance.new("Script")
        scriptObject.Name = "ReviewedAdaptedManifestRuntime"
        stampReviewedAdaptedScript(scriptObject)
        scriptObject.Parent = fixture

        local failures = {}
        AssetAuditService:ValidateManifestReference(fixture, failures)
        Assert.equals(#failures, 0, table.concat(failures, "; "))
    end)
end })

table.insert(suite.tests, { name = "manifest references allow raw review queued disabled runtime state", run = function()
    withTemporaryManifestEntry("RawReviewQueued", function(entry)
        local fixture = makeVisibleImportedManifestReference(entry)
        fixture:SetAttribute("RawImportedScriptPreserved", true)
        fixture:SetAttribute("ScriptReviewStatus", "raw_preserved_pending_adaptation")

        local scriptObject = Instance.new("Script")
        scriptObject.Name = "RawQueuedManifestRuntime"
        scriptObject.Disabled = true
        scriptObject.Parent = fixture

        local failures = {}
        AssetAuditService:ValidateManifestReference(fixture, failures)
        Assert.equals(#failures, 0, table.concat(failures, "; "))
    end)
end })

return TestRunner.registerSuite(suite)
