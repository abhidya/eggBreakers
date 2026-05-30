-- UIFactory: shared UI builder for eggBreakers HUD and mobile controls.
-- Keeps all instance creation in one place so style changes are easy.
local UIFactory = {}

-- Palette used across all HUD elements for consistency
UIFactory.Colors = {
    PanelBg      = Color3.fromRGB(8,  22, 14),
    PanelBorder  = Color3.fromRGB(30, 70, 40),
    BarBg        = Color3.fromRGB(22, 38, 26),
    BarGood      = Color3.fromRGB(72, 210, 110),
    BarMid       = Color3.fromRGB(230, 175, 55),
    BarLow       = Color3.fromRGB(230, 70,  60),
    TextPrimary  = Color3.fromRGB(255, 255, 255),
    TextSoft     = Color3.fromRGB(210, 250, 210),
    TextGold     = Color3.fromRGB(255, 242, 160),
    ButtonBg     = Color3.fromRGB(35,  45, 35),
    ButtonActive = Color3.fromRGB(55,  80, 55),
}

-- Rounds corners on a Frame/TextButton using UICorner.
-- Returns the UICorner instance.
function UIFactory:RoundCorners(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
    return corner
end

-- Adds a 1-px border stroke.
function UIFactory:AddStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or self.Colors.PanelBorder
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- CreateBar: creates an icon label, a filled progress bar, and a numeric
-- value label inside `parent`, positioned at `yOffset`.
-- Returns the Fill frame (the inner fill of the bar).
-- Named children created in parent:
--   {name}Label       TextLabel  (icon / short text)
--   {name}Bar         Frame      (bar background)
--   {name}ValueLabel  TextLabel  (numeric value "75%")
-- The Fill frame is a child of {name}Bar.
function UIFactory:CreateBar(parent, name, yOffset, options)
    options = options or {}
    local h       = options.Height    or 18
    local barH    = options.BarHeight or 12
    local barYOff = options.BarYOffset or 3

    -- Icon / label
    local label = Instance.new("TextLabel")
    label.Name                = name .. "Label"
    label.Size                = UDim2.fromOffset(options.LabelWidth or 120, h)
    label.Position            = UDim2.fromOffset(options.LabelX or 10, yOffset)
    label.BackgroundTransparency = 1
    label.Text                = name
    label.TextColor3          = self.Colors.TextPrimary
    label.TextScaled          = true
    label.Parent              = parent

    -- Numeric value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name                = name .. "ValueLabel"
    valueLabel.Size                = UDim2.fromOffset(options.ValueWidth or 82, h)
    valueLabel.Position            = UDim2.fromOffset(options.ValueX or 320, yOffset)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text                = "100%"
    valueLabel.TextColor3          = self.Colors.TextSoft
    valueLabel.TextScaled          = true
    valueLabel.TextXAlignment      = Enum.TextXAlignment.Right
    valueLabel.Parent              = parent

    -- Bar background
    local bar = Instance.new("Frame")
    bar.Name             = name .. "Bar"
    bar.Size             = UDim2.fromOffset(options.BarWidth or 180, barH)
    bar.Position         = UDim2.fromOffset(options.BarX or 135, yOffset + barYOff)
    bar.BackgroundColor3 = self.Colors.BarBg
    bar.ClipsDescendants = true
    bar.Parent           = parent
    self:RoundCorners(bar, 4)

    -- Fill (inner bar)
    local fill = Instance.new("Frame")
    fill.Name             = "Fill"
    fill.Size             = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = self.Colors.BarGood
    fill.Parent           = bar
    self:RoundCorners(fill, 4)

    return fill
end

-- CreateButton: a styled TextButton suitable for mobile action buttons.
-- Default background matches test expectation Color3.fromRGB(35, 45, 35).
function UIFactory:CreateButton(parent, name, text, position, options)
    local button = Instance.new("TextButton")
    local size   = options and options.Size or UDim2.fromOffset(112, 64)
    button.Name             = name
    button.Text             = text
    button.Size             = size
    button.Position         = position
    button.TextScaled       = true
    button.TextWrapped      = true
    button.BackgroundColor3 = self.Colors.ButtonBg  -- Color3.fromRGB(35, 45, 35)
    button.TextColor3       = self.Colors.TextPrimary
    button.AutoButtonColor  = true
    button.Parent           = parent
    self:RoundCorners(button, 8)
    self:AddStroke(button, self.Colors.PanelBorder, 1)
    return button
end

-- CreateRootGui: wraps a ScreenGui with standard settings.
function UIFactory:CreateRootGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name           = name
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = false
    return gui
end

-- CreatePanel: a styled Frame panel (rounded, semi-transparent dark bg).
function UIFactory:CreatePanel(parent, name, size, position)
    local panel = Instance.new("Frame")
    panel.Name                  = name
    panel.Size                  = size
    panel.Position              = position
    panel.BackgroundColor3      = self.Colors.PanelBg
    panel.BackgroundTransparency = 0.12
    panel.ClipsDescendants      = true
    panel.Parent                = parent
    self:RoundCorners(panel, 10)
    self:AddStroke(panel, self.Colors.PanelBorder, 1)
    return panel
end

return UIFactory
