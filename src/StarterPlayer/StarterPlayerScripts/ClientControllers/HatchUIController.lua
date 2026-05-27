local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local HatchUIController = { Progress = 0 }

function HatchUIController:Show()
    if self.Gui then return self.Gui end
    local gui = UIFactory:CreateRootGui("HatchScreen")
    local overlay = Instance.new("Frame")
    overlay.Name = "MuffledOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(32, 22, 12)
    overlay.BackgroundTransparency = 0.2
    overlay.Parent = gui
    local prompt = Instance.new("TextLabel")
    prompt.Name = "InputPrompt"
    prompt.Size = UDim2.fromOffset(420, 60)
    prompt.Position = UDim2.new(0.5, -210, 1, -150)
    prompt.Text = "Tap to crack the shell"
    prompt.TextScaled = true
    prompt.TextColor3 = Color3.new(1, 1, 1)
    prompt.BackgroundTransparency = 1
    prompt.Parent = overlay
    local meter = Instance.new("Frame")
    meter.Name = "CrackMeter"
    meter.Size = UDim2.fromOffset(360, 20)
    meter.Position = UDim2.new(0.5, -180, 1, -85)
    meter.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
    meter.Parent = overlay
    self.Fill = Instance.new("Frame")
    self.Fill.Name = "Fill"
    self.Fill.Size = UDim2.fromScale(0, 1)
    self.Fill.BackgroundColor3 = Color3.fromRGB(245, 230, 160)
    self.Fill.Parent = meter
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return gui
end

function HatchUIController:SetProgress(progress)
    self:Show()
    self.Progress = progress
    self.Fill.Size = UDim2.fromScale(math.clamp(progress / 100, 0, 1), 1)
    if progress >= 100 and self.Gui then self.Gui.Enabled = false end
end

return HatchUIController
