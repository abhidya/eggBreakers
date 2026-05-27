local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local MobileControlsController = {}
MobileControlsController.Buttons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide", "Flight", "Swim" }

MobileControlsController.DefaultButtonColor = Color3.fromRGB(35, 45, 35)
MobileControlsController.EffectStyles = {
    Sprint = { ActiveText = "Sprint!", ActiveColor = Color3.fromRGB(72, 128, 255) },
    Call = { ActiveText = "Calling", ActiveColor = Color3.fromRGB(255, 196, 76) },
    RestHide = { ActiveText = "Hidden", ActiveColor = Color3.fromRGB(56, 92, 68) },
}

function MobileControlsController:SetButtonEffect(button, actionName, active)
    local style = self.EffectStyles[actionName]
    if not button or not style then return false end
    button:SetAttribute("EffectActive", active == true)
    button.BackgroundColor3 = active and style.ActiveColor or self.DefaultButtonColor
    button.Text = active and style.ActiveText or actionName
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
    local positions = {
        EatDrink = UDim2.new(1, -368 * scale, 1, -170 * scale),
        Attack = UDim2.new(1, -246 * scale, 1, -170 * scale),
        Sprint = UDim2.new(1, -124 * scale, 1, -170 * scale),
        Call = UDim2.new(1, -368 * scale, 1, -96 * scale),
        RestHide = UDim2.new(1, -246 * scale, 1, -96 * scale),
        Flight = UDim2.new(1, -124 * scale, 1, -96 * scale),
        Swim = UDim2.new(1, -124 * scale, 1, -244 * scale),
    }
    local thumbstick = Instance.new("Frame")
    thumbstick.Name = "MoveThumbstick"
    thumbstick.Size = UDim2.fromOffset(110 * scale, 110 * scale)
    thumbstick.Position = UDim2.new(0, 25, 1, -140 * scale)
    thumbstick.BackgroundTransparency = 0.5
    thumbstick.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    thumbstick.Parent = gui
    local labels = {
        EatDrink = "EAT / DRINK\nfind marker",
        Attack = "ATTACK\nnearest dino",
        Sprint = "SPRINT\nuses stamina",
        Call = "CALL\nsignal herd",
        RestHide = "HIDE/REST\nsafe spot",
        Flight = "FLY\nstamina",
        Swim = "SWIM\noxygen",
    }
    for name, position in pairs(positions) do
        local button = UIFactory:CreateButton(gui, name .. "Button", labels[name] or name, position)
        button:SetAttribute("ActionName", name)
        button:SetAttribute("DefaultText", labels[name] or name)
    end
    local dialogue = Instance.new("TextLabel")
    dialogue.Name = "DialoguePromptLabel"
    dialogue.Size = UDim2.fromOffset(360 * scale, 52 * scale)
    dialogue.Position = UDim2.new(0.5, -180 * scale, 1, -238 * scale)
    dialogue.BackgroundTransparency = 0.18
    dialogue.BackgroundColor3 = Color3.fromRGB(16, 28, 20)
    dialogue.TextColor3 = Color3.fromRGB(240, 255, 220)
    dialogue.TextScaled = true
    dialogue.TextWrapped = true
    dialogue.Text = "Guide: follow FOOD / WATER markers. Eat plants or carcasses, drink blue water."
    dialogue:SetAttribute("GuidesToActionableAssets", true)
    dialogue.Parent = gui
    local targetHint = Instance.new("TextLabel")
    targetHint.Name = "NearestActionHintLabel"
    targetHint.Size = UDim2.fromOffset(360 * scale, 38 * scale)
    targetHint.Position = UDim2.new(0.5, -180 * scale, 1, -294 * scale)
    targetHint.BackgroundTransparency = 0.15
    targetHint.BackgroundColor3 = Color3.fromRGB(32, 44, 28)
    targetHint.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetHint.TextScaled = true
    targetHint.TextWrapped = true
    targetHint.Text = "Nearest: scanning for real food/water..."
    targetHint:SetAttribute("NonNpcActionHint", true)
    targetHint.Parent = gui
    local feedback = Instance.new("TextLabel")
    feedback.Name = "ActionFeedbackLabel"
    feedback.Size = UDim2.fromOffset(360 * scale, 42 * scale)
    feedback.Position = UDim2.new(0.5, -180 * scale, 1, -352 * scale)
    feedback.BackgroundTransparency = 0.25
    feedback.BackgroundColor3 = Color3.fromRGB(20, 35, 24)
    feedback.TextColor3 = Color3.new(1, 1, 1)
    feedback.TextScaled = true
    feedback.Visible = false
    feedback.Parent = gui
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return { Gui = gui, Buttons = self.Buttons, Scale = scale }
end

return MobileControlsController
