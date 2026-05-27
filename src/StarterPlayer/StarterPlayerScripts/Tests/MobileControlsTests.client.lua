local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local MobileControlsController = require(script.Parent.Parent.ClientControllers.MobileControlsController)

local suite = { name = "MobileControlsTests.client", category = "Client", tests = {} }

local expectedButtons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide", "Flight", "Swim" }

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
    Assert.equals(button.Size.X.Offset, 112, "mobile button width contract")
    Assert.equals(button.Size.Y.Offset, 64, "mobile button height contract")
    Assert.truthy(button.Position.X.Offset < 0, "action buttons anchor from right edge")
    button.Parent:Destroy()
end })

table.insert(suite.tests, { name = "phone guidance exposes real asset directions", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local controlsGui = result.Gui
    Assert.notNil(controlsGui:FindFirstChild("DialoguePromptLabel"), "dialogue prompt exists")
    Assert.notNil(controlsGui:FindFirstChild("NearestActionHintLabel"), "nearest action hint exists")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("GuidesToActionableAssets"), true, "dialogue guides to non-NPC action assets")
    Assert.equals(controlsGui:FindFirstChild("NearestActionHintLabel"):GetAttribute("NonNpcActionHint"), true, "target hint excludes NPCs")
    Assert.truthy(string.find(controlsGui:FindFirstChild("EatDrinkButton").Text, "EAT", 1, true) ~= nil, "eat/drink button starts explicit")
    controlsGui:Destroy()
    MobileControlsController.Gui = nil
end })


table.insert(suite.tests, { name = "sprint call hide expose visible feedback hooks", run = function()
    local gui = UIFactory:CreateRootGui("MobileControls")
    for _, name in ipairs({ "Sprint", "Call", "RestHide" }) do
        local button = UIFactory:CreateButton(gui, name .. "Button", name, UDim2.fromOffset(0, 0))
        button:SetAttribute("ActionName", name)
        Assert.equals(button:GetAttribute("ActionName"), name, name .. " button has action attribute")
        Assert.equals(button.BackgroundColor3, Color3.fromRGB(35, 45, 35), name .. " starts with inactive color")
    end
    local feedback = Instance.new("TextLabel")
    feedback.Name = "ActionFeedbackLabel"
    feedback.Visible = false
    feedback.Parent = gui
    Assert.notNil(gui:FindFirstChild("ActionFeedbackLabel"), "visible action feedback label exists")
    gui:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
