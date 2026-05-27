local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local MobileControlsController = {}
MobileControlsController.Buttons = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide" }

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
        UIFactory:CreateButton(gui, name .. "Button", name, position)
    end
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return { Gui = gui, Buttons = self.Buttons, Scale = scale }
end

return MobileControlsController
