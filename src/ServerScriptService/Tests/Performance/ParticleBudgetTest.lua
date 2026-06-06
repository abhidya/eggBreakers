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
    Assert.equals(result.importedRuntimeScriptCount, 0, "uncontrolled imported runtime script budget remains zero")
end })

table.insert(suite.tests, { name = "imported scripts audited", run = function()
    local result = AssetManifest.Validate({ minimum = AssetManifest.MinimumUniqueAssets })
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    for _, entry in ipairs(AssetManifest.Entries) do
        if entry.ImportedScriptsPresent then
            Assert.truthy(
                entry.ScriptSandboxStatus == "Sandboxed"
                    or entry.ScriptSandboxStatus == "ReviewedAdapted"
                    or entry.ScriptSandboxStatus == "RawReviewQueued",
                "imported scripts reviewed/adapted or review-queued for " .. entry.AssetId
            )
        end
        Assert.truthy(entry.ScriptsAudited, "script audit flag set for " .. entry.AssetId)
        Assert.truthy(AssetManifest.AllowedScriptSandboxStatuses[entry.ScriptSandboxStatus], "script sandbox status valid for " .. entry.AssetId)
        if (entry.SourceScriptCount or 0) > 0 then
            Assert.truthy(
                entry.ScriptsRemoved
                    or entry.ScriptSandboxStatus == "Sandboxed"
                    or entry.ScriptSandboxStatus == "ReviewedAdapted"
                    or entry.ScriptSandboxStatus == "RawReviewQueued",
                "source scripts removed, sandboxed, reviewed/adapted, or review-queued for " .. entry.AssetId
            )
        end
    end
end })

TestRunner.registerSuite(suite)
return suite
