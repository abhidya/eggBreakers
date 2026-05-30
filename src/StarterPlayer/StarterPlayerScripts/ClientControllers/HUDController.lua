local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIFactory = require(script.Parent.UIFactory)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local HUDController = { LastStats = nil, Bars = {}, ValueLabels = {} }

local stageOrder = { Hatchling = 1, Juvenile = 2, SubAdult = 3, Adult = 4 }
local dietIcons = { Herbivore = "🌿", Carnivore = "🍖", Omnivore = "🌿🍖" }

function HUDController:GetSpeciesDisplayName(speciesId)
    local id = tostring(speciesId or "gallimimus")
    local species = SpeciesConfig[id] or SpeciesConfig[string.lower(id)]
    return species and species.DisplayName or id
end

function HUDController:BuildGrowthBadge(payload)
    local stage = tostring(payload.growthStage or "Hatchling")
    local growth = math.clamp(tonumber(payload.growth) or 0, 0, 100)
    local level = stageOrder[stage] or 1
    local nextHint = level >= 4 and "★" or "→"
    return string.format("⭐ LV %d  %.0f%% %s", level, growth, nextHint)
end

function HUDController:BuildRoleCard(payload)
    local speciesId = tostring(payload.species or "gallimimus")
    local species = SpeciesConfig[speciesId] or SpeciesConfig[string.lower(speciesId)]
    local displayName = species and species.DisplayName or speciesId
    local diet = tostring(payload.diet or (species and species.Diet) or "Food")
    local attack = tostring(species and species.Abilities and species.Abilities.PrimaryAttack or "Nibble")
    return string.format("🦖 %s  %s  🦷 %s", displayName, dietIcons[diet] or "🍽️", attack)
end
function HUDController:BuildDietGuidance(payload)
    local diet = tostring(payload.diet or "Food")
    local foodIcon = "🍽️"
    if diet == "Herbivore" then
        foodIcon = "🌿"
    elseif diet == "Carnivore" then
        foodIcon = "🍖"
    elseif diet == "Omnivore" then
        foodIcon = "🌿🍖"
    end
    local movementModes = payload.movementModes or {}
    local movementHint = "⭐"
    if movementModes.Flight or movementModes.flight or movementModes.flying then
        movementHint = "🪽⚡"
    elseif movementModes.Swim or movementModes.swim or movementModes.swimming then
        movementHint = "🌊🫧"
    end
    return string.format("%s + 💧 = %s", foodIcon, movementHint)
end

function HUDController:EnsureGui()
    if self.Gui then return self.Gui end
    local gui = UIFactory:CreateRootGui("MainHUD")
    local root = Instance.new("Frame")
    root.Name = "HUDRoot"
    root.Size = UDim2.fromOffset(338, 242)
    root.Position = UDim2.fromOffset(10, 10)
    root.BackgroundTransparency = 0.18
    root.BackgroundColor3 = Color3.fromRGB(8, 24, 16)
    root:SetAttribute("CompactKidHUD", true)
    root.Parent = gui
    self.SpeciesLabel = Instance.new("TextLabel")
    self.SpeciesLabel.Name = "SpeciesLabel"
    self.SpeciesLabel.Size = UDim2.fromOffset(318, 22)
    self.SpeciesLabel.Position = UDim2.fromOffset(10, 4)
    self.SpeciesLabel.BackgroundTransparency = 1
    self.SpeciesLabel.TextColor3 = Color3.new(1,1,1)
    self.SpeciesLabel.TextScaled = true
    self.SpeciesLabel.Text = "🦖 Dino"
    self.SpeciesLabel.Parent = root
    self.GrowthBadge = Instance.new("TextLabel")
    self.GrowthBadge.Name = "GrowthLevelBadge"
    self.GrowthBadge.Size = UDim2.fromOffset(154, 30)
    self.GrowthBadge.Position = UDim2.fromOffset(10, 30)
    self.GrowthBadge.BackgroundTransparency = 0.05
    self.GrowthBadge.BackgroundColor3 = Color3.fromRGB(38, 96, 48)
    self.GrowthBadge.TextColor3 = Color3.fromRGB(255, 245, 175)
    self.GrowthBadge.TextScaled = true
    self.GrowthBadge.Text = "⭐ LV 1  0% →"
    self.GrowthBadge:SetAttribute("MobileReadable", true)
    self.GrowthBadge.Parent = root

    self.RoleCard = Instance.new("TextLabel")
    self.RoleCard.Name = "SpeciesRoleCard"
    self.RoleCard.Size = UDim2.fromOffset(160, 30)
    self.RoleCard.Position = UDim2.fromOffset(168, 30)
    self.RoleCard.BackgroundTransparency = 0.05
    self.RoleCard.BackgroundColor3 = Color3.fromRGB(18, 34, 22)
    self.RoleCard.TextColor3 = Color3.fromRGB(230, 255, 230)
    self.RoleCard.TextWrapped = true
    self.RoleCard.TextScaled = true
    self.RoleCard.Text = "Pick a dino"
    self.RoleCard:SetAttribute("MobileReadable", true)
    self.RoleCard.Parent = root

    self.GuidanceLabel = Instance.new("TextLabel")
    self.GuidanceLabel.Name = "DietGuidanceLabel"
    self.GuidanceLabel.Size = UDim2.fromOffset(154, 32)
    self.GuidanceLabel.Position = UDim2.fromOffset(10, 66)
    self.GuidanceLabel.BackgroundTransparency = 1
    self.GuidanceLabel.TextColor3 = Color3.fromRGB(220, 255, 220)
    self.GuidanceLabel.TextWrapped = true
    self.GuidanceLabel.TextScaled = true
    self.GuidanceLabel.Text = "🌿 + 💧 = ⭐"
    self.GuidanceLabel:SetAttribute("IconOnlyTracker", true)
    self.GuidanceLabel.Parent = root
    self.StatusDeltaLabel = Instance.new("TextLabel")
    self.StatusDeltaLabel.Name = "StatusDeltaLabel"
    self.StatusDeltaLabel.Size = UDim2.fromOffset(160, 32)
    self.StatusDeltaLabel.Position = UDim2.fromOffset(168, 66)
    self.StatusDeltaLabel.BackgroundTransparency = 1
    self.StatusDeltaLabel.TextColor3 = Color3.fromRGB(180, 245, 255)
    self.StatusDeltaLabel.TextScaled = true
    self.StatusDeltaLabel.Text = "🍎 + 💧 → ⭐"
    self.StatusDeltaLabel:SetAttribute("IconOnlyTracker", true)
    self.StatusDeltaLabel.Parent = root
    local barOptions = {
        LabelX = 12,
        LabelWidth = 44,
        BarX = 62,
        BarWidth = 188,
        ValueX = 256,
        ValueWidth = 60,
        Height = 18,
        BarHeight = 12,
        BarYOffset = 3,
    }
    self.Bars.health = UIFactory:CreateBar(root, "Health", 112, barOptions)
    self.Bars.hunger = UIFactory:CreateBar(root, "Hunger", 132, barOptions)
    self.Bars.thirst = UIFactory:CreateBar(root, "Thirst", 152, barOptions)
    self.Bars.stamina = UIFactory:CreateBar(root, "Stamina", 172, barOptions)
    self.Bars.oxygen = UIFactory:CreateBar(root, "Oxygen", 192, barOptions)
    self.Bars.growth = UIFactory:CreateBar(root, "Growth", 212, barOptions)
    root.HealthLabel.Text = "❤️"
    root.HungerLabel.Text = "🍎"
    root.ThirstLabel.Text = "💧"
    root.StaminaLabel.Text = "⚡"
    root.OxygenLabel.Text = "🫧"
    root.GrowthLabel.Text = "⭐"
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
    if not previous then return "↗ 🍎 + 💧 → ⭐" end
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
    appendDelta("hunger", "🍎")
    appendDelta("thirst", "💧")
    appendDelta("stamina", "⚡")
    appendDelta("growth", "⭐")
    if current.sprinting == true then table.insert(parts, "⚡↓") end
    if #parts == 0 then return "🍎 + 💧 → ⭐" end
    return table.concat(parts, "  ")
end

function HUDController:ApplyStatUpdate(payload)
    self:EnsureGui()
    local previous = self.LastStats
    self.LastStats = payload
    self.SpeciesLabel.Text = string.format("🦖 %s", self:GetSpeciesDisplayName(payload.species))
    self.GrowthBadge.Text = self:BuildGrowthBadge(payload)
    self.GrowthBadge:SetAttribute("LevelText", self.GrowthBadge.Text)
    self.RoleCard.Text = self:BuildRoleCard(payload)
    self.RoleCard:SetAttribute("RoleText", self.RoleCard.Text)
    self.GuidanceLabel.Text = self:BuildDietGuidance(payload)
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
