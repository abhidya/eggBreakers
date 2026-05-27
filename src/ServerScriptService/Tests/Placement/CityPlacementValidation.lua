local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)

local suite = { name = "CityPlacementValidation.server", category = "Placement", tests = {} }

local function contains(list, value)
    for _, item in ipairs(list) do
        if item == value then return true end
    end
    return false
end

table.insert(suite.tests, { name = "city has ruins overgrowth fossils danger routes entrances trigger", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    Assert.notNil(folders.Zones:FindFirstChild("ApocalypticCity"), "ApocalypticCity zone folder exists")
    Assert.equals(ZoneConfig.ApocalypticCity.DiscoveryName, "Old Eden discovered", "city discovery contract")
    Assert.equals(#MapLayout.CityEntrances, 2, "city has two route entrances")
    Assert.truthy(contains(MapLayout.CityEntrances, "RedstoneCanyonGate"), "redstone entrance present")
    Assert.truthy(contains(MapLayout.CityEntrances, "SwampDeltaCauseway"), "swamp entrance present")
    Assert.truthy(type(MapLayout.RiskyShortcut) == "string" and #MapLayout.RiskyShortcut > 0, "risky shortcut named")
    Assert.truthy(type(MapLayout.BabySafeRoute) == "string" and #MapLayout.BabySafeRoute > 0, "baby-safe route named")
end })

table.insert(suite.tests, { name = "no blocky part buildings", run = function()
    local placeholder = Instance.new("Part")
    placeholder.Name = "BlockoutCityBuilding"
    placeholder.Transparency = 0
    Assert.truthy(AssetAuditService:HasForbiddenVisibleName(placeholder), "blockout city placeholder name rejected")
    placeholder:SetAttribute("CreatorStoreOnly", true)
    placeholder.Name = "OldEdenTower_CreatorStore"
    Assert.falsy(AssetAuditService:HasForbiddenVisibleName(placeholder), "final city landmark name accepted")
    placeholder:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
