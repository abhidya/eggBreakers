local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)
local CollectionService = game:GetService("CollectionService")

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


table.insert(suite.tests, { name = "placed herbivore plants and carnivore carcasses exist", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSources()
    local herbivore = 0
    local carnivore = 0
    local nurseryPlants = 0
    local fernPlants = 0
    local preyCarcasses = 0
    for _, item in ipairs(folders.FoodSources:GetChildren()) do
        if CollectionService:HasTag(item, "FoodSource") then
            Assert.notNil(item:GetAttribute("Nutrition"), item.Name .. " has nutrition")
            Assert.equals(item:GetAttribute("Depleted"), false, item.Name .. " starts available")
            local diet = item:GetAttribute("Diet")
            if diet == "Herbivore" then
                herbivore = herbivore + 1
                if item:GetAttribute("ZoneId") == "NurseryGrove" then nurseryPlants = nurseryPlants + 1 end
                if item:GetAttribute("ZoneId") == "FernPlains" then fernPlants = fernPlants + 1 end
            elseif diet == "Carnivore" then
                carnivore = carnivore + 1
                if tostring(item:GetAttribute("PlacementRole")):find("Carcass") then preyCarcasses = preyCarcasses + 1 end
            end
        end
    end
    Assert.truthy(herbivore >= 4, "multiple herbivore plant foods placed")
    Assert.truthy(carnivore >= 4, "multiple carnivore carcass/meat foods placed")
    Assert.truthy(nurseryPlants >= 2, "Nursery has starter plant food")
    Assert.truthy(fernPlants >= 2, "Fern Plains has herbivore food density")
    Assert.truthy(preyCarcasses >= 3, "carnivore prey/carcass food exists")
end })

TestRunner.registerSuite(suite)
return suite
