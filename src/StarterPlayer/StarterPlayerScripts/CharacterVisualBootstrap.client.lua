local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local VISUAL_NAME = "_EggBreakersCharacterVisualClient"
local hatchProgress = 0
local hatched = false

local function rootFor(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function hideDefaultAvatar(character)
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" then
                descendant.LocalTransparencyModifier = 1
                descendant.Transparency = 1
            end
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = 1
        end
    end
end

local function clearVisual(character)
    local existing = character and character:FindFirstChild(VISUAL_NAME)
    if existing then existing:Destroy() end
end

local function safePart(part)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
end

local function weld(root, part, offset)
    safePart(part)
    part.CFrame = root.CFrame * offset
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = root
    constraint.Part1 = part
    constraint.Parent = part
end

local function makePart(name, size, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

local function showEgg(character)
    local root = rootFor(character)
    if not root then return false end
    clearVisual(character)
    hideDefaultAvatar(character)
    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "Egg")
    local shell = makePart("EggVisual", Vector3.new(3.5, 4.5, 3.5), Color3.fromRGB(232, 221, 190))
    shell.Shape = Enum.PartType.Ball
    shell.Parent = model
    weld(root, shell, CFrame.new(0, -0.5, 0))
    model.Parent = character
    return true
end

local function showDinosaur(character)
    local root = rootFor(character)
    if not root then return false end
    clearVisual(character)
    hideDefaultAvatar(character)
    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "DinosaurFallback")
    local body = makePart("DinosaurVisual", Vector3.new(4.5, 2, 6), Color3.fromRGB(64, 142, 74))
    body.Parent = model
    weld(root, body, CFrame.new(0, -1.1, -0.2))
    local head = makePart("DinosaurHead", Vector3.new(1.6, 1, 1.2), Color3.fromRGB(104, 172, 82))
    head.Parent = model
    weld(root, head, CFrame.new(0, -0.35, -3.2))
    local tail = makePart("DinosaurTail", Vector3.new(1, 1, 3), Color3.fromRGB(64, 142, 74))
    tail.Parent = model
    weld(root, tail, CFrame.new(0, -1.1, 2.6))
    model.Parent = character
    return true
end

local function applyVisual()
    local character = player.Character
    if not character then return end
    hideDefaultAvatar(character)
    if hatched then
        showDinosaur(character)
    else
        showEgg(character)
    end
end

local function bindCharacter(character)
    character:WaitForChild("HumanoidRootPart", 10)
    task.defer(applyVisual)
    character.DescendantAdded:Connect(function()
        task.defer(applyVisual)
    end)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end

Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
    if type(payload) == "table" then
        if payload.hatched == true then
            hatched = true
        end
        if type(payload.hatchProgress) == "number" then
            hatchProgress = payload.hatchProgress
            if hatchProgress >= 100 then hatched = true end
        end
        applyVisual()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or hatched then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space then
        hatchProgress = math.clamp(hatchProgress + 20, 0, 100)
        Remotes:WaitForChild("RequestHatch"):FireServer("tap")
        if hatchProgress >= 100 then
            hatched = true
        end
        applyVisual()
    end
end)
