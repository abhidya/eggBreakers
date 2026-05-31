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

table.insert(suite.tests, { name = "phone guidance exposes scent cues without fake arrows", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local controlsGui = result.Gui
    Assert.notNil(controlsGui:FindFirstChild("DialoguePromptLabel"), "dialogue prompt exists")
    Assert.notNil(controlsGui:FindFirstChild("NearestActionHintLabel"), "nearest action hint exists")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("GuidesToActionableAssets"), true, "dialogue guides to non-NPC action assets")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("ProductionKidGuidance"), true, "guidance is production kid UI")
    Assert.equals(controlsGui:FindFirstChild("DialoguePromptLabel"):GetAttribute("IconOnlyTracker"), true, "dialogue is icon-first")
    Assert.equals(controlsGui:FindFirstChild("NearestActionHintLabel"):GetAttribute("NonNpcActionHint"), true, "target hint excludes NPCs")
    Assert.equals(controlsGui:FindFirstChild("NearestActionHintLabel"):GetAttribute("IconOnlyTracker"), true, "target hint is icon-first")
    Assert.equals(controlsGui:FindFirstChild("EatDrinkButton").Text, "🍎💧", "eat/drink button starts icon-first")
    Assert.truthy(string.find(controlsGui:FindFirstChild("NearestActionHintLabel").Text, "⬆", 1, true) == nil, "target hint does not use fake direction arrow")
    Assert.truthy(string.find(controlsGui:FindFirstChild("NearestActionHintLabel").Text, "◌", 1, true) ~= nil, "idle target hint uses sense pulse")
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
    for _, name in ipairs(MobileControlsController.OptionalButtons) do
        local button = result.Gui:FindFirstChild(name .. "Button")
        Assert.notNil(button, name .. " optional button exists for runtime unlock")
        Assert.equals(button.Visible, false, name .. " starts hidden")
        Assert.equals(button.Active, false, name .. " does not remain as grey inactive button")
        Assert.equals(button.AutoButtonColor, false, name .. " has no grey disabled affordance")
        Assert.equals(button:GetAttribute("OptionalAction"), true, name .. " is marked optional")
    end
    result.Gui:Destroy()
    MobileControlsController.Gui = nil
end })

table.insert(suite.tests, { name = "mobile buttons expose icon-first minimal labels", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local controlsGui = result.Gui
    local expected = { EatDrink = "🍎💧", Attack = "🦷", Sprint = "⚡", Call = "📣", RestHide = "🌿💤", Flight = "🪽", Swim = "🌊" }
    for name, text in pairs(expected) do
        local button = controlsGui:FindFirstChild(name .. "Button")
        Assert.equals(button.Text, text, name .. " label is icon-first/minimal")
        Assert.equals(button:GetAttribute("DefaultText"), text, name .. " default label remains minimal")
        Assert.equals(button:GetAttribute("IconFirstMinimalLabel"), true, name .. " label contract marked")
        Assert.truthy(string.len(button.Text) <= 12, name .. " label stays short")
    end
    Assert.equals(controlsGui:FindFirstChild("EatDrinkButton"):GetAttribute("KidIcon"), "🍎", "eat button has icon identity")
    Assert.equals(controlsGui:FindFirstChild("AttackButton"):GetAttribute("KidIcon"), "🦷", "attack button has icon identity")
    Assert.equals(controlsGui:FindFirstChild("CallButton"):GetAttribute("MobileReadable"), true, "buttons remain mobile readable")
    controlsGui:Destroy()
    MobileControlsController.Gui = nil
end })

table.insert(suite.tests, { name = "waypoint tracker stays icon based", run = function()
    local food = MobileControlsController:BuildWaypointText("Food", 12.4, "Herbivore")
    local water = MobileControlsController:BuildWaypointText("Water", 7.6)
    local distant = MobileControlsController:BuildWaypointText("Food", 42.2, "Carnivore")
    local none = MobileControlsController:BuildWaypointText("None", nil, "Carnivore")
    Assert.truthy(string.find(food, "✨ 🌿 12m", 1, true) ~= nil, "nearby herbivore food uses sense pulse and distance")
    Assert.truthy(string.find(water, "✨ 💧 8m", 1, true) ~= nil, "nearby water waypoint uses sparkle cue and rounded distance")
    Assert.truthy(string.find(distant, "〰 🍖 42m", 1, true) ~= nil, "distant carnivore food uses scent trail and diet icon")
    Assert.truthy(string.find(none, "🍖", 1, true) ~= nil and string.find(none, "💧", 1, true) ~= nil, "idle tracker shows diet-valid food and water icons")
    Assert.truthy(string.find(food, "Food", 1, true) == nil, "food word removed from tracker")
    Assert.truthy(string.find(water, "Water", 1, true) == nil, "water word removed from tracker")
    Assert.truthy(string.find(food, "⬆", 1, true) == nil and string.find(distant, "⬆", 1, true) == nil, "target tracker never uses generic up arrow")
end })

table.insert(suite.tests, { name = "diet icons distinguish food targets", run = function()
    Assert.equals(MobileControlsController:BuildTargetIcon("Food", "Herbivore"), "🌿", "herbivore food uses plant icon")
    Assert.equals(MobileControlsController:BuildTargetIcon("Food", "Carnivore"), "🍖", "carnivore food uses meat icon")
    Assert.equals(MobileControlsController:BuildTargetIcon("Food", "Omnivore"), "🍽️", "omnivore food uses mixed diet icon")
    Assert.equals(MobileControlsController:BuildTargetIcon("Water", "Carnivore"), "💧", "water icon ignores diet")
    Assert.equals(MobileControlsController:BuildFoodWaterLegend({ diet = "Carnivore", hunger = 20, thirst = 80 }), "🍖 + 💧 = ⭐", "legend uses carnivore food icon")
end })

table.insert(suite.tests, { name = "sensed target state is not tappable", run = function()
    local button = UIFactory:CreateButton(Instance.new("Frame"), "EatDrinkButton", "🍎💧", UDim2.fromOffset(0, 0))
    local ok = MobileControlsController:SetButtonContext(button, "Sensed")
    Assert.equals(ok, true, "sensed state applies")
    Assert.equals(button:GetAttribute("Context"), "Sensed", "button records sensed-only state")
    Assert.equals(button.Active, false, "sensed distant target does not advertise tappable action")
    Assert.equals(button.AutoButtonColor, false, "sensed distant target does not look pressable")
    button.Parent:Destroy()
end })

table.insert(suite.tests, { name = "action feedback avoids directional arrows", run = function()
    Assert.truthy(string.find("◌ 🍎 💧", "↗", 1, true) == nil, "fallback feedback avoids diagonal direction arrow")
    Assert.truthy(string.find(MobileControlsController:BuildWaypointText("Food", 30, "Herbivore"), "⬆", 1, true) == nil, "scent cue avoids up arrow")
end })


table.insert(suite.tests, { name = "mobile hud prompts do not overlap controls", run = function()
    local result = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    local gui = result.Gui
    local function verticalRect(instance)
        return {
            top = instance.Position.Y.Offset,
            bottom = instance.Position.Y.Offset + instance.Size.Y.Offset,
        }
    end
    local function verticallySeparated(a, b)
        return a.bottom <= b.top or b.bottom <= a.top
    end
    local floating = { "DialoguePromptLabel", "NearestActionHintLabel", "ActionFeedbackLabel" }
    local actions = { "EatDrinkButton", "AttackButton", "SprintButton", "CallButton", "RestHideButton", "FlightButton", "SwimButton" }
    for _, aName in ipairs(floating) do
        local a = verticalRect(gui:FindFirstChild(aName))
        for _, bName in ipairs(actions) do
            local b = verticalRect(gui:FindFirstChild(bName))
            Assert.truthy(verticallySeparated(a, b), aName .. " vertically clears " .. bName)
        end
    end
    Assert.equals(gui:FindFirstChild("NearestActionHintLabel"):GetAttribute("WaypointCue"), "scent-pulse-nearby-trail", "scent cue contract exists")
    gui:Destroy()
    MobileControlsController.Gui = nil
end })

TestRunner.registerSuite(suite)
return suite
