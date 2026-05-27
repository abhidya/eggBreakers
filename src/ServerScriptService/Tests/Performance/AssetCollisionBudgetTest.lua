local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local PerformanceAuditService = require(game:GetService("ServerScriptService").Services.PerformanceAuditService)

local suite = { name = "AssetCollisionBudgetTest", category = "Performance", tests = {} }

table.insert(suite.tests, { name = "decorative collision touch query disabled where safe", run = function()
    local result = PerformanceAuditService:Scan()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
end })

table.insert(suite.tests, { name = "asset collision budgets are explicit", run = function()
    Assert.truthy(PerformanceAuditService.MaxDecorativeCollidableParts <= 40, "decorative collision cap must stay tight")
    Assert.truthy(PerformanceAuditService.MaxImportedPartsWithTouch <= 25, "touch-enabled imported part cap must stay tight")
end })

return TestRunner.registerSuite(suite)
