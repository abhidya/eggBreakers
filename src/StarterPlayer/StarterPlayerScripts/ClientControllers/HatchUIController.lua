local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local UIFactory = require(script.Parent.UIFactory)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)

local HatchUIController = { Progress = 0 }
HatchUIController.PromptPosition = UDim2.new(0.5, -210, 1, -470)
HatchUIController.MeterPosition = UDim2.new(0.5, -180, 1, -405)
HatchUIController.PromptSize = UDim2.fromOffset(420, 52)
HatchUIController.MeterSize = UDim2.fromOffset(360, 18)
HatchUIController.SelectorPosition = UDim2.new(0.5, -238, 1, -682)
HatchUIController.SelectorSize = UDim2.fromOffset(476, 162)
HatchUIController.RandomSpeciesOptionId = Constants.RandomStarterSpeciesId
HatchUIController.StarterSpecies = {
    "coelophysis",
    "parasaurolophus",
    "utahraptor",
    "citipati",
    HatchUIController.RandomSpeciesOptionId,
}

local starterRoleText = {
    coelophysis = "fast scavenger",
    parasaurolophus = "safe grazer",
    utahraptor = "pack hunter",
    citipati = "nest forager",
}

local function getViewportSize()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function HatchUIController:GetResponsiveScale(viewport)
    viewport = viewport or getViewportSize()
    if viewport.X >= 900 and viewport.Y >= 540 then return 1, false end
    local scale = math.clamp(math.min(viewport.X / 844, viewport.Y / 390), 0.62, 0.86)
    return scale, true
end

function HatchUIController:GetSpeciesButtonText(speciesId)
    if speciesId == self.RandomSpeciesOptionId then
        local rolled = self.RandomRolledSpeciesId and SpeciesConfig[self.RandomRolledSpeciesId]
        if rolled then
            return string.format("🎲 Random\n%s", rolled.DisplayName or self.RandomRolledSpeciesId)
        end
        return "🎲 Random\nall species"
    end
    local species = SpeciesConfig[speciesId]
    local name = species and species.DisplayName or speciesId
    local diet = species and species.Diet or ""
    local icon = diet == "Carnivore" and "🍖" or (diet == "Omnivore" and "🍽️" or "🌿")
    local role = starterRoleText[speciesId] or (species and species.Role) or "survivor"
    return string.format("%s %s\n%s", icon, name, role)
end

function HatchUIController:Show()
    if self.Gui then return self.Gui end
    local gui = UIFactory:CreateRootGui("HatchScreen")
    local overlay = Instance.new("Frame")
    overlay.Name = "MuffledOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(32, 22, 12)
    overlay.BackgroundTransparency = 0.2
    overlay.Active = true
    overlay.Parent = gui
    local prompt = Instance.new("TextButton")
    prompt.Name = "InputPrompt"
    prompt.Size = self.PromptSize
    prompt.Position = self.PromptPosition
    prompt.Text = "Tap to crack the shell"
    prompt.Font = Enum.Font.FredokaOne
    prompt.TextScaled = true
    prompt.TextColor3 = Color3.new(1, 1, 1)
    prompt.BackgroundTransparency = 1
    prompt.AutoButtonColor = true
    prompt:SetAttribute("HatchInputButton", true)
    prompt.Parent = overlay
    self.Prompt = prompt
    local selector = Instance.new("Frame")
    selector.Name = "SpeciesSelector"
    selector.Size = self.SelectorSize
    selector.Position = self.SelectorPosition
    selector.BackgroundColor3 = Color3.fromRGB(24, 18, 12)
    selector.BackgroundTransparency = 0.12
    selector.Parent = overlay
    UIFactory:RoundCorners(selector, 10)
    UIFactory:AddStroke(selector, Color3.fromRGB(112, 90, 48), 1)
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(230, 46)
    layout.CellPadding = UDim2.fromOffset(8, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = selector
    self.Selector = selector
    self.SelectorLayout = layout
    self.SpeciesButtons = {}
    local meter = Instance.new("Frame")
    meter.Name = "CrackMeter"
    meter.Size = self.MeterSize
    meter.Position = self.MeterPosition
    meter.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
    meter.Parent = overlay
    self.Meter = meter
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
    self:ApplyResponsiveLayout()
    return gui
end

function HatchUIController:ApplyResponsiveLayout()
    if not self.Gui then return false end
    local viewport = getViewportSize()
    local scale, compact = self:GetResponsiveScale(viewport)
    local selector = self.Selector
    local layout = self.SelectorLayout
    local prompt = self.Prompt
    local meter = self.Meter

    if selector and layout then
        if compact then
            local selectorWidth = math.max(300, math.min(476 * scale, viewport.X - 24))
            local columns = selectorWidth < 420 and 2 or 3
            local cellPadding = math.max(5, 8 * scale)
            local cellWidth = math.floor((selectorWidth - cellPadding * (columns + 1)) / columns)
            local cellHeight = math.max(34, 42 * scale)
            local rows = math.ceil((self.CurrentSpeciesOptionCount or #self.StarterSpecies) / columns)
            local selectorHeight = math.max(102, rows * cellHeight + (rows + 1) * cellPadding)
            selector.Size = UDim2.fromOffset(selectorWidth, selectorHeight)
            selector.Position = UDim2.new(0.5, -selectorWidth / 2, 0, math.max(54, math.floor(viewport.Y * 0.08)))
            selector:SetAttribute("MobileSafeLayout", true)
            layout.CellSize = UDim2.fromOffset(cellWidth, cellHeight)
            layout.CellPadding = UDim2.fromOffset(cellPadding, cellPadding)
        else
            selector.Size = self.SelectorSize
            selector.Position = self.SelectorPosition
            selector:SetAttribute("MobileSafeLayout", false)
            layout.CellSize = UDim2.fromOffset(230, 46)
            layout.CellPadding = UDim2.fromOffset(8, 8)
        end
    end

    if prompt then
        if compact then
            local promptWidth = math.max(260, math.min(360 * scale, viewport.X - 36))
            local promptHeight = math.max(42, 52 * scale)
            prompt.Size = UDim2.fromOffset(promptWidth, promptHeight)
            prompt.Position = UDim2.new(0.5, -promptWidth / 2, 1, -math.max(132, 146 * scale))
            prompt:SetAttribute("MobileSafeLayout", true)
        else
            prompt.Size = self.PromptSize
            prompt.Position = self.PromptPosition
            prompt:SetAttribute("MobileSafeLayout", false)
        end
    end

    if meter then
        if compact then
            local meterWidth = math.max(240, math.min(310 * scale, viewport.X - 56))
            meter.Size = UDim2.fromOffset(meterWidth, math.max(12, 16 * scale))
            meter.Position = UDim2.new(0.5, -meterWidth / 2, 1, -math.max(84, 96 * scale))
            meter:SetAttribute("MobileSafeLayout", true)
        else
            meter.Size = self.MeterSize
            meter.Position = self.MeterPosition
            meter:SetAttribute("MobileSafeLayout", false)
        end
    end
    return true
end

function HatchUIController:RequestHatchInput(inputType)
    if self.Gui and self.Gui.Enabled == false then return end
    if self.OnHatchInput then
        self.OnHatchInput(inputType or "tap")
    end
end

function HatchUIController:BindHatchInput(onHatch)
    self:Show()
    self.OnHatchInput = onHatch or self.OnHatchInput
    if self.HatchInputBound then return end
    self.HatchInputBound = true

    local overlay = self.Gui and self.Gui:FindFirstChild("MuffledOverlay")
    local prompt = overlay and overlay:FindFirstChild("InputPrompt")
    if prompt and prompt:IsA("TextButton") then
        prompt.Activated:Connect(function()
            self:RequestHatchInput("tap")
        end)
    end
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Space then
            self:RequestHatchInput("space")
        end
    end)
end

function HatchUIController:SetSpeciesOptions(speciesIds, selectedSpeciesId, onSelect)
    self:Show()
    speciesIds = speciesIds or self.StarterSpecies
    self.CurrentSpeciesOptionCount = #speciesIds
    self.OnSelectSpecies = onSelect or self.OnSelectSpecies
    self.SelectedSpeciesId = selectedSpeciesId or self.SelectedSpeciesId or speciesIds[1]
    local selectedButtonId = self.SelectedSpeciesId
    local selectedInOptions = false
    for _, speciesId in ipairs(speciesIds) do
        if speciesId == self.SelectedSpeciesId then
            selectedInOptions = true
            break
        end
    end
    if not selectedInOptions and SpeciesConfig[self.SelectedSpeciesId] and table.find(speciesIds, self.RandomSpeciesOptionId) then
        self.RandomRolledSpeciesId = self.SelectedSpeciesId
        selectedButtonId = self.RandomSpeciesOptionId
    elseif self.SelectedSpeciesId == self.RandomSpeciesOptionId then
        self.RandomRolledSpeciesId = nil
    end
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
        button.Font = Enum.Font.FredokaOne
        button.TextScaled = true
        button.TextWrapped = true
        button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        button.TextStrokeTransparency = 0.55
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = speciesId == selectedButtonId and Color3.fromRGB(86, 108, 54) or Color3.fromRGB(54, 42, 28)
        button:SetAttribute("SpeciesId", speciesId)
        button:SetAttribute("StarterRole", starterRoleText[speciesId] or "")
        button:SetAttribute("FirstSessionReadable", true)
        button:SetAttribute("RandomFullRoster", speciesId == self.RandomSpeciesOptionId)
        if speciesId == self.RandomSpeciesOptionId and self.RandomRolledSpeciesId then
            button:SetAttribute("RolledSpeciesId", self.RandomRolledSpeciesId)
        end
        UIFactory:RoundCorners(button, 8)
        UIFactory:AddStroke(button, speciesId == selectedButtonId and Color3.fromRGB(245, 230, 160) or Color3.fromRGB(92, 72, 42), speciesId == selectedButtonId and 2 or 1)
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
    self:ApplyResponsiveLayout()
end

function HatchUIController:SetProgress(progress)
    self:Show()
    self.Progress = progress
    self.Fill.Size = UDim2.fromScale(math.clamp(progress / 100, 0, 1), 1)
    if progress >= 100 and self.Gui then self.Gui.Enabled = false end
end

return HatchUIController
