local MobileControlsController = require(script.Parent.MobileControlsController)
local SenseGuideController = require(script.Parent.SenseGuideController)

local ActionGuidanceController = {}

local function dietForTarget(target, stats)
    if target and target:GetAttribute("Diet") then
        return target:GetAttribute("Diet")
    end
    return stats and stats.diet or nil
end

function ActionGuidanceController:Update(gui, context)
    if not gui or not context then return false end
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    local dialogue = gui:FindFirstChild("DialoguePromptLabel")
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    local stats = context.LastStats or {}
    local preferred = SenseGuideController.PreferredMode(stats)
    local senseDistance = context.SenseTargetDistance or 80
    local actionDistance = context.ActionTargetDistance or 14
    local finder = context.FindNearestEatDrinkTarget
    if type(finder) ~= "function" then return false end

    local target, targetType, distance = finder(context, senseDistance, preferred)
    if not target and preferred ~= nil then
        target, targetType, distance = finder(context, senseDistance)
    end
    local actionableTarget, actionableType, actionableDistance = finder(context, actionDistance, preferred)
    if not actionableTarget and preferred ~= nil then
        actionableTarget, actionableType, actionableDistance = finder(context, actionDistance)
    end
    local displayTarget = actionableTarget or target
    local displayType = actionableType or targetType
    local displayDistance = actionableDistance or distance

    if displayTarget then
        local targetDiet = dietForTarget(displayTarget, stats)
        if hint then
            hint.Text = MobileControlsController:BuildWaypointText(displayType, displayDistance, targetDiet)
            hint:SetAttribute("TargetName", displayTarget.Name)
            hint:SetAttribute("TargetType", displayType)
            hint:SetAttribute("TargetDiet", targetDiet or "")
            hint:SetAttribute("DistanceStuds", math.floor((displayDistance or 0) + 0.5))
            hint:SetAttribute("Actionable", actionableTarget ~= nil)
            hint:SetAttribute("IconOnlyTracker", true)
        end
    elseif hint then
        hint.Text = MobileControlsController:BuildWaypointText("None", nil, stats.diet)
        hint:SetAttribute("TargetName", "")
        hint:SetAttribute("TargetType", "None")
        hint:SetAttribute("TargetDiet", "")
        hint:SetAttribute("Actionable", false)
        hint:SetAttribute("IconOnlyTracker", true)
    end

    if actionableTarget then
        local targetName = context.DescribeTarget and context:DescribeTarget(actionableTarget) or actionableTarget.Name
        local verb = actionableType == "Water" and "DRINK" or "EAT"
        local targetDiet = dietForTarget(actionableTarget, stats)
        local icon = MobileControlsController:BuildTargetIcon(actionableType, targetDiet)
        if eatDrink then
            eatDrink.Text = icon .. " " .. (actionableType == "Water" and "Drink" or "Eat")
            eatDrink:SetAttribute("CurrentTargetName", actionableTarget.Name)
            eatDrink:SetAttribute("CurrentTargetLabel", targetName)
            eatDrink:SetAttribute("CurrentTargetType", actionableType)
            eatDrink:SetAttribute("CurrentTargetDiet", targetDiet or "")
            eatDrink:SetAttribute("CurrentTargetDistanceStuds", math.floor((actionableDistance or 0) + 0.5))
            eatDrink:SetAttribute("ActionVerb", verb)
            MobileControlsController:SetButtonContext(eatDrink, "Nearby")
        end
        if dialogue then
            dialogue.Text = actionableType == "Water" and "💧 → ⭐" or (icon .. " → ⭐")
            dialogue:SetAttribute("IconOnlyTracker", true)
        end
    else
        if eatDrink then
            eatDrink.Text = MobileControlsController:BuildFoodWaterLegend(stats)
            eatDrink:SetAttribute("CurrentTargetName", "")
            eatDrink:SetAttribute("CurrentTargetLabel", "")
            eatDrink:SetAttribute("CurrentTargetType", "None")
            eatDrink:SetAttribute("CurrentTargetDiet", "")
            eatDrink:SetAttribute("CurrentTargetDistanceStuds", 0)
            eatDrink:SetAttribute("ActionVerb", "")
            MobileControlsController:SetButtonContext(eatDrink, target and "Sensed" or "Unavailable")
        end
        if dialogue then
            dialogue.Text = MobileControlsController:BuildFoodWaterLegend(stats)
            dialogue:SetAttribute("IconOnlyTracker", true)
        end
    end
    return true
end

return ActionGuidanceController
