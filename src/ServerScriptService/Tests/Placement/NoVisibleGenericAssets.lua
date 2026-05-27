local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)

local suite = { name = "NoVisibleGenericAssets.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "no default visible placeholders", run = function()
    local bad = Instance.new("Part")
    bad.Name = "Placeholder_Rock"
    bad.Transparency = 0
    Assert.truthy(AssetAuditService:HasForbiddenVisibleName(bad), "placeholder-like visible name detected")
    bad.Name = "FernPlains_Rock_Imported"
    Assert.falsy(AssetAuditService:HasForbiddenVisibleName(bad), "production asset name accepted")
    bad:Destroy()
end })

table.insert(suite.tests, { name = "invisible helper exceptions follow naming/storage", run = function()
    local allowed = AssetAuditService.AllowedInvisibleParents
    Assert.truthy(#allowed >= 4, "approved invisible helper parent list is explicit")
    Assert.equals(allowed[1], "InvisibleGameplayVolumes", "primary invisible helper folder")
end })

TestRunner.registerSuite(suite)
return suite
