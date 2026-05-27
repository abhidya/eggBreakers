local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local SpeciesModelService = require(script.Parent.SpeciesModelService)

local CharacterVisualService = {}
CharacterVisualService.VisualFolderName = "_EggBreakersCharacterVisual"
CharacterVisualService.EggVisualName = "EggVisual"
CharacterVisualService.DinosaurVisualName = "DinosaurVisual"
CharacterVisualService.ReleaseMode = true
CharacterVisualService.AllowDebugFallback = false
CharacterVisualService.EggModelCandidatePaths = {
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Egg_Nest/Egg",
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Egg_Nest",
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Dinosaur_Egg_Nest/Egg",
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Dinosaur_Egg_Nest",
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Nest_And_Eggs/Egg",
    "ReplicatedStorage/ImportedAssetLibrary/Imported_Nest_And_Eggs",
}

local function getRoot(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

local function resolvePath(path)
    local current = game
    for segment in string.gmatch(path, "[^/]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

local function hasVisiblePart(instance)
    if instance:IsA("BasePart") and instance.Transparency < 1 then return true end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then return true end
    end
    return false
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

function CharacterVisualService:ResolveImportedEggModel()
    for _, path in ipairs(self.EggModelCandidatePaths) do
        local model = resolvePath(path)
        if model and hasVisiblePart(model) then
            return model, path
        end
    end
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        for _, descendant in ipairs(library:GetDescendants()) do
            local name = string.lower(descendant.Name)
            if (string.find(name, "egg", 1, true) or string.find(name, "nest", 1, true)) and hasVisiblePart(descendant) then
                return descendant, descendant:GetFullName()
            end
        end
    end
    return nil, "missing_imported_egg_or_nest_model"
end

function CharacterVisualService:_prepareVisualClone(source, visualName)
    local clone = source:Clone()
    clone.Name = visualName
    clone:SetAttribute("EggBreakersVisual", true)
    clone:SetAttribute("ImportedVisual", true)
    clone:SetAttribute("SourcePath", source:GetFullName())
    for _, descendant in ipairs(clone:GetDescendants()) do
        removeExecutableCode(descendant)
    end
    for _, descendant in ipairs(clone:GetDescendants()) do
        setDescendantCollisionSafe(descendant)
    end
    if clone:IsA("BasePart") then
        setDescendantCollisionSafe(clone)
    end
    return clone
end

function CharacterVisualService:_createEggVisual(character, root)
    local source = self:ResolveImportedEggModel()
    if not source then
        return nil, "missing_imported_egg_visual"
    end
    local clone = self:_prepareVisualClone(source, self.EggVisualName)
    local attached = self:_attachModel(character, root, clone)
    if attached then
        attached:SetAttribute("VisualKind", "ImportedEgg")
        return attached, "imported_egg"
    end
    return nil, "invalid_imported_egg_visual"
end

function CharacterVisualService:_prepareDinosaurClone(model)
    local clone = self:_prepareVisualClone(model, self.DinosaurVisualName)
    clone:SetAttribute("VisualKind", "ImportedDinosaur")
    return clone
end

function CharacterVisualService:_attachModel(character, root, model)
    local primary = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)) or (model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart", true))
    if not primary then
        model:Destroy()
        return nil
    end

    local folder = self:_visualFolder(character)
    model.Parent = folder
    if model:IsA("Model") then
        model.PrimaryPart = primary
        model:PivotTo(root.CFrame)
    elseif model:IsA("BasePart") then
        model.CFrame = root.CFrame
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            self:_weldToRoot(descendant, root)
        end
    end
    if model:IsA("BasePart") then
        self:_weldToRoot(model, root)
    end
    return model
end

function CharacterVisualService:_createFallbackDinosaur(character, root, state, options)
    options = options or {}
    if self.ReleaseMode and not options.debugOnly and not self.AllowDebugFallback then
        return nil, "fallback_disabled_in_release"
    end
    local folder = self:_visualFolder(character)
    local body = Instance.new("Part")
    body.Name = self.DinosaurVisualName
    body.Size = Vector3.new(4, 2, 7)
    body.Color = Color3.fromRGB(64, 142, 74)
    body.Material = Enum.Material.SmoothPlastic
    body:SetAttribute("EggBreakersVisual", true)
    body:SetAttribute("DebugOnly", true)
    body:SetAttribute("FallbackForSpecies", state and state.SpeciesId or "unknown")
    setDescendantCollisionSafe(body)
    body.Parent = folder
    self:_weldToRoot(body, root)
    return body, "dinosaur_fallback_debug"
end

function CharacterVisualService:ApplyForState(player, state, options)
    options = options or {}
    local character = player and player.Character
    local root = getRoot(character)
    if not character or not root then return false, "missing_character_root" end

    self:HideDefaultAvatar(character)
    self:ClearVisual(character)

    if not state or state.Hatched ~= true then
        local egg, reason = self:_createEggVisual(character, root)
        if egg then return true, reason end
        return false, reason
    end

    local sourceModel = SpeciesModelService:ResolveModel(state.SpeciesId or "gallimimus", state.GrowthStage or "Hatchling", { requireExact = self.ReleaseMode })
    if sourceModel then
        local attached = self:_attachModel(character, root, self:_prepareDinosaurClone(sourceModel))
        if attached then
            return true, "dinosaur_model"
        end
    end

    local fallback, reason = self:_createFallbackDinosaur(character, root, state, options)
    if fallback then return true, reason end
    return false, reason
end

function CharacterVisualService:ValidateReleaseVisualAssets()
    local failures = {}
    local egg = self:ResolveImportedEggModel()
    if not egg then
        table.insert(failures, "missing imported egg/nest visual model")
    end
    local speciesResult = SpeciesModelService:ValidateConfiguredModels({ requireExact = true })
    for _, failure in ipairs(speciesResult.failures) do
        table.insert(failures, failure)
    end
    return { passed = #failures == 0, failures = failures }
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
