local UIFactory = {}

function UIFactory:CreateBar(parent, name, yOffset)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Size = UDim2.fromOffset(120, 18)
    label.Position = UDim2.fromOffset(10, yOffset)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = parent

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = name .. "ValueLabel"
    valueLabel.Size = UDim2.fromOffset(82, 18)
    valueLabel.Position = UDim2.fromOffset(320, yOffset)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "100%"
    valueLabel.TextColor3 = Color3.fromRGB(235, 255, 235)
    valueLabel.TextScaled = true
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = parent

    local bar = Instance.new("Frame")
    bar.Name = name .. "Bar"
    bar.Size = UDim2.fromOffset(180, 12)
    bar.Position = UDim2.fromOffset(135, yOffset + 3)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(82, 200, 120)
    fill.Parent = bar
    return fill
end

function UIFactory:CreateButton(parent, name, text, position, options)
    local button = Instance.new("TextButton")
    local size = options and options.Size or UDim2.fromOffset(112, 64)
    button.Name = name
    button.Text = text
    button.Size = UDim2.fromOffset(112, 64)
    button.Position = position
    button.TextScaled = true
    button.TextWrapped = true
    button.BackgroundColor3 = Color3.fromRGB(35, 45, 35)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.AutoButtonColor = true
    button.Parent = parent
    return button
end

function UIFactory:CreateRootGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    return gui
end

return UIFactory
