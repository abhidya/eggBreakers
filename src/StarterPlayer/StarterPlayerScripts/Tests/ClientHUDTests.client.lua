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
    Assert.truthy(string.find(delta, "🍎%+25") ~= nil, "food increase shown with icon")
    Assert.truthy(string.find(delta, "💧%+35") ~= nil, "water increase shown with icon")
    Assert.truthy(string.find(delta, "⚡%-10") ~= nil, "stamina decrease shown with icon")
    Assert.truthy(string.find(delta, "⭐%+8") ~= nil, "growth increase shown with icon")
    Assert.truthy(string.find(delta, "⚡↓", 1, true) ~= nil, "sprint drain hint shown visually")
end })

table.insert(suite.tests, { name = "diet guidance is visual for young readers", run = function()
    local herbivore = HUDController:BuildDietGuidance({
        species = "gallimimus",
        diet = "Herbivore",
        growthStage = "Hatchling",
        creatureCategory = "SmallPrey",
        maxOxygen = 55,
    })
    Assert.truthy(string.find(herbivore, "🌿", 1, true) ~= nil, "herbivore food icon appears")
    Assert.truthy(string.find(herbivore, "💧", 1, true) ~= nil, "water icon appears")
    Assert.truthy(string.find(herbivore, "green plants", 1, true) == nil, "long food copy removed")

    local carnivore = HUDController:BuildDietGuidance({
        species = "velociraptor",
        diet = "Carnivore",
        growthStage = "Hatchling",
    })
    Assert.truthy(string.find(carnivore, "🍖", 1, true) ~= nil, "carnivore food icon appears")
    Assert.truthy(string.find(carnivore, "red meat", 1, true) == nil, "long carnivore copy removed")
end })


table.insert(suite.tests, { name = "growth badge makes dinosaur leveling clear", run = function()
    local badge = HUDController:BuildGrowthBadge({ growthStage = "Juvenile", growth = 45 })
    Assert.truthy(string.find(badge, "LV 2", 1, true) ~= nil, "juvenile maps to level 2")
    Assert.truthy(string.find(badge, "45%", 1, true) ~= nil, "growth percent appears")
    Assert.truthy(string.find(badge, "→", 1, true) ~= nil, "next stage hint appears")
    Assert.truthy(string.find(badge, "Juvenile", 1, true) == nil, "stage word removed for density")

    local adult = HUDController:BuildGrowthBadge({ growthStage = "Adult", growth = 100 })
    Assert.truthy(string.find(adult, "★", 1, true) ~= nil, "adult shows max level")
end })

table.insert(suite.tests, { name = "species role card explains diet role and action", run = function()
    local card = HUDController:BuildRoleCard({ species = "velociraptor", diet = "Carnivore" })
    Assert.truthy(string.find(card, "Velociraptor", 1, true) ~= nil, "display name appears")
    Assert.truthy(string.find(card, "🍖", 1, true) ~= nil, "diet icon appears")
    Assert.truthy(string.find(card, "Carnivore", 1, true) == nil, "diet word removed for density")
    Assert.truthy(string.find(card, "Role:", 1, true) == nil, "role label removed for density")
    Assert.truthy(string.find(card, "Claw", 1, true) ~= nil, "primary action appears")
end })

table.insert(suite.tests, { name = "hud factory supports compact mobile bars", run = function()
    local root = Instance.new("Frame")
    local fill = UIFactory:CreateBar(root, "Hunger", 20, {
        LabelWidth = 44,
        BarX = 62,
        BarWidth = 188,
        ValueX = 256,
        ValueWidth = 60,
    })
    Assert.equals(root.HungerLabel.Size.X.Offset, 44, "compact icon label width applied")
    Assert.equals(root.HungerBar.Position.X.Offset, 62, "compact bar starts after icon")
    Assert.equals(root.HungerBar.Size.X.Offset, 188, "compact bar width applied")
    Assert.equals(root.HungerValueLabel.Position.X.Offset, 256, "compact value label applied")
    Assert.notNil(fill, "fill still returned")
    root:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
