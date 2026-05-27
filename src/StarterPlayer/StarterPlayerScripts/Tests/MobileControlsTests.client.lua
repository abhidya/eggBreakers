local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)

local suite = { name = "MobileControlsTests.client", category = "Client", tests = {} }

local expectedButtons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide" }

table.insert(suite.tests, { name = "thumbstick and buttons exist", run = function()
    local gui = UIFactory:CreateRootGui("MobileControls")
    local thumbstick = Instance.new("Frame")
    thumbstick.Name = "MoveThumbstick"
    thumbstick.Size = UDim2.fromOffset(110, 110)
    thumbstick.Parent = gui
    for _, name in ipairs(expectedButtons) do
        if name ~= "MoveThumbstick" then
            UIFactory:CreateButton(gui, name .. "Button", name, UDim2.fromOffset(0, 0))
        end
    end
    Assert.notNil(gui:FindFirstChild("MoveThumbstick"), "thumbstick frame exists")
    for _, name in ipairs(expectedButtons) do
        if name ~= "MoveThumbstick" then
            Assert.notNil(gui:FindFirstChild(name .. "Button"), name .. " button exists")
        end
    end
    gui:Destroy()
end })

table.insert(suite.tests, { name = "buttons do not overlap HUD", run = function()
    local button = UIFactory:CreateButton(Instance.new("Frame"), "AttackButton", "Attack", UDim2.new(1, -195, 1, -150))
    Assert.equals(button.Size.X.Offset, 86, "mobile button width contract")
    Assert.equals(button.Size.Y.Offset, 48, "mobile button height contract")
    Assert.truthy(button.Position.X.Offset < 0, "action buttons anchor from right edge")
    button.Parent:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
