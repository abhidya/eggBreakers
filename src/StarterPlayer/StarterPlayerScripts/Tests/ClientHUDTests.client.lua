local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local HUDController = require(script.Parent.Parent.ClientControllers.HUDController)

local suite = { name = "ClientHUDTests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "stat update renders HUD bars", run = function()
    local root = Instance.new("Frame")
    local fill = UIFactory:CreateBar(root, "Health", 12)
    Assert.equals(fill.Name, "Fill", "bar exposes fill frame")
    Assert.notNil(root:FindFirstChild("HealthLabel"), "label created")
    Assert.notNil(root:FindFirstChild("HealthBar"), "bar created")
    fill.Size = UDim2.fromScale(math.clamp(75 / 100, 0, 1), 1)
    Assert.equals(fill.Size.X.Scale, 0.75, "75 health maps to 75% bar fill")
    root:Destroy()
end })

table.insert(suite.tests, { name = "small screen readability gate", run = function()
    local payload = RemoteContracts.StatUpdate.Payload
    Assert.truthy(table.find(payload, "health") ~= nil, "StatUpdate includes health")
    Assert.truthy(table.find(payload, "hunger") ~= nil, "StatUpdate includes hunger")
    Assert.truthy(table.find(payload, "thirst") ~= nil, "StatUpdate includes thirst")
    Assert.truthy(table.find(payload, "stamina") ~= nil, "StatUpdate includes stamina")
    Assert.truthy(table.find(payload, "oxygen") ~= nil, "StatUpdate includes oxygen")
    Assert.truthy(table.find(payload, "maxOxygen") ~= nil, "StatUpdate includes max oxygen")
    Assert.truthy(table.find(payload, "creatureCategory") ~= nil, "StatUpdate includes creature category")
    Assert.truthy(table.find(payload, "movementModes") ~= nil, "StatUpdate includes movement modes")
    Assert.truthy(table.find(payload, "ecosystemProfile") ~= nil, "StatUpdate includes ecosystem profile")
    Assert.truthy(table.find(payload, "growthStage") ~= nil, "StatUpdate includes growth stage")
end })

table.insert(suite.tests, { name = "diet guidance explains species food and water", run = function()
    local herbivore = HUDController:BuildDietGuidance({
        species = "gallimimus",
        diet = "Herbivore",
        growthStage = "Hatchling",
        creatureCategory = "SmallPrey",
        maxOxygen = 55,
    })
    Assert.truthy(string.find(herbivore, "gallimimus", 1, true) ~= nil, "species appears in guidance")
    Assert.truthy(string.find(herbivore, "Herbivore", 1, true) ~= nil, "diet appears in guidance")
    Assert.truthy(string.find(herbivore, "green plant", 1, true) ~= nil, "herbivore food hint appears")
    Assert.truthy(string.find(herbivore, "SmallPrey", 1, true) ~= nil, "creature category appears")
    Assert.truthy(string.find(herbivore, "oxygen", 1, true) ~= nil, "oxygen hint appears")
    Assert.truthy(string.find(herbivore, "blue water", 1, true) ~= nil, "water hint appears")

    local carnivore = HUDController:BuildDietGuidance({
        species = "velociraptor",
        diet = "Carnivore",
        growthStage = "Hatchling",
    })
    Assert.truthy(string.find(carnivore, "red carcass", 1, true) ~= nil, "carnivore food hint appears")
end })

TestRunner.registerSuite(suite)
return suite
