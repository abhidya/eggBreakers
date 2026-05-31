local Players = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local HatchUIController = { Progress = 0 }
HatchUIController.PromptPosition = UDim2.new(0.5, -210, 1, -470)
HatchUIController.MeterPosition = UDim2.new(0.5, -180, 1, -405)
HatchUIController.PromptSize = UDim2.fromOffset(420, 52)
HatchUIController.MeterSize = UDim2.fromOffset(360, 18)
HatchUIController.SelectorPosition = UDim2.new(0.5, -230, 1, -560)
HatchUIController.SelectorSize = UDim2.fromOffset(460, 72)
HatchUIController.StarterSpecies = { "gallimimus", "triceratops", "velociraptor", "carnotaurus" }

function HatchUIController:GetSpeciesButtonText(speciesId)
    local species = SpeciesConfig[speciesId]
    local name = species and species.DisplayName or speciesId
    local diet = species and species.Diet or ""
    local icon = diet == "Carnivore" and "🍖" or (diet == "Omnivore" and "🍽️" or "🌿")
    return string.format("%s %s", icon, name)
end

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
    prompt.Size = self.PromptSize
    prompt.Position = self.PromptPosition
    prompt.Text = "Tap to crack the shell"
    prompt.TextScaled = true
    prompt.TextColor3 = Color3.new(1, 1, 1)
    prompt.BackgroundTransparency = 1
    prompt.Parent = overlay
    local selector = Instance.new("Frame")
    selector.Name = "SpeciesSelector"
    selector.Size = self.SelectorSize
    selector.Position = self.SelectorPosition
    selector.BackgroundColor3 = Color3.fromRGB(24, 18, 12)
    selector.BackgroundTransparency = 0.12
    selector.Parent = overlay
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(220, 30)
    layout.CellPadding = UDim2.fromOffset(8, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = selector
    self.Selector = selector
    self.SpeciesButtons = {}
    local meter = Instance.new("Frame")
    meter.Name = "CrackMeter"
    meter.Size = self.MeterSize
    meter.Position = self.MeterPosition
    meter.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
    meter.Parent = overlay
    self.Fill = Instance.new("Frame")
    self.Fill.Name = "Fill"
    self.Fill.Size = UDim2.fromScale(0, 1)
    self.Fill.BackgroundColor3 = Color3.fromRGB(245, 230, 160)
    self.Fill.Parent = meter
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        gui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
    self.Gui = gui
    return gui
end

function HatchUIController:SetSpeciesOptions(speciesIds, selectedSpeciesId, onSelect)
    self:Show()
    speciesIds = speciesIds or self.StarterSpecies
    self.OnSelectSpecies = onSelect or self.OnSelectSpecies
    self.SelectedSpeciesId = selectedSpeciesId or self.SelectedSpeciesId or speciesIds[1]
    for _, child in ipairs(self.Selector:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    self.SpeciesButtons = {}
    for index, speciesId in ipairs(speciesIds) do
        local button = Instance.new("TextButton")
        button.Name = "Species_" .. speciesId
        button.LayoutOrder = index
        button.Text = self:GetSpeciesButtonText(speciesId)
        button.TextScaled = true
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = speciesId == self.SelectedSpeciesId and Color3.fromRGB(86, 108, 54) or Color3.fromRGB(54, 42, 28)
        button:SetAttribute("SpeciesId", speciesId)
        button.Parent = self.Selector
        button.Activated:Connect(function()
            self.SelectedSpeciesId = speciesId
            self:SetSpeciesOptions(speciesIds, speciesId, self.OnSelectSpecies)
            if self.OnSelectSpecies then
                self.OnSelectSpecies(speciesId)
            end
        end)
        self.SpeciesButtons[speciesId] = button
    end
end

function HatchUIController:SetProgress(progress)
    self:Show()
    self.Progress = progress
    self.Fill.Size = UDim2.fromScale(math.clamp(progress / 100, 0, 1), 1)
    if progress >= 100 and self.Gui then self.Gui.Enabled = false end
end

return HatchUIController
