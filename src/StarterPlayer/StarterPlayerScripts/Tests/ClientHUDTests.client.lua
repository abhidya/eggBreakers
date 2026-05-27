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
    Assert.notNil(root:FindFirstChild("HealthValueLabel"), "numeric value label created")
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
    Assert.truthy(table.find(payload, "sprinting") ~= nil, "StatUpdate includes sprinting")
    Assert.truthy(table.find(payload, "ecosystemProfile") ~= nil, "StatUpdate includes ecosystem profile")
    Assert.truthy(table.find(payload, "growthStage") ~= nil, "StatUpdate includes growth stage")
end })

table.insert(suite.tests, { name = "stat delta text makes progression readable", run = function()
    local delta = HUDController:BuildDeltaText(
        { health = 80, hunger = 40, thirst = 40, stamina = 80, growth = 10 },
        { health = 80, hunger = 65, thirst = 75, stamina = 70, growth = 18, sprinting = true }
    )
    Assert.truthy(string.find(delta, "Food%+25") ~= nil, "food increase shown")
    Assert.truthy(string.find(delta, "Water%+35") ~= nil, "water increase shown")
    Assert.truthy(string.find(delta, "Stam%-10") ~= nil, "stamina decrease shown")
    Assert.truthy(string.find(delta, "Grow%+8") ~= nil, "growth increase shown")
    Assert.truthy(string.find(delta, "Sprint drains stamina", 1, true) ~= nil, "sprint drain hint shown")
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


table.insert(suite.tests, { name = "growth badge makes dinosaur leveling clear", run = function()
    local badge = HUDController:BuildGrowthBadge({ growthStage = "Juvenile", growth = 45 })
    Assert.truthy(string.find(badge, "LV 2", 1, true) ~= nil, "juvenile maps to level 2")
    Assert.truthy(string.find(badge, "45% growth", 1, true) ~= nil, "growth percent appears")
    Assert.truthy(string.find(badge, "next stage", 1, true) ~= nil, "next stage hint appears")

    local adult = HUDController:BuildGrowthBadge({ growthStage = "Adult", growth = 100 })
    Assert.truthy(string.find(adult, "Max level", 1, true) ~= nil, "adult shows max level")
end })

table.insert(suite.tests, { name = "species role card explains diet role and action", run = function()
    local card = HUDController:BuildRoleCard({ species = "velociraptor", diet = "Carnivore" })
    Assert.truthy(string.find(card, "Velociraptor", 1, true) ~= nil, "display name appears")
    Assert.truthy(string.find(card, "Carnivore", 1, true) ~= nil, "diet appears")
    Assert.truthy(string.find(card, "Role:", 1, true) ~= nil, "role label appears")
    Assert.truthy(string.find(card, "Claw", 1, true) ~= nil, "primary action appears")
end })

TestRunner.registerSuite(suite)
return suite
