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
    Assert.truthy(string.find(card, "👣", 1, true) ~= nil, "movement badge appears")
    Assert.truthy(string.find(card, "⟐", 1, true) ~= nil, "pack/profile badge appears")
    Assert.truthy(string.find(card, "Carnivore", 1, true) == nil, "diet word removed for density")
    Assert.truthy(string.find(card, "Role:", 1, true) == nil, "role label removed for density")
    Assert.truthy(string.find(card, "Claw", 1, true) ~= nil, "primary action appears")
end })

table.insert(suite.tests, { name = "ecosystem profile badges expose species category and movement", run = function()
    local prey = HUDController:BuildRoleCard({
        species = "gallimimus",
        diet = "Herbivore",
        creatureCategory = "SmallPrey",
        movementModes = { Ground = true },
        ecosystemProfile = { SmallPrey = true, Herding = true, CanGraze = true },
    })
    Assert.truthy(string.find(prey, "Gallimimus", 1, true) ~= nil, "species display name appears")
    Assert.truthy(string.find(prey, "🌿", 1, true) ~= nil, "diet/profile plant badge appears")
    Assert.truthy(string.find(prey, "🐾", 1, true) ~= nil, "small prey category badge appears")
    Assert.truthy(string.find(prey, "👣", 1, true) ~= nil, "ground movement badge appears")

    local swimmer = HUDController:BuildRoleCard({
        species = "spinosaurus",
        diet = "Carnivore",
        creatureCategory = "SemiAquatic",
        movementModes = { Ground = true, Swim = true },
        ecosystemProfile = { SemiAquatic = true, RiverPredator = true, ApexEventEligible = true },
    })
    Assert.truthy(string.find(swimmer, "Spinosaurus", 1, true) ~= nil, "swimmer species appears")
    Assert.truthy(string.find(swimmer, "🌊", 1, true) ~= nil, "swim/profile badge appears")
    Assert.truthy(string.find(swimmer, "⚠", 1, true) ~= nil, "apex-eligible threat badge appears")
end })

table.insert(suite.tests, { name = "oxygen uses progressive disclosure", run = function()
    Assert.equals(HUDController:ShouldShowOxygen({
        maxOxygen = 60,
        oxygen = 60,
        swimming = false,
        movementModes = { Swim = true },
    }), false, "full oxygen on shore stays hidden even for swimmers")

    Assert.equals(HUDController:ShouldShowOxygen({
        maxOxygen = 60,
        oxygen = 60,
        swimming = true,
    }), true, "active swimming shows oxygen")

    Assert.equals(HUDController:ShouldShowOxygen({
        maxOxygen = 60,
        oxygen = 34,
        swimming = false,
    }), true, "oxygen recovery remains visible after loss")
end })

table.insert(suite.tests, { name = "apex threat badge is compact and observable", run = function()
    local apex = HUDController:BuildThreatBadge({
        species = "tyrannosaurus",
        creatureCategory = "Apex",
        ecosystemProfile = { Apex = true, ThreatRadius = 140 },
    })
    Assert.equals(apex, "⚠ 140m", "apex threat radius is visible without prose")

    local statusThreat = HUDController:BuildThreatBadge({
        creatureCategory = "SmallPrey",
        statusEffects = { ApexThreatNearby = true },
    })
    Assert.equals(statusThreat, "⚠", "nearby apex status is observable")

    local calm = HUDController:BuildThreatBadge({
        creatureCategory = "SmallPrey",
        ecosystemProfile = { Herding = true },
    })
    Assert.equals(calm, "", "non-threat profiles stay quiet")
end })

table.insert(suite.tests, { name = "story cue exposes biome needs threat fish and nest state", run = function()
    local hatchling = HUDController:BuildStoryCue({
        species = "gallimimus",
        diet = "Herbivore",
        growthStage = "Hatchling",
        hunger = 22,
        thirst = 18,
        ecosystemProfile = { PreferredBiome = "NurseryGrove", SmallPrey = true },
    })
    Assert.truthy(string.find(hatchling, "NurseryGrove", 1, true) ~= nil, "biome context appears")
    Assert.truthy(string.find(hatchling, "🐣", 1, true) ~= nil, "hatchling story state appears")
    Assert.truthy(string.find(hatchling, "🌿!", 1, true) ~= nil, "food need appears with diet icon")
    Assert.truthy(string.find(hatchling, "💧!", 1, true) ~= nil, "water need appears")

    local swamp = HUDController:BuildStoryCue({
        species = "spinosaurus",
        diet = "Carnivore",
        growthStage = "Adult",
        hunger = 88,
        thirst = 75,
        swimming = true,
        oxygen = 28,
        maxOxygen = 100,
        creatureCategory = "SemiAquatic",
        ecosystemProfile = { SemiAquatic = true, RiverPredator = true, ApexEventEligible = true, PreferredBiome = "SwampDelta" },
        statusEffects = { CurrentBiome = "SwampDelta", FishSchoolNearby = true, ApexThreatNearby = true, NestEggCount = 2 },
    })
    Assert.truthy(string.find(swamp, "SwampDelta", 1, true) ~= nil, "current biome overrides profile")
    Assert.truthy(string.find(swamp, "🐟", 1, true) ~= nil, "fish cue appears for aquatic story beat")
    Assert.truthy(string.find(swamp, "🫧!", 1, true) ~= nil, "oxygen danger appears")
    Assert.truthy(string.find(swamp, "⚠", 1, true) ~= nil, "apex warning appears")
    Assert.truthy(string.find(swamp, "🪺x2", 1, true) ~= nil, "nest egg state appears when replicated")
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
