local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local Constants = require(ReplicatedStorage.Shared.Constants)
local PlacementValidationService = require(ServerScriptService.Services.PlacementValidationService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)

local suite = { name = "FoodSourceAndFloatingValidation.server", category = "Placement", tests = {} }

local function makeFood(name, diet, nutrition, position)
    local food = Instance.new("Part")
    food.Name = name
    food.Size = Vector3.new(3, 2, 3)
    food.Position = position or Vector3.new(-2000, 12, 0)
    food:SetAttribute("Diet", diet)
    food:SetAttribute("Nutrition", nutrition)
    food:SetAttribute("ZoneId", "NurseryGrove")
    food.Parent = workspace
    CollectionService:AddTag(food, Constants.Tags.FoodSource)
    return food
end

table.insert(suite.tests, { name = "food source tag diet nutrition and reachability are concrete", run = function()
    local food = makeFood("NurseryHerbivoreFernFood", "Herbivore", 25, Vector3.new(-2000, 12, 0))
    local root = Instance.new("Part")
    root.Name = "ReachabilityRoot"
    root.Position = Vector3.new(-2003, 12, 0)
    root.Parent = workspace

    local placement = PlacementValidationService:ValidateFoodSourceInstance(food)
    Assert.truthy(placement.passed, table.concat(placement.failures, "; "))
    Assert.truthy(CollectionService:HasTag(food, Constants.Tags.FoodSource), "food source tag required")
    Assert.truthy(RemoteValidationService:ValidateFoodTarget(root, food, "Herbivore", 12), "matching nearby herbivore food reachable")
    local wrongDietOk, wrongDietReason = RemoteValidationService:ValidateFoodTarget(root, food, "Carnivore", 12)
    Assert.falsy(wrongDietOk, "wrong diet rejected")
    Assert.equals(wrongDietReason, "wrong_diet", "wrong diet reason")

    root:Destroy()
    food:Destroy()
end })

table.insert(suite.tests, { name = "invalid food source metadata fails placement gate", run = function()
    local food = makeFood("BadFoodMetadata", "Omnivore", 0, Vector3.new(-2000, 12, 0))
    local result = PlacementValidationService:ValidateFoodSourceInstance(food)
    Assert.falsy(result.passed, "invalid diet/nutrition must fail")
    Assert.truthy(#result.failures >= 2, "diet and nutrition failures reported")
    food:Destroy()
end })

table.insert(suite.tests, { name = "visible floating assets fail unless explicitly allowed", run = function()
    local grounded = Instance.new("Part")
    grounded.Name = "GroundedVisibleAsset"
    grounded.Size = Vector3.new(4, 4, 4)
    grounded.Position = Vector3.new(0, 12, 0)
    grounded:SetAttribute("GroundTopY", 10)
    grounded.Parent = workspace

    local floating = Instance.new("Part")
    floating.Name = "FloatingVisibleAsset"
    floating.Size = Vector3.new(4, 4, 4)
    floating.Position = Vector3.new(0, 25, 0)
    floating:SetAttribute("GroundTopY", 10)
    floating.Parent = workspace

    local probeRoot = Instance.new("Folder")
    probeRoot.Name = "FloatingValidationProbeRoot"
    probeRoot.Parent = workspace
    grounded.Parent = probeRoot
    floating.Parent = probeRoot

    local result = PlacementValidationService:ValidateNoFloatingVisibleAssets(probeRoot)
    Assert.falsy(result.passed, "floating asset should fail")
    Assert.truthy(#result.failures >= 1, "floating failure reported")

    floating:SetAttribute("FloatingAllowed", true)
    result = PlacementValidationService:ValidateNoFloatingVisibleAssets(probeRoot)
    Assert.truthy(result.passed, table.concat(result.failures, "; "))

    probeRoot:Destroy()
end })

return TestRunner.registerSuite(suite)
