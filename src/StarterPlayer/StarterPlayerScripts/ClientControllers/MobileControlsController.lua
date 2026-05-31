-- MobileControlsController: thumb-reachable action buttons for mobile players.
-- Core actions: EatDrink, Attack, Sprint, Call, RestHide.
-- Optional (hidden until species unlocks): Flight, Swim.
-- Left side: movement thumbstick placeholder (Roblox TouchThumbstick takes it at runtime).
-- Floating hints above the button cluster: scent cue + action feedback.
--
-- Public API (stable – do NOT remove or rename):
--   MobileControlsController.Buttons          table
--   MobileControlsController.OptionalButtons  table
--   MobileControlsController.EffectStyles     table
--   MobileControlsController:BuildWaypointText(targetType, distance, diet) -> string
--   MobileControlsController:BuildTargetIcon(targetType, diet)         -> string
--   MobileControlsController:BuildFoodWaterLegend(stats)              -> string
--   MobileControlsController:SetButtonEffect(button, actionName, active) -> bool
--   MobileControlsController:FlashButtonEffect(button, actionName, durationSeconds) -> bool
--   MobileControlsController:WireVisibleButtonEffects(gui) -> bool
--   MobileControlsController:CreateControls(settings) -> { Gui, Buttons, OptionalButtons, Scale }
--   MobileControlsController:ShowOptionalButton(gui, name) -- unlock flight/swim at runtime
--   MobileControlsController:HideOptionalButton(gui, name)
--   MobileControlsController:SetActionAvailable(gui, name, available) -- progressive disclosure
--   MobileControlsController:SetButtonContext(button, context) -- contextual one-tap state
--   MobileControlsController:UpdateWaypoint(gui, targetType, distance, diet) -- diegetic sense cue
--   MobileControlsController:ShowActionFeedback(gui, message, durationSeconds) -- transient toast

local Players   = game:GetService("Players")
local UIFactory = require(script.Parent.UIFactory)

local MobileControlsController = {}

-- All button names (thumbstick is a Frame, not a TextButton)
MobileControlsController.Buttons         = { "MoveThumbstick", "EatDrink", "Attack", "Sprint", "Call", "RestHide" }
MobileControlsController.OptionalButtons = { "Flight", "Swim" }

-- Default inactive background colour (must match test assertion Color3.fromRGB(35, 45, 35))
MobileControlsController.DefaultButtonColor = Color3.fromRGB(35, 45, 35)

-- Visual feedback styles for each action
MobileControlsController.EffectStyles = {
    EatDrink = { ActiveText = "🍎+",   ActiveColor = Color3.fromRGB(66,  140,  82) },
    Attack   = { ActiveText = "🦷!",   ActiveColor = Color3.fromRGB(190,  78,  62) },
    Sprint   = { ActiveText = "⚡!",   ActiveColor = Color3.fromRGB(72,  128, 255) },
    Call     = { ActiveText = "📣!",   ActiveColor = Color3.fromRGB(255, 196,  76) },
    RestHide = { ActiveText = "🌿💤", ActiveColor = Color3.fromRGB(56,   92,  68) },
    Flight   = { ActiveText = "🪽",    ActiveColor = Color3.fromRGB(96,  170, 255) },
    Swim     = { ActiveText = "🌊",    ActiveColor = Color3.fromRGB(56,  160, 210) },
}

-- ── Pure helpers ──────────────────────────────────────────────────────────────

function MobileControlsController:BuildTargetIcon(targetType, diet)
    if targetType == "Water" then return "💧" end
    diet = tostring(diet or "")
    if diet == "Herbivore" then return "🌿" end
    if diet == "Carnivore" then return "🍖" end
    if diet == "Omnivore" then return "🍽️" end
    return "🍎"
end

-- Scent cue shown in the NearestActionHintLabel.
-- Nearby targets sparkle; distant targets use a non-directional scent trail.
function MobileControlsController:BuildWaypointText(targetType, distance, diet)
    if not targetType or targetType == "None" then return "◌ " .. self:BuildTargetIcon("Food", diet) .. "  💧" end
    local icon   = self:BuildTargetIcon(targetType, diet)
    local meters = math.max(0, tonumber(distance) or 0)
    local pulse  = meters <= 14 and "✨" or "〰"
    return string.format("%s %s %.0fm", pulse, icon, meters)
end

-- Short legend for DialoguePromptLabel.
function MobileControlsController:BuildFoodWaterLegend(stats)
    stats   = stats or {}
    local foodLow = (tonumber(stats.hunger) or 100) <= (tonumber(stats.thirst) or 100)
    local foodIcon = self:BuildTargetIcon("Food", stats.diet)
    return foodLow and (foodIcon .. " + 💧 = ⭐") or ("💧 + " .. foodIcon .. " = ⭐")
end

-- ── Button effect helpers ─────────────────────────────────────────────────────

function MobileControlsController:SetButtonEffect(button, actionName, active)
    local style = self.EffectStyles[actionName]
    if not button or not style then return false end
    button:SetAttribute("EffectActive", active == true)
    button.BackgroundColor3 = active and style.ActiveColor or self.DefaultButtonColor
    button.Text             = active and style.ActiveText or (button:GetAttribute("DefaultText") or actionName)
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

-- Wires press/release visual feedback onto the always-visible buttons in `gui`.
function MobileControlsController:WireVisibleButtonEffects(gui)
    if not gui then return false end
    local sprint = gui:FindFirstChild("SprintButton")
    if sprint then
        sprint.MouseButton1Down:Connect(function() self:SetButtonEffect(sprint, "Sprint", true)  end)
        sprint.MouseButton1Up:Connect(  function() self:SetButtonEffect(sprint, "Sprint", false) end)
        sprint.MouseLeave:Connect(      function() self:SetButtonEffect(sprint, "Sprint", false) end)
    end
    local call = gui:FindFirstChild("CallButton")
    if call then
        call.Activated:Connect(function() self:FlashButtonEffect(call, "Call") end)
    end
    local restHide = gui:FindFirstChild("RestHideButton")
    if restHide then
        restHide.MouseButton1Down:Connect(function() self:SetButtonEffect(restHide, "RestHide", true)  end)
        restHide.MouseButton1Up:Connect(  function() self:SetButtonEffect(restHide, "RestHide", false) end)
        restHide.MouseLeave:Connect(      function() self:SetButtonEffect(restHide, "RestHide", false) end)
    end
    return true
end

-- ── Optional button runtime unlock ────────────────────────────────────────────

-- Call when a species with Flight/Swim is selected.
function MobileControlsController:ShowOptionalButton(gui, name)
    if not gui then return end
    local button = gui:FindFirstChild(name .. "Button")
    if button then
        button.Visible          = true
        button.Active           = true
        button.AutoButtonColor  = true
    end
end

-- Call when switching away from a Flight/Swim species.
function MobileControlsController:HideOptionalButton(gui, name)
    if not gui then return end
    local button = gui:FindFirstChild(name .. "Button")
    if button then
        button.Visible          = false
        button.Active           = false
        button.AutoButtonColor  = false
    end
end

-- ── Progressive disclosure + contextual one-tap state ─────────────────────────

-- Diegetic "dimmed but present" affordance: an action exists for this species
-- but is not usable right now (e.g. nothing nearby to eat). We keep the button
-- on-screen (so the thumb learns its position) but subdue it instead of hiding,
-- which matches DESIGN.md "Disabled: subdued with reason".
function MobileControlsController:SetActionAvailable(gui, name, available)
    if not gui then return false end
    local button = gui:FindFirstChild(name .. "Button")
    if not button then return false end
    available = available ~= false
    button.Active          = available
    button.AutoButtonColor = available
    button.TextTransparency       = available and 0    or 0.45
    button.BackgroundTransparency = available and 0    or 0.35
    button:SetAttribute("Available", available)
    button:SetAttribute("Context", available and "Ready" or "Unavailable")
    return true
end

-- Contextual one-tap state for a single action button. `context` is a short
-- diegetic state token ("Ready", "Nearby", "Cooldown", "Unavailable").
-- Updates the Context attribute (read by ClientBootstrap) and a subtle pulse
-- so the player can tell at a glance what one tap will do.
function MobileControlsController:SetButtonContext(button, context)
    if not button then return false end
    context = context or "Ready"
    button:SetAttribute("Context", context)
    if context == "Nearby" then
        -- highlight: this action has a valid target within reach right now
        button.TextTransparency       = 0
        button.BackgroundTransparency = 0
        button.Active                 = true
        button.AutoButtonColor        = true
    elseif context == "Sensed" then
        button.TextTransparency       = 0.2
        button.BackgroundTransparency = 0.18
        button.Active                 = false
        button.AutoButtonColor        = false
    elseif context == "Unavailable" then
        button.TextTransparency       = 0.45
        button.BackgroundTransparency = 0.35
        button.Active                 = false
        button.AutoButtonColor        = false
    end
    return true
end

-- ── Floating-hint helpers ─────────────────────────────────────────────────────

-- Push a fresh waypoint cue into the NearestActionHintLabel (icon-only, diegetic).
function MobileControlsController:UpdateWaypoint(gui, targetType, distance, diet)
    if not gui then return false end
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    if not hint then return false end
    hint.Text = self:BuildWaypointText(targetType, distance, diet)
    return true
end

-- Transient, thumb-clear toast for action feedback ("ate fern", "drank", "hid").
-- Stays icon/verb short; auto-hides so it never covers the controls for long.
function MobileControlsController:ShowActionFeedback(gui, message, durationSeconds)
    if not gui then return false end
    local feedback = gui:FindFirstChild("ActionFeedbackLabel")
    if not feedback then return false end
    feedback.Text    = message or ""
    feedback.Visible = true
    feedback:SetAttribute("LastFeedback", message or "")
    local token = (feedback:GetAttribute("FeedbackToken") or 0) + 1
    feedback:SetAttribute("FeedbackToken", token)
    task.delay(durationSeconds or 1.4, function()
        if feedback and feedback.Parent and feedback:GetAttribute("FeedbackToken") == token then
            feedback.Visible = false
        end
    end)
    return true
end

-- ── Layout constants ─────────────────────────────────────────────────────────

-- Icon labels for buttons (tests assert exact text values)
local BUTTON_LABELS = {
    EatDrink = "🍎💧",
    Attack   = "🦷",
    Sprint   = "⚡",
    Call     = "📣",
    RestHide = "🌿💤",
    Flight   = "🪽",
    Swim     = "🌊",
}

local BUTTON_ICONS = {
    EatDrink = "🍎",
    Attack   = "🦷",
    Sprint   = "⚡",
    Call     = "📣",
    RestHide = "🌿💤",
    Flight   = "🪽",
    Swim     = "🌊",
}

-- ── CreateControls ────────────────────────────────────────────────────────────

function MobileControlsController:CreateControls(settings)
    if self.Gui then return self.Gui end
    local scale = settings and settings.MobileButtonScale or 1.0

    -- Button dimensions
    local bW = 76 * scale
    local bH = 54 * scale
    local buttonSize = UDim2.fromOffset(bW, bH)

    -- Right-cluster anchor offsets from bottom-right corner.
    -- Three columns, two rows + optional top row.
    --  Col offsets from right edge:  col1=-252, col2=-168, col3=-84
    --  Row offsets from bottom:      row1=-132 (upper), row2=-72 (lower)
    --  Optional row:                 row0=-204 (flight/swim above main cluster)
    local positions = {
        EatDrink = UDim2.new(1, -252 * scale, 1, -132 * scale),
        Attack   = UDim2.new(1, -168 * scale, 1, -132 * scale),
        Sprint   = UDim2.new(1,  -84 * scale, 1, -132 * scale),
        Call     = UDim2.new(1, -168 * scale, 1,  -72 * scale),
        RestHide = UDim2.new(1,  -84 * scale, 1,  -72 * scale),
        -- Optional row (hidden by default)
        Flight   = UDim2.new(1, -168 * scale, 1, -204 * scale),
        Swim     = UDim2.new(1,  -84 * scale, 1, -204 * scale),
    }

    local gui = UIFactory:CreateRootGui("MobileControls")

    -- ── Movement thumbstick placeholder ───────────────────────────────────
    -- Roblox's TouchThumbstick takes over this area at runtime.
    local thumbstick = Instance.new("Frame")
    thumbstick.Name                  = "MoveThumbstick"
    thumbstick.Size                  = UDim2.fromOffset(120 * scale, 120 * scale)
    thumbstick.Position              = UDim2.new(0, 18 * scale, 1, -138 * scale)
    thumbstick.BackgroundTransparency = 0.55
    thumbstick.BackgroundColor3      = Color3.fromRGB(20, 20, 20)
    UIFactory:RoundCorners(thumbstick, 60)  -- circle
    thumbstick.Parent = gui

    -- ── Action buttons ────────────────────────────────────────────────────
    for name, position in pairs(positions) do
        local button = UIFactory:CreateButton(gui, name .. "Button", BUTTON_LABELS[name] or name, position)
        button.Size  = buttonSize
        button:SetAttribute("ActionName",           name)
        button:SetAttribute("DefaultText",          BUTTON_LABELS[name] or name)
        button:SetAttribute("KidIcon",              BUTTON_ICONS[name] or "")
        button:SetAttribute("MobileReadable",       true)
        button:SetAttribute("IconFirstMinimalLabel", true)
        button:SetAttribute("OptionalAction",       name == "Flight" or name == "Swim")
        -- Contextual one-tap state, consumed by ClientBootstrap target finding.
        button:SetAttribute("Context",      "Ready")
        button:SetAttribute("Available",    true)
        button:SetAttribute("PressCount",   0)
        button:SetAttribute("CooldownSeconds", name == "Call" and 0.4 or 0.2)
        -- Diegetic readability: soft drop-stroke so the glyph stays legible
        -- against bright jungle/canyon backgrounds (DESIGN.md contrast goal).
        -- Position/AnchorPoint left untouched so the HUD-clearance invariant
        -- asserted by MobileControlsTests stays geometrically true.
        button.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        button.TextStrokeTransparency = 0.45
        button.Font = Enum.Font.FredokaOne
        -- Flight and Swim start hidden until species unlocks them
        if name == "Flight" or name == "Swim" then
            button.Visible         = false
            button.Active          = false
            button.AutoButtonColor = false
        end
    end

    -- ── Floating hints above button cluster ───────────────────────────────
    -- DialoguePromptLabel: icon-only diet/action guidance
    local dialogue = Instance.new("TextLabel")
    dialogue.Name                  = "DialoguePromptLabel"
    dialogue.Size                  = UDim2.fromOffset(168 * scale, 32 * scale)
    dialogue.Position              = UDim2.new(0.5, -84 * scale, 1, -360 * scale)
    dialogue.BackgroundTransparency = 0.1
    dialogue.BackgroundColor3      = Color3.fromRGB(16, 28, 20)
    dialogue.TextColor3            = Color3.fromRGB(240, 255, 220)
    dialogue.TextScaled            = true
    dialogue.TextWrapped           = true
    dialogue.Text                  = "🍎 + 💧 = ⭐"
    dialogue:SetAttribute("GuidesToActionableAssets",  true)
    dialogue:SetAttribute("IconOnlyTracker",           true)
    dialogue:SetAttribute("ProductionKidGuidance",     true)
    dialogue.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    dialogue.TextStrokeTransparency = 0.5
    UIFactory:RoundCorners(dialogue, 6)
    dialogue.Parent = gui

    -- NearestActionHintLabel: non-directional scent/sense cue
    local targetHint = Instance.new("TextLabel")
    targetHint.Name                  = "NearestActionHintLabel"
    targetHint.Size                  = UDim2.fromOffset(168 * scale, 44 * scale)
    targetHint.Position              = UDim2.new(0.5, -84 * scale, 1, -320 * scale)
    targetHint.BackgroundTransparency = 0.04
    targetHint.BackgroundColor3      = Color3.fromRGB(24, 54, 34)
    targetHint.TextColor3            = Color3.fromRGB(255, 255, 255)
    targetHint.TextScaled            = true
    targetHint.TextWrapped           = true
    targetHint.Text                  = "◌ 🌿  💧"
    targetHint:SetAttribute("NonNpcActionHint",         true)
    targetHint:SetAttribute("IconOnlyTracker",          true)
    targetHint:SetAttribute("FloatsAboveActionButtons", true)
    targetHint:SetAttribute("WaypointCue",              "scent-pulse-nearby-trail")
    targetHint.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    targetHint.TextStrokeTransparency = 0.45
    UIFactory:RoundCorners(targetHint, 6)
    targetHint.Parent = gui

    -- ActionFeedbackLabel: transient per-action feedback (starts hidden)
    local feedback = Instance.new("TextLabel")
    feedback.Name                  = "ActionFeedbackLabel"
    feedback.Size                  = UDim2.fromOffset(180 * scale, 34 * scale)
    feedback.Position              = UDim2.new(0.5, -90 * scale, 1, -268 * scale)
    feedback.BackgroundTransparency = 0.1
    feedback.BackgroundColor3      = Color3.fromRGB(20, 35, 24)
    feedback.TextColor3            = Color3.new(1, 1, 1)
    feedback.TextScaled            = true
    feedback.Visible               = false
    feedback:SetAttribute("MobileReadable", true)
    feedback:SetAttribute("LastFeedback",   "")
    feedback:SetAttribute("FeedbackToken",  0)
    feedback.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    feedback.TextStrokeTransparency = 0.45
    UIFactory:RoundCorners(feedback, 6)
    feedback.Parent = gui

    gui.Parent  = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui    = gui
    return { Gui = gui, Buttons = self.Buttons, OptionalButtons = self.OptionalButtons, Scale = scale }
end

return MobileControlsController
