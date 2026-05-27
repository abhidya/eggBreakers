local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetAuditService = require(game:GetService("ServerScriptService").Services.AssetAuditService)

local suite = { name = "AssetManifestValidation", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "asset import manifest has 500 unique pipeline ids", run = function()
    local result = AssetManifest.Validate({ minimum = 500 })
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.equals(result.total, 500, "G011 manifest entry count")
    Assert.equals(result.uniqueAssetIds, 500, "G011 unique AssetId count")
end })

table.insert(suite.tests, { name = "visible workspace assets must not be placeholder primitives", run = function()
    local result = AssetAuditService:ScanWorkspace()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
end })

return TestRunner.registerSuite(suite)
