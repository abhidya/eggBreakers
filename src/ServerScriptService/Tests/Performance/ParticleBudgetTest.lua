local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local PerformanceAuditService = require(ServerScriptService.Services.PerformanceAuditService)

local suite = { name = "ParticleBudgetTest.server", category = "Performance", tests = {} }

table.insert(suite.tests, { name = "particle emitters capped per zone", run = function()
    Assert.truthy(PerformanceAuditService.MaxParticlesPerZone <= 20, "per-zone particle budget stays capped")
    local result = PerformanceAuditService:Scan()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.equals(result.importedRuntimeScriptCount, 0, "imported runtime script budget remains zero")
end })

table.insert(suite.tests, { name = "imported scripts audited", run = function()
    local result = AssetManifest.Validate({ minimum = AssetManifest.MinimumUniqueAssets })
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    for _, entry in ipairs(AssetManifest.Entries) do
        Assert.falsy(entry.ImportedScriptsPresent, "imported scripts removed for " .. entry.AssetId)
        Assert.truthy(entry.ScriptsAudited, "script audit flag set for " .. entry.AssetId)
        Assert.truthy(entry.ScriptsRemoved or entry.ScriptPolicy == "AuditedSandboxedModule", "script disposition approved for " .. entry.AssetId)
    end
end })

TestRunner.registerSuite(suite)
return suite
