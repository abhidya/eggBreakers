local SpeciesModelService = require(script.Parent.SpeciesModelService)

local CharacterVisualService = {}
CharacterVisualService.VisualFolderName = "_EggBreakersCharacterVisual"
CharacterVisualService.EggVisualName = "EggVisual"
CharacterVisualService.DinosaurVisualName = "DinosaurVisual"

local function getRoot(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

local function setDescendantCollisionSafe(instance)
    if instance:IsA("BasePart") then
        instance.Anchored = false
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
        instance.Massless = true
    end
end

local function removeExecutableCode(instance)
    if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
        instance:Destroy()
    end
end

function CharacterVisualService:HideDefaultAvatar(character)
    if not character then return false end
    local changed = false
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" then
                descendant.Transparency = 1
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
            end
            changed = true
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = 1
            changed = true
        end
    end
    return changed
end

function CharacterVisualService:_visualFolder(character)
    local folder = character:FindFirstChild(self.VisualFolderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = self.VisualFolderName
        folder.Parent = character
    end
    return folder
end

function CharacterVisualService:ClearVisual(character)
    local folder = character and character:FindFirstChild(self.VisualFolderName)
    if folder then folder:Destroy() end
end

function CharacterVisualService:_weldToRoot(part, root)
    part.CFrame = root.CFrame
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = part
    weld.Parent = part
end

function CharacterVisualService:_createEggVisual(character, root)
    local folder = self:_visualFolder(character)
    local egg = Instance.new("Part")
    egg.Name = self.EggVisualName
    egg.Shape = Enum.PartType.Ball
    egg.Size = Vector3.new(3.5, 4.5, 3.5)
    egg.Color = Color3.fromRGB(232, 221, 190)
    egg.Material = Enum.Material.SmoothPlastic
    egg:SetAttribute("EggBreakersVisual", true)
    setDescendantCollisionSafe(egg)
    egg.Parent = folder
    self:_weldToRoot(egg, root)
    return egg
end

function CharacterVisualService:_prepareDinosaurClone(model)
    local clone = model:Clone()
    clone.Name = self.DinosaurVisualName
    clone:SetAttribute("EggBreakersVisual", true)
    for _, descendant in ipairs(clone:GetDescendants()) do
        removeExecutableCode(descendant)
    end
    for _, descendant in ipairs(clone:GetDescendants()) do
        setDescendantCollisionSafe(descendant)
    end
    return clone
end

function CharacterVisualService:_attachModel(character, root, model)
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary then
        model:Destroy()
        return nil
    end

    local folder = self:_visualFolder(character)
    model.Parent = folder
    model.PrimaryPart = primary
    model:PivotTo(root.CFrame)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            self:_weldToRoot(descendant, root)
        end
    end
    return model
end

function CharacterVisualService:_createFallbackDinosaur(character, root, state)
    local folder = self:_visualFolder(character)
    local body = Instance.new("Part")
    body.Name = self.DinosaurVisualName
    body.Size = Vector3.new(4, 2, 7)
    body.Color = Color3.fromRGB(64, 142, 74)
    body.Material = Enum.Material.SmoothPlastic
    body:SetAttribute("EggBreakersVisual", true)
    body:SetAttribute("FallbackForSpecies", state and state.SpeciesId or "unknown")
    setDescendantCollisionSafe(body)
    body.Parent = folder
    self:_weldToRoot(body, root)
    return body
end

function CharacterVisualService:ApplyForState(player, state)
    local character = player and player.Character
    local root = getRoot(character)
    if not character or not root then return false, "missing_character_root" end

    self:HideDefaultAvatar(character)
    self:ClearVisual(character)

    if not state or state.Hatched ~= true then
        self:_createEggVisual(character, root)
        return true, "egg"
    end

    local sourceModel = SpeciesModelService:ResolveModel(state.SpeciesId or "gallimimus", state.GrowthStage or "Hatchling")
    if sourceModel then
        local attached = self:_attachModel(character, root, self:_prepareDinosaurClone(sourceModel))
        if attached then
            return true, "dinosaur_model"
        end
    end

    self:_createFallbackDinosaur(character, root, state)
    return true, "dinosaur_fallback"
end

function CharacterVisualService:HasVisibleGameVisual(character)
    local folder = character and character:FindFirstChild(self.VisualFolderName)
    if not folder then return false end
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then
            return true
        end
    end
    return false
end

return CharacterVisualService
