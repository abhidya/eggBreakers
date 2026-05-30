local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local MobileControlsController = {}
MobileControlsController.Buttons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide" }
MobileControlsController.OptionalButtons = { "Flight", "Swim" }

MobileControlsController.DefaultButtonColor = Color3.fromRGB(35, 45, 35)
MobileControlsController.EffectStyles = {
    EatDrink = { ActiveText = "Snack!", ActiveColor = Color3.fromRGB(66, 140, 82) },
    Attack = { ActiveText = "Chomp!", ActiveColor = Color3.fromRGB(190, 78, 62) },
    Sprint = { ActiveText = "Zoom!", ActiveColor = Color3.fromRGB(72, 128, 255) },
    Call = { ActiveText = "Roar!", ActiveColor = Color3.fromRGB(255, 196, 76) },
    RestHide = { ActiveText = "Cozy", ActiveColor = Color3.fromRGB(56, 92, 68) },
    Flight = { ActiveText = "Flying", ActiveColor = Color3.fromRGB(96, 170, 255) },
    Swim = { ActiveText = "Swimming", ActiveColor = Color3.fromRGB(56, 160, 210) },
}

function MobileControlsController:BuildWaypointText(targetType, distance)
    if not targetType or targetType == "None" then return "↗ 🍎  💧" end
    local icon = targetType == "Water" and "💧" or "🍎"
    return string.format("↗ %s %.0fm", icon, distance or 0)
end

function MobileControlsController:BuildFoodWaterLegend(stats)
    stats = stats or {}
    local foodLow = (tonumber(stats.hunger) or 100) <= (tonumber(stats.thirst) or 100)
    return foodLow and "🍎 + 💧 = ⭐" or "💧 + 🍎 = ⭐"
end

function MobileControlsController:SetButtonEffect(button, actionName, active)
    local style = self.EffectStyles[actionName]
    if not button or not style then return false end
    button:SetAttribute("EffectActive", active == true)
    button.BackgroundColor3 = active and style.ActiveColor or self.DefaultButtonColor
    button.Text = active and style.ActiveText or (button:GetAttribute("DefaultText") or actionName)
    return true
end

function MobileControlsController:FlashButtonEffect(button, actionName, durationSeconds)
    if not self:SetButtonEffect(button, actionName, true) then return false end
    task.delay(durationSeconds or 0.35, function()
        if button and button.Parent then
            self:SetButtonEffect(button, actionName, false)
        end
    end)
    return true
end

function MobileControlsController:WireVisibleButtonEffects(gui)
    if not gui then return false end
    local sprint = gui:FindFirstChild("SprintButton")
    if sprint then
        sprint.MouseButton1Down:Connect(function() self:SetButtonEffect(sprint, "Sprint", true) end)
        sprint.MouseButton1Up:Connect(function() self:SetButtonEffect(sprint, "Sprint", false) end)
        sprint.MouseLeave:Connect(function() self:SetButtonEffect(sprint, "Sprint", false) end)
    end
    local call = gui:FindFirstChild("CallButton")
    if call then
        call.Activated:Connect(function() self:FlashButtonEffect(call, "Call") end)
    end
    local restHide = gui:FindFirstChild("RestHideButton")
    if restHide then
        restHide.MouseButton1Down:Connect(function() self:SetButtonEffect(restHide, "RestHide", true) end)
        restHide.MouseButton1Up:Connect(function() self:SetButtonEffect(restHide, "RestHide", false) end)
        restHide.MouseLeave:Connect(function() self:SetButtonEffect(restHide, "RestHide", false) end)
    end
    return true
end


function MobileControlsController:CreateControls(settings)
    if self.Gui then return self.Gui end
    local scale = settings and settings.MobileButtonScale or 1.0
    local gui = UIFactory:CreateRootGui("MobileControls")
    local buttonSize = UDim2.fromOffset(82 * scale, 58 * scale)
    local positions = {
        EatDrink = UDim2.new(1, -274 * scale, 1, -142 * scale),
        Attack = UDim2.new(1, -184 * scale, 1, -142 * scale),
        Sprint = UDim2.new(1, -94 * scale, 1, -142 * scale),
        Call = UDim2.new(1, -184 * scale, 1, -76 * scale),
        RestHide = UDim2.new(1, -94 * scale, 1, -76 * scale),
        Flight = UDim2.new(1, -184 * scale, 1, -208 * scale),
        Swim = UDim2.new(1, -94 * scale, 1, -208 * scale),
    }
    local thumbstick = Instance.new("Frame")
    thumbstick.Name = "MoveThumbstick"
    thumbstick.Size = UDim2.fromOffset(120 * scale, 120 * scale)
    thumbstick.Position = UDim2.new(0, 24, 1, -146 * scale)
    thumbstick.BackgroundTransparency = 0.5
    thumbstick.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    thumbstick.Parent = gui
    local labels = {
        EatDrink = "🍎 Snack",
        Attack = "🦷 Chomp",
        Sprint = "⚡ Zoom",
        Call = "📣 Roar",
        RestHide = "🌿 Rest",
        Flight = "🪽 Fly",
        Swim = "🌊 Swim",
    }
    local icons = {
        EatDrink = "🍎",
        Attack = "🦷",
        Sprint = "⚡",
        Call = "📣",
        RestHide = "🌿",
        Flight = "🪽",
        Swim = "🌊",
    }
    for name, position in pairs(positions) do
        local button = UIFactory:CreateButton(gui, name .. "Button", labels[name] or name, position)
        button.Size = buttonSize
        button:SetAttribute("ActionName", name)
        button:SetAttribute("DefaultText", labels[name] or name)
        button:SetAttribute("KidIcon", icons[name] or "")
        button:SetAttribute("MobileReadable", true)
        button:SetAttribute("OptionalAction", name == "Flight" or name == "Swim")
        if name == "Flight" or name == "Swim" then
            button.Visible = false
            button.Active = false
            button.AutoButtonColor = false
        end
    end
    local dialogue = Instance.new("TextLabel")
    dialogue.Name = "DialoguePromptLabel"
    dialogue.Size = UDim2.fromOffset(168 * scale, 34 * scale)
    dialogue.Position = UDim2.new(0.5, -84 * scale, 1, -332 * scale)
    dialogue.BackgroundTransparency = 0.1
    dialogue.BackgroundColor3 = Color3.fromRGB(16, 28, 20)
    dialogue.TextColor3 = Color3.fromRGB(240, 255, 220)
    dialogue.TextScaled = true
    dialogue.TextWrapped = true
    dialogue.Text = "🍎 + 💧 = ⭐"
    dialogue:SetAttribute("GuidesToActionableAssets", true)
    dialogue:SetAttribute("IconOnlyTracker", true)
    dialogue:SetAttribute("ProductionKidGuidance", true)
    dialogue.Parent = gui
    local targetHint = Instance.new("TextLabel")
    targetHint.Name = "NearestActionHintLabel"
    targetHint.Size = UDim2.fromOffset(168 * scale, 56 * scale)
    targetHint.Position = UDim2.new(0.5, -84 * scale, 1, -286 * scale)
    targetHint.BackgroundTransparency = 0.04
    targetHint.BackgroundColor3 = Color3.fromRGB(24, 54, 34)
    targetHint.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetHint.TextScaled = true
    targetHint.TextWrapped = true
    targetHint.Text = "↗ 🍎  💧"
    targetHint:SetAttribute("NonNpcActionHint", true)
    targetHint:SetAttribute("IconOnlyTracker", true)
    targetHint:SetAttribute("FloatsAboveActionButtons", true)
    targetHint.Parent = gui
    local feedback = Instance.new("TextLabel")
    feedback.Name = "ActionFeedbackLabel"
    feedback.Size = UDim2.fromOffset(180 * scale, 40 * scale)
    feedback.Position = UDim2.new(0.5, -90 * scale, 1, -236 * scale)
    feedback.BackgroundTransparency = 0.1
    feedback.BackgroundColor3 = Color3.fromRGB(20, 35, 24)
    feedback.TextColor3 = Color3.new(1, 1, 1)
    feedback.TextScaled = true
    feedback.Visible = false
    feedback:SetAttribute("MobileReadable", true)
    feedback:SetAttribute("LastFeedback", "")
    feedback.Parent = gui
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return { Gui = gui, Buttons = self.Buttons, OptionalButtons = self.OptionalButtons, Scale = scale }
end

return MobileControlsController
