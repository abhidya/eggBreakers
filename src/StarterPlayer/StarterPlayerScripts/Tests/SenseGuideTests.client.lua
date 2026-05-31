local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SenseGuideController = require(script.Parent.Parent.ClientControllers.SenseGuideController)

local suite = { name = "SenseGuideTests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "preferred mode follows dominant need", run = function()
    Assert.equals(SenseGuideController.PreferredMode({ hunger = 30, thirst = 80 }), "Food", "low hunger prefers food")
    Assert.equals(SenseGuideController.PreferredMode({ hunger = 80, thirst = 30 }), "Water", "low thirst prefers water")
    Assert.equals(SenseGuideController.PreferredMode({ hunger = 30, thirst = 30 }), "Water", "tie prefers water")
    Assert.equals(SenseGuideController.PreferredMode({ hunger = 90, thirst = 90 }), nil, "comfortable stats do not guide")
end })

table.insert(suite.tests, { name = "food badge uses target diet icon", run = function()
    local target = Instance.new("Part")
    target.Name = "ClientCarnivoreFood"
    target.Anchored = true
    target.Position = Vector3.new(0, 4, 0)
    target:SetAttribute("Diet", "Carnivore")
    target.Parent = workspace

    SenseGuideController:Bind({
        Finder = function()
            return target, "Food", 9
        end,
        GetStats = function()
            return { hunger = 25, thirst = 90 }
        end,
    })

    local shown = SenseGuideController:Update()
    Assert.equals(shown, true, "guide shows for low hunger")
    Assert.truthy(string.find(SenseGuideController._badge.Text, "🍖", 1, true) ~= nil, "carnivore food badge uses meat icon")

    SenseGuideController:Hide()
    target:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
