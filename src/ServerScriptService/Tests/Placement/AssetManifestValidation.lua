local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetAuditService = require(game:GetService("ServerScriptService").Services.AssetAuditService)

local suite = { name = "AssetManifestValidation", category = "Placement", tests = {} }

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

return TestRunner.registerSuite(suite)
