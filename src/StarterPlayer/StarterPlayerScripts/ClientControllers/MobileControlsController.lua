local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local MobileControlsController = {}
MobileControlsController.Buttons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide" }

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
        EatDrink = UDim2.new(1, -290 * scale, 1, -150 * scale),
        Attack = UDim2.new(1, -195 * scale, 1, -150 * scale),
        Sprint = UDim2.new(1, -100 * scale, 1, -150 * scale),
        Call = UDim2.new(1, -195 * scale, 1, -95 * scale),
        RestHide = UDim2.new(1, -100 * scale, 1, -95 * scale),
    }
    local thumbstick = Instance.new("Frame")
    thumbstick.Name = "MoveThumbstick"
    thumbstick.Size = UDim2.fromOffset(110 * scale, 110 * scale)
    thumbstick.Position = UDim2.new(0, 25, 1, -140 * scale)
    thumbstick.BackgroundTransparency = 0.5
    thumbstick.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    thumbstick.Parent = gui
    for name, position in pairs(positions) do
        local button = UIFactory:CreateButton(gui, name .. "Button", name, position)
        button:SetAttribute("ActionName", name)
    end
    local feedback = Instance.new("TextLabel")
    feedback.Name = "ActionFeedbackLabel"
    feedback.Size = UDim2.fromOffset(260 * scale, 34 * scale)
    feedback.Position = UDim2.new(1, -290 * scale, 1, -205 * scale)
    feedback.BackgroundTransparency = 0.25
    feedback.BackgroundColor3 = Color3.fromRGB(20, 35, 24)
    feedback.TextColor3 = Color3.new(1, 1, 1)
    feedback.TextScaled = true
    feedback.Visible = false
    feedback.Parent = gui
    self:WireVisibleButtonEffects(gui)
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return { Gui = gui, Buttons = self.Buttons, Scale = scale }
end

return MobileControlsController
