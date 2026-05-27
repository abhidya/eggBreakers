local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIFactory = require(script.Parent.UIFactory)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local HUDController = { LastStats = nil, Bars = {}, ValueLabels = {} }

local stageOrder = { Hatchling = 1, Juvenile = 2, SubAdult = 3, Adult = 4 }

function HUDController:BuildGrowthBadge(payload)
    local stage = tostring(payload.growthStage or "Hatchling")
    local growth = math.clamp(tonumber(payload.growth) or 0, 0, 100)
    local level = stageOrder[stage] or 1
    local nextHint = level >= 4 and "Max level" or string.format("%.0f%% to next stage", math.max(0, 100 - growth))
    return string.format("LV %d %s • %.0f%% growth • %s", level, stage, growth, nextHint)
end

function HUDController:BuildRoleCard(payload)
    local speciesId = tostring(payload.species or "gallimimus")
    local species = SpeciesConfig[speciesId] or SpeciesConfig[string.lower(speciesId)]
    local displayName = species and species.DisplayName or speciesId
    local diet = tostring(payload.diet or (species and species.Diet) or "Unknown diet")
    local role = tostring((species and species.Role) or payload.creatureCategory or "survivor")
    local attack = tostring(species and species.Abilities and species.Abilities.PrimaryAttack or "basic attack")
    return string.format("%s • %s\nRole: %s\nMain action: %s", displayName, diet, role, attack)
end

function HUDController:BuildDietGuidance(payload)
    local species = tostring(payload.species or "Unknown species")
    local diet = tostring(payload.diet or "Unknown diet")
    local growthStage = tostring(payload.growthStage or "Unknown stage")
    local foodHint = "find labeled food"
    if diet == "Herbivore" then
        foodHint = "graze green plant patches"
    elseif diet == "Carnivore" then
        foodHint = "hunt prey or eat red carcass/meat caches"
    elseif diet == "Omnivore" then
        foodHint = "eat safe plants or small prey"
    end
    local category = tostring(payload.creatureCategory or "Ecosystem")
    local movementHint = ""
    local movementModes = payload.movementModes or {}
    if movementModes.Flight or movementModes.flight or movementModes.flying then
        movementHint = " Flight drains stamina."
    elseif movementModes.Swim or movementModes.swim or movementModes.swimming or payload.maxOxygen then
        movementHint = " Watch oxygen in deep water."
    end
    return string.format("%s %s [%s] is a %s — %s, drink blue water.%s", growthStage, species, category, diet, foodHint, movementHint)
end

function HUDController:EnsureGui()
    if self.Gui then return self.Gui end
    local gui = UIFactory:CreateRootGui("MainHUD")
    local root = Instance.new("Frame")
    root.Name = "HUDRoot"
    root.Size = UDim2.fromOffset(430, 232)
    root.Position = UDim2.fromOffset(10, 10)
    root.BackgroundTransparency = 0.35
    root.BackgroundColor3 = Color3.fromRGB(10, 20, 12)
    root.Parent = gui
    self.SpeciesLabel = Instance.new("TextLabel")
    self.SpeciesLabel.Name = "SpeciesLabel"
    self.SpeciesLabel.Size = UDim2.fromOffset(410, 24)
    self.SpeciesLabel.Position = UDim2.fromOffset(10, 4)
    self.SpeciesLabel.BackgroundTransparency = 1
    self.SpeciesLabel.TextColor3 = Color3.new(1,1,1)
    self.SpeciesLabel.TextScaled = true
    self.SpeciesLabel.Text = "Species"
    self.SpeciesLabel.Parent = root
    self.GrowthBadge = Instance.new("TextLabel")
    self.GrowthBadge.Name = "GrowthLevelBadge"
    self.GrowthBadge.Size = UDim2.fromOffset(400, 26)
    self.GrowthBadge.Position = UDim2.fromOffset(10, 28)
    self.GrowthBadge.BackgroundTransparency = 0.2
    self.GrowthBadge.BackgroundColor3 = Color3.fromRGB(26, 72, 40)
    self.GrowthBadge.TextColor3 = Color3.fromRGB(255, 245, 175)
    self.GrowthBadge.TextScaled = true
    self.GrowthBadge.Text = "LV 1 Hatchling • 0% growth"
    self.GrowthBadge:SetAttribute("MobileReadable", true)
    self.GrowthBadge.Parent = root

    self.RoleCard = Instance.new("TextLabel")
    self.RoleCard.Name = "SpeciesRoleCard"
    self.RoleCard.Size = UDim2.fromOffset(400, 52)
    self.RoleCard.Position = UDim2.fromOffset(10, 58)
    self.RoleCard.BackgroundTransparency = 0.2
    self.RoleCard.BackgroundColor3 = Color3.fromRGB(18, 34, 22)
    self.RoleCard.TextColor3 = Color3.fromRGB(230, 255, 230)
    self.RoleCard.TextWrapped = true
    self.RoleCard.TextScaled = true
    self.RoleCard.Text = "Pick a species to see diet, role, and main action."
    self.RoleCard:SetAttribute("MobileReadable", true)
    self.RoleCard.Parent = root

    self.GuidanceLabel = Instance.new("TextLabel")
    self.GuidanceLabel.Name = "DietGuidanceLabel"
    self.GuidanceLabel.Size = UDim2.fromOffset(410, 40)
    self.GuidanceLabel.Position = UDim2.fromOffset(10, 28)
    self.GuidanceLabel.BackgroundTransparency = 1
    self.GuidanceLabel.TextColor3 = Color3.fromRGB(220, 255, 220)
    self.GuidanceLabel.TextWrapped = true
    self.GuidanceLabel.TextScaled = true
    self.GuidanceLabel.Text = "Hatch, then follow glowing FOOD/WATER markers. Eat plants/carcasses, drink blue water, watch stats grow."
    self.GuidanceLabel.Parent = root
    self.LevelBadge = Instance.new("TextLabel")
    self.LevelBadge.Name = "GrowthLevelBadge"
    self.LevelBadge.Size = UDim2.fromOffset(410, 24)
    self.LevelBadge.Position = UDim2.fromOffset(10, 68)
    self.LevelBadge.BackgroundTransparency = 0.2
    self.LevelBadge.BackgroundColor3 = Color3.fromRGB(32, 70, 42)
    self.LevelBadge.TextColor3 = Color3.fromRGB(255, 255, 210)
    self.LevelBadge.TextScaled = true
    self.LevelBadge.Text = "Level 1 Hatchling • Growth 0%"
    self.LevelBadge.Parent = root
    self.StatusDeltaLabel = Instance.new("TextLabel")
    self.StatusDeltaLabel.Name = "StatusDeltaLabel"
    self.StatusDeltaLabel.Size = UDim2.fromOffset(410, 24)
    self.StatusDeltaLabel.Position = UDim2.fromOffset(10, 94)
    self.StatusDeltaLabel.BackgroundTransparency = 1
    self.StatusDeltaLabel.TextColor3 = Color3.fromRGB(180, 245, 255)
    self.StatusDeltaLabel.TextScaled = true
    self.StatusDeltaLabel.Text = "Eat + drink to grow. Sprint spends stamina."
    self.StatusDeltaLabel.Parent = root
    self.Bars.health = UIFactory:CreateBar(root, "Health", 124)
    self.Bars.hunger = UIFactory:CreateBar(root, "Hunger", 146)
    self.Bars.thirst = UIFactory:CreateBar(root, "Thirst", 168)
    self.Bars.stamina = UIFactory:CreateBar(root, "Stamina", 190)
    self.Bars.oxygen = UIFactory:CreateBar(root, "Oxygen", 212)
    self.Bars.growth = UIFactory:CreateBar(root, "Growth", 234)
    root.Size = UDim2.fromOffset(430, 260)
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui
    return gui
end

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

function HUDController:SetBar(name, value)
    local fill = self.Bars[name]
    local percent = math.clamp((value or 0) / 100, 0, 1)
    if fill then
        fill.Size = UDim2.fromScale(percent, 1)
        if percent < 0.25 then
            fill.BackgroundColor3 = Color3.fromRGB(235, 75, 65)
        elseif percent < 0.55 then
            fill.BackgroundColor3 = Color3.fromRGB(230, 170, 60)
        else
            fill.BackgroundColor3 = Color3.fromRGB(82, 200, 120)
        end
        local parent = fill.Parent and fill.Parent.Parent
        local valueLabel = parent and parent:FindFirstChild(name:gsub("^%l", string.upper) .. "ValueLabel")
        if valueLabel then
            valueLabel.Text = tostring(round(value)) .. "%"
            valueLabel:SetAttribute("Value", round(value))
        end
    end
end

function HUDController:BuildDeltaText(previous, current)
    if not previous then return "Find food/water markers. Eat + drink increases growth." end
    local parts = {}
    local function appendDelta(key, label)
        local oldValue = tonumber(previous[key])
        local newValue = tonumber(current[key])
        if oldValue and newValue then
            local delta = round(newValue - oldValue)
            if delta ~= 0 then
                table.insert(parts, string.format("%s%+d", label, delta))
            end
        end
    end
    appendDelta("health", "HP")
    appendDelta("hunger", "Food")
    appendDelta("thirst", "Water")
    appendDelta("stamina", "Stam")
    appendDelta("growth", "Grow")
    if current.sprinting == true then table.insert(parts, "Sprint drains stamina") end
    if #parts == 0 then return "Stats stable. Eat, drink, fight, run, and grow." end
    return table.concat(parts, "  ")
end

function HUDController:ApplyStatUpdate(payload)
    self:EnsureGui()
    local previous = self.LastStats
    self.LastStats = payload
    self.SpeciesLabel.Text = string.format("%s | %s | %s", tostring(payload.species), tostring(payload.diet), tostring(payload.growthStage))
    self.GrowthBadge.Text = self:BuildGrowthBadge(payload)
    self.GrowthBadge:SetAttribute("LevelText", self.GrowthBadge.Text)
    self.RoleCard.Text = self:BuildRoleCard(payload)
    self.RoleCard:SetAttribute("RoleText", self.RoleCard.Text)
    self.GuidanceLabel.Text = self:BuildDietGuidance(payload)
    local level = math.floor((tonumber(payload.growth) or 0) / 25) + 1
    self.LevelBadge.Text = string.format("Level %d %s • Growth %d%% • %s", level, tostring(payload.growthStage or "Hatchling"), round(payload.growth), tostring(payload.diet or "Diet"))
    self.LevelBadge:SetAttribute("Level", level)
    self.StatusDeltaLabel.Text = self:BuildDeltaText(previous, payload)
    self.StatusDeltaLabel:SetAttribute("LastDeltaText", self.StatusDeltaLabel.Text)
    self:SetBar("health", payload.health)
    self:SetBar("hunger", payload.hunger)
    self:SetBar("thirst", payload.thirst)
    self:SetBar("stamina", payload.stamina)
    self:SetBar("oxygen", payload.maxOxygen and payload.maxOxygen > 0 and (payload.oxygen or payload.maxOxygen) / payload.maxOxygen * 100 or 100)
    self:SetBar("growth", payload.growth)
end

Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
    HUDController:ApplyStatUpdate(payload)
end)

return HUDController
