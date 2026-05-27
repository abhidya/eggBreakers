local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)

local suite = { name = "InvisiblePartNamingValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "invisible helpers named and transparent", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    local helper = Instance.new("Part")
    helper.Name = "_INVISIBLE_TestVolume"
    helper.Transparency = 1
    helper.Parent = folders.InvisibleGameplayVolumes
    Assert.truthy(AssetAuditService:IsInvisibleHelper(helper), "approved helper name/transparency accepted")
    helper.Name = "VisibleBadHelper"
    Assert.falsy(AssetAuditService:IsInvisibleHelper(helper), "unnamed invisible helper rejected")
    helper:Destroy()
end })

table.insert(suite.tests, { name = "helpers stored in approved folders", run = function()
    local badParent = Instance.new("Folder")
    badParent.Name = "RandomHelpers"
    badParent.Parent = workspace
    local helper = Instance.new("Part")
    helper.Name = "_INVISIBLE_BadParent"
    helper.Transparency = 1
    helper.Parent = badParent
    Assert.falsy(AssetAuditService:IsInvisibleHelper(helper), "helper outside approved folders rejected")
    badParent:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
