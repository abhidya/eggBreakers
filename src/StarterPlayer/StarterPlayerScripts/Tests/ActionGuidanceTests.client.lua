local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local ActionGuidanceController = require(script.Parent.Parent.ClientControllers.ActionGuidanceController)
local MobileControlsController = require(script.Parent.Parent.ClientControllers.MobileControlsController)

local suite = { name = "ActionGuidanceTests.client", category = "Client", tests = {} }

local function makeGuidanceGui()
    local gui = UIFactory:CreateRootGui("ActionGuidanceTests")
    UIFactory:CreateLabel(gui, "NearestActionHintLabel", "◌ 🌿  💧", UDim2.fromOffset(0, 0), {
        Size = UDim2.fromOffset(240, 42),
    })
    UIFactory:CreateLabel(gui, "DialoguePromptLabel", "🌿 + 💧 = ⭐", UDim2.fromOffset(0, 48), {
        Size = UDim2.fromOffset(240, 42),
    })
    UIFactory:CreateButton(gui, "EatDrinkButton", "🍎💧", UDim2.fromOffset(0, 96), {
        Size = UDim2.fromOffset(120, 58),
    })
    return gui
end

table.insert(suite.tests, { name = "far sensed target does not become tappable", run = function()
    local gui = makeGuidanceGui()
    local target = Instance.new("Part")
    target.Name = "DistantMeatCache"
    target:SetAttribute("Diet", "Carnivore")
    local context = {
        LastStats = { diet = "Carnivore", hunger = 20, thirst = 90 },
        SenseTargetDistance = 80,
        ActionTargetDistance = 14,
        FindNearestEatDrinkTarget = function(_, maxDistance)
            if maxDistance >= 80 then
                return target, "Food", 42
            end
            return nil, nil, nil
        end,
        DescribeTarget = function(_, instance)
            return instance.Name, "Carnivore"
        end,
    }

    Assert.truthy(ActionGuidanceController:Update(gui, context), "guidance updates")
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    Assert.equals(hint:GetAttribute("Actionable"), false, "far target is sensed only")
    Assert.equals(hint:GetAttribute("TargetName"), "DistantMeatCache", "hint tracks sensed target")
    Assert.equals(hint:GetAttribute("TargetDiet"), "Carnivore", "hint tracks diet")
    Assert.truthy(string.find(hint.Text, "🍖", 1, true) ~= nil, "hint uses carnivore icon")
    Assert.equals(eatDrink:GetAttribute("Context"), "Sensed", "button shows sensed state")
    Assert.equals(eatDrink.Active, false, "sensed button is not tappable")
    Assert.equals(eatDrink:GetAttribute("ActionVerb"), "", "sensed button has no action verb")

    target:Destroy()
    gui:Destroy()
end })

table.insert(suite.tests, { name = "near target becomes one tap eat action", run = function()
    local gui = makeGuidanceGui()
    local target = Instance.new("Part")
    target.Name = "NearFern"
    target:SetAttribute("Diet", "Herbivore")
    local context = {
        LastStats = { diet = "Herbivore", hunger = 20, thirst = 90 },
        SenseTargetDistance = 80,
        ActionTargetDistance = 14,
        FindNearestEatDrinkTarget = function()
            return target, "Food", 8
        end,
        DescribeTarget = function(_, instance)
            return instance.Name, "Herbivore"
        end,
    }

    Assert.truthy(ActionGuidanceController:Update(gui, context), "guidance updates")
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    Assert.equals(hint:GetAttribute("Actionable"), true, "near target is actionable")
    Assert.equals(eatDrink:GetAttribute("Context"), "Nearby", "button shows nearby state")
    Assert.equals(eatDrink:GetAttribute("ActionVerb"), "EAT", "button gets eat action")
    Assert.equals(eatDrink:GetAttribute("CurrentTargetName"), "NearFern", "button tracks target")
    Assert.equals(eatDrink.Active, true, "near button is tappable")
    Assert.truthy(string.find(eatDrink.Text, "Snack", 1, true) ~= nil, "button names snack action")

    target:Destroy()
    gui:Destroy()
end })

table.insert(suite.tests, { name = "no target keeps diet legend unavailable", run = function()
    local gui = makeGuidanceGui()
    local context = {
        LastStats = { diet = "Carnivore", hunger = 90, thirst = 20 },
        FindNearestEatDrinkTarget = function()
            return nil, nil, nil
        end,
    }

    Assert.truthy(ActionGuidanceController:Update(gui, context), "guidance updates")
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    Assert.equals(hint:GetAttribute("Actionable"), false, "no target is not actionable")
    Assert.equals(eatDrink:GetAttribute("Context"), "Unavailable", "button unavailable without target")
    Assert.equals(eatDrink.Text, MobileControlsController:BuildFoodWaterLegend(context.LastStats), "button keeps diet legend")

    gui:Destroy()
end })

TestRunner.registerSuite(suite)
return suite
