-- HUDController: survival HUD for eggBreakers.
-- Displays Health, Hunger, Thirst, Stamina, Oxygen (hidden when not relevant),
-- and a growth-stage progress indicator.  Kid-friendly: icon-led, minimal text,
-- colour-coded bars (green → amber → red).
--
-- Public API (stable – do NOT remove or rename):
--   HUDController:GetSpeciesDisplayName(speciesId) -> string
--   HUDController:BuildGrowthBadge(payload)        -> string
--   HUDController:BuildRoleCard(payload)            -> string
--   HUDController:BuildDietGuidance(payload)        -> string
--   HUDController:BuildDeltaText(previous, current) -> string
--   HUDController:ApplyStatUpdate(payload)
--   HUDController:SetBar(name, value)
--   HUDController:EnsureGui()                       -> gui

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIFactory         = require(script.Parent.UIFactory)
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local SpeciesConfig     = require(ReplicatedStorage.Shared.SpeciesConfig)

local HUDController = { LastStats = nil, Bars = {}, ValueLabels = {} }

-- ── Constants ────────────────────────────────────────────────────────────────

local stageOrder = { Hatchling = 1, Juvenile = 2, SubAdult = 3, Adult = 4 }
local dietIcons  = { Herbivore = "🌿", Carnivore = "🍖", Omnivore = "🌿🍖" }

-- HUD panel layout
local PANEL_W    = 338
local PANEL_H    = 256  -- slightly taller to breathe
local PANEL_PAD  = 10

-- Bar row layout (icon | [====bar====] | 75%)
local BAR_OPTS = {
    LabelX     = 12,
    LabelWidth  = 44,
    BarX        = 60,
    BarWidth    = 194,
    ValueX      = 260,
    ValueWidth  = 60,
    Height      = 18,
    BarHeight   = 13,
    BarYOffset  = 3,
}

-- Rows are stacked from this Y down
local BAR_START_Y = 108
local BAR_STEP    = 22

-- ── Pure helpers ──────────────────────────────────────────────────────────────

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function HUDController:GetSpeciesDisplayName(speciesId)
    local id      = tostring(speciesId or "gallimimus")
    local species = SpeciesConfig[id] or SpeciesConfig[string.lower(id)]
    return species and species.DisplayName or id
end

-- Returns a compact growth badge string: "⭐ LV 2  45% →"
-- Tests assert: LV matches stageOrder, percent matches, "→" for non-Adult, "★" for Adult.
function HUDController:BuildGrowthBadge(payload)
    local stage   = tostring(payload.growthStage or "Hatchling")
    local growth  = math.clamp(tonumber(payload.growth) or 0, 0, 100)
    local level   = stageOrder[stage] or 1
    local nextHint = level >= 4 and "★" or "→"
    return string.format("⭐ LV %d  %.0f%% %s", level, growth, nextHint)
end

-- Returns a compact species role card: "🦖 Velociraptor  🍖  🦷 Claw"
-- Tests assert: DisplayName, diet icon, no "Carnivore" word, no "Role:" label.
function HUDController:BuildRoleCard(payload)
    local speciesId   = tostring(payload.species or "gallimimus")
    local species     = SpeciesConfig[speciesId] or SpeciesConfig[string.lower(speciesId)]
    local displayName = species and species.DisplayName or speciesId
    local diet        = tostring(payload.diet or (species and species.Diet) or "Food")
    local attack      = tostring(
        species and species.Abilities and species.Abilities.PrimaryAttack or "Nibble"
    )
    return string.format("🦖 %s  %s  🦷 %s", displayName, dietIcons[diet] or "🍽️", attack)
end

-- Returns icon-only diet + movement guidance: "🌿 + 💧 = ⭐"
-- Tests assert: food icon present, water icon present, no long-form words.
function HUDController:BuildDietGuidance(payload)
    local diet     = tostring(payload.diet or "Food")
    local foodIcon = dietIcons[diet] or "🍽️"
    local movementModes = payload.movementModes or {}
    local moveHint
    if movementModes.Flight or movementModes.flight or movementModes.flying then
        moveHint = "🪽⚡"
    elseif movementModes.Swim or movementModes.swim or movementModes.swimming then
        moveHint = "🌊🫧"
    else
        moveHint = "⭐"
    end
    return string.format("%s + 💧 = %s", foodIcon, moveHint)
end

-- Returns a compact delta string showing what changed since the last tick.
-- Tests assert icon+delta strings like "🍎+25", "💧+35", "⚡-10", "⭐+8", "⚡↓".
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
    appendDelta("health",  "HP")
    appendDelta("hunger",  "🍎")
    appendDelta("thirst",  "💧")
    appendDelta("stamina", "⚡")
    appendDelta("growth",  "⭐")
    if current.sprinting == true then table.insert(parts, "⚡↓") end
    if #parts == 0 then return "🍎 + 💧 → ⭐" end
    return table.concat(parts, "  ")
end

-- ── GUI construction ──────────────────────────────────────────────────────────

function HUDController:EnsureGui()
    if self.Gui then return self.Gui end

    local gui  = UIFactory:CreateRootGui("MainHUD")
    local root = UIFactory:CreatePanel(
        gui, "HUDRoot",
        UDim2.fromOffset(PANEL_W, PANEL_H),
        UDim2.fromOffset(PANEL_PAD, PANEL_PAD)
    )
    root:SetAttribute("CompactKidHUD", true)

    -- ── Row 1: species name ────────────────────────────────────────────────
    self.SpeciesLabel              = Instance.new("TextLabel")
    self.SpeciesLabel.Name         = "SpeciesLabel"
    self.SpeciesLabel.Size         = UDim2.fromOffset(PANEL_W - 20, 22)
    self.SpeciesLabel.Position     = UDim2.fromOffset(10, 6)
    self.SpeciesLabel.BackgroundTransparency = 1
    self.SpeciesLabel.TextColor3   = UIFactory.Colors.TextPrimary
    self.SpeciesLabel.TextScaled   = true
    self.SpeciesLabel.Text         = "🦖 Dino"
    self.SpeciesLabel.Parent       = root

    -- ── Row 2: growth badge + role card ────────────────────────────────────
    self.GrowthBadge                  = Instance.new("TextLabel")
    self.GrowthBadge.Name             = "GrowthLevelBadge"
    self.GrowthBadge.Size             = UDim2.fromOffset(154, 30)
    self.GrowthBadge.Position         = UDim2.fromOffset(10, 32)
    self.GrowthBadge.BackgroundTransparency = 0.05
    self.GrowthBadge.BackgroundColor3 = Color3.fromRGB(38, 96, 48)
    self.GrowthBadge.TextColor3       = UIFactory.Colors.TextGold
    self.GrowthBadge.TextScaled       = true
    self.GrowthBadge.Text             = "⭐ LV 1  0% →"
    self.GrowthBadge:SetAttribute("MobileReadable", true)
    UIFactory:RoundCorners(self.GrowthBadge, 6)
    self.GrowthBadge.Parent           = root

    self.RoleCard                  = Instance.new("TextLabel")
    self.RoleCard.Name             = "SpeciesRoleCard"
    self.RoleCard.Size             = UDim2.fromOffset(158, 30)
    self.RoleCard.Position         = UDim2.fromOffset(170, 32)
    self.RoleCard.BackgroundTransparency = 0.05
    self.RoleCard.BackgroundColor3 = Color3.fromRGB(18, 36, 24)
    self.RoleCard.TextColor3       = UIFactory.Colors.TextSoft
    self.RoleCard.TextWrapped      = true
    self.RoleCard.TextScaled       = true
    self.RoleCard.Text             = "Pick a dino"
    self.RoleCard:SetAttribute("MobileReadable", true)
    UIFactory:RoundCorners(self.RoleCard, 6)
    self.RoleCard.Parent           = root

    -- ── Row 3: diet guidance + delta ───────────────────────────────────────
    self.GuidanceLabel                  = Instance.new("TextLabel")
    self.GuidanceLabel.Name             = "DietGuidanceLabel"
    self.GuidanceLabel.Size             = UDim2.fromOffset(154, 26)
    self.GuidanceLabel.Position         = UDim2.fromOffset(10, 66)
    self.GuidanceLabel.BackgroundTransparency = 1
    self.GuidanceLabel.TextColor3       = UIFactory.Colors.TextSoft
    self.GuidanceLabel.TextWrapped      = true
    self.GuidanceLabel.TextScaled       = true
    self.GuidanceLabel.Text             = "🌿 + 💧 = ⭐"
    self.GuidanceLabel:SetAttribute("IconOnlyTracker", true)
    self.GuidanceLabel.Parent           = root

    self.StatusDeltaLabel               = Instance.new("TextLabel")
    self.StatusDeltaLabel.Name          = "StatusDeltaLabel"
    self.StatusDeltaLabel.Size          = UDim2.fromOffset(158, 26)
    self.StatusDeltaLabel.Position      = UDim2.fromOffset(170, 66)
    self.StatusDeltaLabel.BackgroundTransparency = 1
    self.StatusDeltaLabel.TextColor3    = Color3.fromRGB(160, 235, 255)
    self.StatusDeltaLabel.TextScaled    = true
    self.StatusDeltaLabel.Text          = "🍎 + 💧 → ⭐"
    self.StatusDeltaLabel:SetAttribute("IconOnlyTracker", true)
    self.StatusDeltaLabel.Parent        = root

    -- Thin separator line
    local sep      = Instance.new("Frame")
    sep.Name       = "Separator"
    sep.Size       = UDim2.fromOffset(PANEL_W - 20, 1)
    sep.Position   = UDim2.fromOffset(10, 97)
    sep.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
    sep.BackgroundTransparency = 0.4
    sep.Parent     = root

    -- ── Stat bars ──────────────────────────────────────────────────────────
    -- Each bar row: icon label | [====fill====] | value%
    local barDefs = {
        { key = "health",  y = BAR_START_Y,                  icon = "❤️"  },
        { key = "hunger",  y = BAR_START_Y + BAR_STEP,       icon = "🍎"  },
        { key = "thirst",  y = BAR_START_Y + BAR_STEP * 2,   icon = "💧"  },
        { key = "stamina", y = BAR_START_Y + BAR_STEP * 3,   icon = "⚡"  },
        { key = "oxygen",  y = BAR_START_Y + BAR_STEP * 4,   icon = "🫧"  },
        { key = "growth",  y = BAR_START_Y + BAR_STEP * 5,   icon = "⭐"  },
    }

    for _, def in ipairs(barDefs) do
        local capName    = def.key:gsub("^%l", string.upper)  -- "Health", etc.
        local fill       = UIFactory:CreateBar(root, capName, def.y, BAR_OPTS)
        self.Bars[def.key] = fill
        -- Apply icon to the label UIFactory just created
        local lbl = root:FindFirstChild(capName .. "Label")
        if lbl then lbl.Text = def.icon end
    end

    -- Oxygen row starts hidden; shown only when underwater/relevant
    local oxyBar = root:FindFirstChild("OxygenBar")
    local oxyLbl = root:FindFirstChild("OxygenLabel")
    local oxyVal = root:FindFirstChild("OxygenValueLabel")
    self._oxygenVisible = true  -- will be toggled by ApplyStatUpdate
    self._oxygenBar     = oxyBar
    self._oxygenLabel   = oxyLbl
    self._oxygenValue   = oxyVal

    gui.Parent   = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui     = gui
    return gui
end

-- ── Bar update ────────────────────────────────────────────────────────────────

-- Colours bars green/amber/red based on fill fraction.
function HUDController:SetBar(name, value)
    local fill    = self.Bars[name]
    local percent = math.clamp((value or 0) / 100, 0, 1)
    if fill then
        fill.Size = UDim2.fromScale(percent, 1)
        if percent < 0.25 then
            fill.BackgroundColor3 = UIFactory.Colors.BarLow
        elseif percent < 0.55 then
            fill.BackgroundColor3 = UIFactory.Colors.BarMid
        else
            fill.BackgroundColor3 = UIFactory.Colors.BarGood
        end
        -- Update numeric value label
        local capName    = name:gsub("^%l", string.upper)
        local barFrame   = fill.Parent
        local rootFrame  = barFrame and barFrame.Parent
        local valueLabel = rootFrame and rootFrame:FindFirstChild(capName .. "ValueLabel")
        if valueLabel then
            valueLabel.Text = tostring(round(value)) .. "%"
            valueLabel:SetAttribute("Value", round(value))
        end
    end
end

-- ── Oxygen visibility ─────────────────────────────────────────────────────────

local function setOxygenRowVisible(self, visible)
    if self._oxygenVisible == visible then return end
    self._oxygenVisible = visible
    if self._oxygenBar   then self._oxygenBar.Visible   = visible end
    if self._oxygenLabel then self._oxygenLabel.Visible = visible end
    if self._oxygenValue then self._oxygenValue.Visible = visible end
end

-- ── Stat update entry point ───────────────────────────────────────────────────

function HUDController:ApplyStatUpdate(payload)
    self:EnsureGui()
    local previous   = self.LastStats
    self.LastStats   = payload

    -- Species name
    self.SpeciesLabel.Text = string.format("🦖 %s", self:GetSpeciesDisplayName(payload.species))

    -- Growth badge + role card
    self.GrowthBadge.Text = self:BuildGrowthBadge(payload)
    self.GrowthBadge:SetAttribute("LevelText", self.GrowthBadge.Text)
    self.RoleCard.Text = self:BuildRoleCard(payload)
    self.RoleCard:SetAttribute("RoleText", self.RoleCard.Text)

    -- Guidance + delta
    self.GuidanceLabel.Text = self:BuildDietGuidance(payload)
    self.StatusDeltaLabel.Text = self:BuildDeltaText(previous, payload)
    self.StatusDeltaLabel:SetAttribute("LastDeltaText", self.StatusDeltaLabel.Text)

    -- Stat bars
    self:SetBar("health",  payload.health)
    self:SetBar("hunger",  payload.hunger)
    self:SetBar("thirst",  payload.thirst)
    self:SetBar("stamina", payload.stamina)
    self:SetBar("growth",  payload.growth)

    -- Oxygen: show only when the creature has an oxygen stat (swimming species
    -- or currently underwater).  maxOxygen > 0 signals the server considers it relevant.
    local maxOxy = tonumber(payload.maxOxygen) or 0
    local showOxy = maxOxy > 0
    setOxygenRowVisible(self, showOxy)
    if showOxy then
        local oxyPct = math.clamp((tonumber(payload.oxygen) or maxOxy) / maxOxy * 100, 0, 100)
        self:SetBar("oxygen", oxyPct)
    end
end

-- ── Remote listener ───────────────────────────────────────────────────────────

Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
    HUDController:ApplyStatUpdate(payload)
end)

-- ── CombatFeedbackController init (appended by Lane C – must be preserved) ───

local _ok, CombatFeedbackController = pcall(require, script.Parent.CombatFeedbackController)
if _ok and CombatFeedbackController and CombatFeedbackController.Init then
    CombatFeedbackController:Init()
end

-- ── NpcHealthThreatController init (self-inits on require; require to load) ───

local _okNpcThreat, NpcHealthThreatController = pcall(require, script.Parent.NpcHealthThreatController)
if _okNpcThreat and NpcHealthThreatController and NpcHealthThreatController.Init then
    NpcHealthThreatController:Init()
end

return HUDController
