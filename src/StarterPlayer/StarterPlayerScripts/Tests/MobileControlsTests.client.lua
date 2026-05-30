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
    thumbstick.Size = UDim2.fromOffset(132, 132)
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
    local button = UIFactory:CreateButton(Instance.new("Frame"), "AttackButton", "Attack", UDim2.new(1, -184, 1, -142), { Size = UDim2.fromOffset(82, 58) })
    Assert.truthy(button.Size.X.Offset <= 82, "mobile button width stays compact")
    Assert.truthy(button.Size.Y.Offset <= 58, "mobile button height stays compact")
    Assert.truthy(button.Position.X.Offset < 0, "action buttons anchor from right edge")
    Assert.truthy(button.Position.Y.Offset < -120, "top action row clears bottom edge")
    button.Parent:Destroy()
end })

table.insert(suite.tests, { name = "phone guidance exposes real asset directions", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local controlsGui = result.Gui
    Assert.notNil(controlsGui:FindFirstChild("DialoguePromptLabel"), "dialogue prompt exists")
    Assert.notNil(controlsGui:FindFirstChild("NearestActionHintLabel"), "nearest action hint exists")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("GuidesToActionableAssets"), true, "dialogue guides to non-NPC action assets")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("ProductionKidGuidance"), true, "guidance is production kid UI")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("IconOnlyTracker"), true, "dialogue is icon-first")
    Assert.equals(controlsGui:FindFirstChild("NearestActionHintLabel"):GetAttribute("NonNpcActionHint"), true, "target hint excludes NPCs")
    Assert.equals(controlsGui:FindFirstChild("NearestActionHintLabel"):GetAttribute("IconOnlyTracker"), true, "target hint is icon-first")
    Assert.truthy(string.find(controlsGui:FindFirstChild("EatDrinkButton").Text, "Snack", 1, true) ~= nil, "eat/drink button starts kid-friendly")
    Assert.truthy(string.find(controlsGui:FindFirstChild("NearestActionHintLabel").Text, "↗", 1, true) ~= nil, "target hint is visual arrow style")
    Assert.truthy(string.find(controlsGui:FindFirstChild("NearestActionHintLabel").Text, "Follow", 1, true) == nil, "long tracker instruction removed")
    controlsGui:Destroy()
    MobileControlsController.Gui = nil
end })


table.insert(suite.tests, { name = "all gameplay actions expose feedback and cooldown hooks", run = function()
    local gui = UIFactory:CreateRootGui("MobileControls")
    for _, name in ipairs({ "EatDrink", "Attack", "Sprint", "Call", "RestHide", "Flight", "Swim" }) do
        local button = UIFactory:CreateButton(gui, name .. "Button", name, UDim2.fromOffset(0, 0))
        button:SetAttribute("ActionName", name)
        button:SetAttribute("Context", "Ready")
        button:SetAttribute("PressCount", 0)
        button:SetAttribute("LastActionResult", "Ready")
        button:SetAttribute("CooldownSeconds", name == "Call" and 0.4 or 0.2)
        Assert.equals(button:GetAttribute("ActionName"), name, name .. " button has action attribute")
        Assert.equals(button:GetAttribute("Context"), "Ready", name .. " has contextual state")
        Assert.truthy(button:GetAttribute("CooldownSeconds") > 0, name .. " exposes cooldown")
        Assert.equals(button:GetAttribute("PressCount"), 0, name .. " starts with press counter")
        Assert.equals(button.BackgroundColor3, Color3.fromRGB(35, 45, 35), name .. " starts with inactive color")
    end
    local feedback = Instance.new("TextLabel")
    feedback.Name = "ActionFeedbackLabel"
    feedback.Visible = false
    feedback:SetAttribute("MobileReadable", true)
    feedback:SetAttribute("LastFeedback", "")
    feedback.Parent = gui
    Assert.notNil(gui:FindFirstChild("ActionFeedbackLabel"), "visible action feedback label exists")
    Assert.equals(feedback:GetAttribute("MobileReadable"), true, "feedback is readable on phone")
    gui:Destroy()
end })

table.insert(suite.tests, { name = "flight and swim controls hide until available", run = function()
    Assert.truthy(table.find(MobileControlsController.OptionalButtons, "Flight") ~= nil, "flight is optional")
    Assert.truthy(table.find(MobileControlsController.OptionalButtons, "Swim") ~= nil, "swim is optional")
    Assert.notNil(MobileControlsController.EffectStyles.Flight, "flight has visual feedback style")
    Assert.notNil(MobileControlsController.EffectStyles.Swim, "swim has visual feedback style")
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    Assert.equals(result.Gui:FindFirstChild("FlightButton").Visible, false, "flight starts hidden")
    Assert.equals(result.Gui:FindFirstChild("SwimButton").Visible, false, "swim starts hidden")
    Assert.equals(result.Gui:FindFirstChild("FlightButton").Active, false, "flight does not remain as grey inactive button")
    Assert.equals(result.Gui:FindFirstChild("SwimButton").Active, false, "swim does not remain as grey inactive button")
    result.Gui:Destroy()
    MobileControlsController.Gui = nil
end })

table.insert(suite.tests, { name = "mobile buttons expose icon identity", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local controlsGui = result.Gui
    Assert.equals(controlsGui:FindFirstChild("EatDrinkButton"):GetAttribute("KidIcon"), "🍎", "eat button has icon identity")
    Assert.equals(controlsGui:FindFirstChild("AttackButton"):GetAttribute("KidIcon"), "🦷", "attack button has icon identity")
    Assert.equals(controlsGui:FindFirstChild("CallButton"):GetAttribute("MobileReadable"), true, "buttons remain mobile readable")
    controlsGui:Destroy()
    MobileControlsController.Gui = nil
end })

table.insert(suite.tests, { name = "waypoint tracker stays icon based", run = function()
    local food = MobileControlsController:BuildWaypointText("Food", 12.4)
    local water = MobileControlsController:BuildWaypointText("Water", 7.6)
    local none = MobileControlsController:BuildWaypointText("None")
    Assert.truthy(string.find(food, "↗ 🍎 12m", 1, true) ~= nil, "food waypoint uses arrow icon and distance")
    Assert.truthy(string.find(water, "↗ 💧 8m", 1, true) ~= nil, "water waypoint uses arrow icon and rounded distance")
    Assert.truthy(string.find(none, "🍎", 1, true) ~= nil and string.find(none, "💧", 1, true) ~= nil, "idle tracker shows food and water icons")
    Assert.truthy(string.find(food, "Food", 1, true) == nil, "food word removed from tracker")
    Assert.truthy(string.find(water, "Water", 1, true) == nil, "water word removed from tracker")
end })

TestRunner.registerSuite(suite)
return suite
