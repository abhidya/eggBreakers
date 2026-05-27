local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)

local suite = { name = "FoodWaterPlacementValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "nursery food water exists", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    Assert.notNil(folders.Zones:FindFirstChild("NurseryGrove"), "NurseryGrove zone exists")
    Assert.notNil(folders.FoodSources, "FoodSources folder exists")
    Assert.notNil(folders.WaterSources, "WaterSources folder exists")
end })

table.insert(suite.tests, { name = "non nursery water and risky food/fossils reachable", run = function()
    local root = Instance.new("Part")
    root.Position = Vector3.new(0, 0, 0)
    root.Parent = workspace
    local nearby = Instance.new("Part")
    nearby.Position = Vector3.new(5, 0, 0)
    nearby.Parent = workspace
    local far = Instance.new("Part")
    far.Position = Vector3.new(80, 0, 0)
    far.Parent = workspace
    Assert.truthy(RemoteValidationService:IsClose(root, nearby, 12), "nearby placement reachable")
    Assert.falsy(RemoteValidationService:IsClose(root, far, 12), "far placement rejected")
    root:Destroy(); nearby:Destroy(); far:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
