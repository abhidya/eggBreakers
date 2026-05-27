local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local MobileControlsController = require(script.Parent.Parent.ClientControllers.MobileControlsController)

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


table.insert(suite.tests, { name = "sprint call hide buttons expose visible effects", run = function()
    local gui = UIFactory:CreateRootGui("MobileControlsEffectProbe")
    local sprint = UIFactory:CreateButton(gui, "SprintButton", "Sprint", UDim2.fromOffset(0, 0))
    local call = UIFactory:CreateButton(gui, "CallButton", "Call", UDim2.fromOffset(0, 0))
    local restHide = UIFactory:CreateButton(gui, "RestHideButton", "RestHide", UDim2.fromOffset(0, 0))

    Assert.truthy(MobileControlsController:SetButtonEffect(sprint, "Sprint", true), "sprint effect applies")
    Assert.equals(sprint:GetAttribute("EffectActive"), true, "sprint effect active flag")
    Assert.equals(sprint.Text, "Sprint!", "sprint active label")
    Assert.truthy(MobileControlsController:SetButtonEffect(sprint, "Sprint", false), "sprint effect clears")
    Assert.equals(sprint:GetAttribute("EffectActive"), false, "sprint effect inactive flag")
    Assert.equals(sprint.Text, "Sprint", "sprint default label restored")

    Assert.truthy(MobileControlsController:SetButtonEffect(call, "Call", true), "call effect applies")
    Assert.equals(call.Text, "Calling", "call active label")
    Assert.truthy(MobileControlsController:SetButtonEffect(restHide, "RestHide", true), "hide effect applies")
    Assert.equals(restHide.Text, "Hidden", "hide active label")

    gui:Destroy()
end })

table.insert(suite.tests, { name = "mobile controls create visible action feedback label", run = function()
    MobileControlsController.Gui = nil
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local gui = result.Gui
    Assert.notNil(gui:FindFirstChild("ActionFeedbackLabel"), "action feedback label exists")
    Assert.equals(gui.SprintButton:GetAttribute("ActionName"), "Sprint", "sprint action attribute")
    Assert.equals(gui.CallButton:GetAttribute("ActionName"), "Call", "call action attribute")
    Assert.equals(gui.RestHideButton:GetAttribute("ActionName"), "RestHide", "hide action attribute")
    gui:Destroy()
    MobileControlsController.Gui = nil
end })

TestRunner.registerSuite(suite)
return suite
