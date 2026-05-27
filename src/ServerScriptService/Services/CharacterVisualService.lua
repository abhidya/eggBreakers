local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local SpeciesModelService = require(script.Parent.SpeciesModelService)

local CharacterVisualService = {}

local VISUAL_NAME = "EggBreakersCharacterVisual"

local function getRoot(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

local function setAvatarVisible(character, visible)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" then
                descendant.Transparency = visible and 0 or 1
            end
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = visible and 0 or 1
        elseif descendant:IsA("Accessory") then
            local handle = descendant:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.Transparency = visible and 0 or 1
                handle.CanCollide = false
                handle.CanTouch = false
                handle.CanQuery = false
            end
        end
    end
end

local function clearVisual(character)
    local existing = character and character:FindFirstChild(VISUAL_NAME)
    if existing then existing:Destroy() end
end

local function weldPartToRoot(root, part, offset)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CFrame = root.CFrame * offset
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = part
    weld.Parent = part
end

local function makePart(name, size, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

local function makeEggVisual(root)
    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "Egg")

    local shell = makePart("EggShell", Vector3.new(4, 4.8, 4), Color3.fromRGB(234, 226, 199), Enum.Material.Slate)
    shell.Shape = Enum.PartType.Ball
    shell.Parent = model
    weldPartToRoot(root, shell, CFrame.new(0, -0.6, 0))

    local crack = makePart("ShellCrack", Vector3.new(0.12, 3.2, 0.18), Color3.fromRGB(64, 58, 50), Enum.Material.Slate)
    crack.Parent = model
    weldPartToRoot(root, crack, CFrame.new(0, -0.3, -2.03) * CFrame.Angles(0, 0, math.rad(18)))

    return model
end

local function prepareImportedClone(source, root)
    local clone = source:Clone()
    clone.Name = VISUAL_NAME
    clone:SetAttribute("VisualKind", "Dinosaur")
    clone:SetAttribute("ImportedSourcePath", source:GetFullName())

    local parts = {}
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        end
    end

    if clone:IsA("BasePart") then
        table.insert(parts, clone)
    end

    if #parts == 0 then
        clone:Destroy()
        return nil
    end

    local pivot = clone:IsA("Model") and clone:GetPivot() or parts[1].CFrame
    local _, size = clone:IsA("Model") and clone:GetBoundingBox() or { parts[1].CFrame, parts[1].Size }
    local largest = math.max(size.X, size.Y, size.Z)
    local scale = largest > 0 and math.clamp(6 / largest, 0.25, 2) or 1
    if clone:IsA("Model") and math.abs(scale - 1) > 0.01 then
        pcall(function() clone:ScaleTo(scale) end)
        pivot = clone:GetPivot()
    end

    local targetPivot = root.CFrame * CFrame.new(0, -1.4, -0.5)
    if clone:IsA("Model") then
        clone:PivotTo(targetPivot)
    else
        clone.CFrame = targetPivot
    end

    for _, part in ipairs(parts) do
        local relative = targetPivot:ToObjectSpace(part.CFrame)
        weldPartToRoot(root, part, relative)
    end

    return clone
end

local function makeFallbackDinosaur(root, speciesId)
    local species = SpeciesConfig[speciesId] or SpeciesConfig.gallimimus
    local carnivore = species and species.Diet == "Carnivore"
    local bodyColor = carnivore and Color3.fromRGB(112, 65, 45) or Color3.fromRGB(76, 126, 64)
    local accentColor = carnivore and Color3.fromRGB(170, 92, 54) or Color3.fromRGB(128, 164, 78)

    local model = Instance.new("Model")
    model.Name = VISUAL_NAME
    model:SetAttribute("VisualKind", "DinosaurFallback")
    model:SetAttribute("SpeciesId", speciesId or "gallimimus")

    local body = makePart("DinosaurBody", Vector3.new(4.5, 2, 2), bodyColor)
    body.Parent = model
    weldPartToRoot(root, body, CFrame.new(0, -1.1, -0.2))

    local neck = makePart("DinosaurNeck", Vector3.new(1, 1.6, 1), bodyColor)
    neck.Parent = model
    weldPartToRoot(root, neck, CFrame.new(0, -0.35, -1.9) * CFrame.Angles(math.rad(-22), 0, 0))

    local head = makePart("DinosaurHead", Vector3.new(1.7, 1, 1.2), accentColor)
    head.Parent = model
    weldPartToRoot(root, head, CFrame.new(0, -0.15, -3))

    local tail = makePart("DinosaurTail", Vector3.new(1, 1, 3.4), bodyColor)
    tail.Parent = model
    weldPartToRoot(root, tail, CFrame.new(0, -1.05, 2.4) * CFrame.Angles(math.rad(-10), 0, 0))

    for i, x in ipairs({ -1.5, 1.5 }) do
        local leg = makePart("DinosaurLeg" .. i, Vector3.new(0.7, 1.8, 0.7), bodyColor)
        leg.Parent = model
        weldPartToRoot(root, leg, CFrame.new(x, -2.3, 0.25))
    end

    return model
end

function CharacterVisualService:ApplyEgg(player)
    local character = player.Character
    local root = getRoot(character)
    if not character or not root then return false, "missing_character" end
    clearVisual(character)
    setAvatarVisible(character, false)
    local visual = makeEggVisual(root)
    visual.Parent = character
    return true, visual
end

function CharacterVisualService:ApplyDinosaur(player, state)
    local character = player.Character
    local root = getRoot(character)
    if not character or not root or not state then return false, "missing_character_or_state" end
    clearVisual(character)
    setAvatarVisible(character, false)

    local source = SpeciesModelService:ResolveModel(state.SpeciesId, state.GrowthStage or "Hatchling")
    local visual = source and prepareImportedClone(source, root) or makeFallbackDinosaur(root, state.SpeciesId)
    if not visual then
        visual = makeFallbackDinosaur(root, state.SpeciesId)
    end
    visual.Parent = character
    return true, visual
end

function CharacterVisualService:ApplyForState(player, state)
    if not state or not state.Hatched then
        return self:ApplyEgg(player)
    end
    return self:ApplyDinosaur(player, state)
end

function CharacterVisualService:GetVisual(player)
    local character = player.Character
    return character and character:FindFirstChild(VISUAL_NAME)
end

return CharacterVisualService
