local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SERVER_VISUAL_NAME = "_EggBreakersCharacterVisual"
local VISUAL_NAME = "_EggBreakersCharacterVisualClient"
local DEBUG_VISUAL_FALLBACK = false
local hatchProgress = 0
local hatched = false
local lastHatchInputAt = 0
local HATCH_INPUT_COOLDOWN = 0.08

local function rootFor(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function isGameVisualDescendant(instance)
    local current = instance
    while current do
        if current.Name == SERVER_VISUAL_NAME or current.Name == VISUAL_NAME or current:GetAttribute("EggBreakersVisual") == true or current:GetAttribute("ImportedVisual") == true then
            return true
        end
        current = current.Parent
    end
    return false
end

local function hideDefaultAvatar(character)
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if isGameVisualDescendant(descendant) then
            -- Server-imported egg/dinosaur visuals are the playable body; never hide them as default avatar parts.
        elseif descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" then
                descendant.LocalTransparencyModifier = 1
                descendant.Transparency = 1
            end
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        elseif not isGameVisualDescendant(descendant) and (descendant:IsA("Decal") or descendant:IsA("Texture")) then
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
    if not DEBUG_VISUAL_FALLBACK then return false end
    local root = rootFor(character)
    if not root then return false end
    clearVisual(character)
    hideDefaultAvatar(character)
    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "DebugEggFallback")
    model:SetAttribute("DebugOnly", true)
    local shell = makePart("EggVisual", Vector3.new(3.5, 4.5, 3.5), Color3.fromRGB(232, 221, 190))
    shell.Shape = Enum.PartType.Ball
    shell.Parent = model
    weld(root, shell, CFrame.new(0, -0.5, 0))
    model.Parent = character
    return true
end

local function showDinosaur(character)
    if not DEBUG_VISUAL_FALLBACK then return false end
    local root = rootFor(character)
    if not root then return false end
    clearVisual(character)
    hideDefaultAvatar(character)
    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "DebugDinosaurFallback")
    model:SetAttribute("DebugOnly", true)
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

local function hopEgg(character)
    local root = rootFor(character)
    if not root then return false end
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 28, root.AssemblyLinearVelocity.Z)
    local original = root.CFrame
    local up = original * CFrame.new(0, 0.45, 0) * CFrame.Angles(math.rad(4), 0, math.rad(3))
    local out = TweenService:Create(root, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = up })
    local back = TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = original })
    out:Play()
    out.Completed:Connect(function()
        back:Play()
    end)
    return true
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
        local now = os.clock()
        if now - lastHatchInputAt < HATCH_INPUT_COOLDOWN then return end
        lastHatchInputAt = now
        Remotes:WaitForChild("RequestHatch"):FireServer("tap")
        hopEgg(player.Character)
        -- Keep hatch state server-authoritative. Optimistically marking 100% here can
        -- strand players if one local tap was rate-limited or dropped: the client
        -- stops accepting input while the server egg remains below hatch threshold.
        applyVisual()
    end
end)
