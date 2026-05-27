local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIFactory = require(script.Parent.UIFactory)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local HUDController = { LastStats = nil, Bars = {} }

function HUDController:EnsureGui()
    if self.Gui then return self.Gui end
    local gui = UIFactory:CreateRootGui("MainHUD")
    local root = Instance.new("Frame")
    root.Name = "HUDRoot"
    root.Size = UDim2.fromOffset(340, 150)
    root.Position = UDim2.fromOffset(10, 10)
    root.BackgroundTransparency = 0.35
    root.BackgroundColor3 = Color3.fromRGB(10, 20, 12)
    root.Parent = gui
    self.SpeciesLabel = Instance.new("TextLabel")
    self.SpeciesLabel.Name = "SpeciesLabel"
    self.SpeciesLabel.Size = UDim2.fromOffset(320, 22)
    self.SpeciesLabel.Position = UDim2.fromOffset(10, 4)
    self.SpeciesLabel.BackgroundTransparency = 1
    self.SpeciesLabel.TextColor3 = Color3.new(1,1,1)
    self.SpeciesLabel.TextScaled = true
    self.SpeciesLabel.Text = "Species"
    self.SpeciesLabel.Parent = root
    self.Bars.health = UIFactory:CreateBar(root, "Health", 30)
    self.Bars.hunger = UIFactory:CreateBar(root, "Hunger", 52)
    self.Bars.thirst = UIFactory:CreateBar(root, "Thirst", 74)
    self.Bars.stamina = UIFactory:CreateBar(root, "Stamina", 96)
    self.Bars.growth = UIFactory:CreateBar(root, "Growth", 118)
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return gui
end

function HUDController:SetBar(name, value)
    local fill = self.Bars[name]
    if fill then fill.Size = UDim2.fromScale(math.clamp((value or 0) / 100, 0, 1), 1) end
end

function HUDController:ApplyStatUpdate(payload)
    self:EnsureGui()
    self.LastStats = payload
    self.SpeciesLabel.Text = string.format("%s | %s | %s", tostring(payload.species), tostring(payload.diet), tostring(payload.growthStage))
    self:SetBar("health", payload.health)
    self:SetBar("hunger", payload.hunger)
    self:SetBar("thirst", payload.thirst)
    self:SetBar("stamina", payload.stamina)
    self:SetBar("growth", payload.growth)
end

Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
    HUDController:ApplyStatUpdate(payload)
end)

return HUDController
