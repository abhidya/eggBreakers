local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local SpeciesModelService = require(script.Parent.SpeciesModelService)

local CharacterVisualService = {}
CharacterVisualService.VisualFolderName = "_EggBreakersCharacterVisual"
CharacterVisualService.EggVisualName = "EggVisual"
CharacterVisualService.DinosaurVisualName = "DinosaurVisual"
CharacterVisualService.MinimumDinosaurHeight = 4
CharacterVisualService.MinimumDinosaurLength = 7
CharacterVisualService.DefaultDinosaurForwardCorrection = CFrame.new()
CharacterVisualService.DinosaurForwardCorrection = CharacterVisualService.DefaultDinosaurForwardCorrection
CharacterVisualService.DinosaurForwardCorrectionDegrees = 0
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

local function isGameVisualDescendant(instance)
    local current = instance
    while current do
        if current.Name == CharacterVisualService.VisualFolderName or current:GetAttribute("EggBreakersVisual") == true or current:GetAttribute("ImportedVisual") == true then
            return true
        end
        current = current.Parent
    end
    return false
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
        instance.Transparency = math.min(instance.Transparency, 0.05)
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
        if isGameVisualDescendant(descendant) then
            -- Preserve imported egg/dinosaur replacements; only hide the default Roblox avatar.
        elseif descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" then
                descendant.Transparency = 1
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
            end
            changed = true
        elseif not isGameVisualDescendant(descendant) and (descendant:IsA("Decal") or descendant:IsA("Texture")) then
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

function CharacterVisualService:_weldToRoot(part, root, preserveCFrame)
    if not preserveCFrame then
        part.CFrame = root.CFrame
    end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = part
    weld.Parent = part
end

local function axisMax(vector)
    return math.max(vector.X, vector.Y, vector.Z)
end

local function getVisibleParts(instance)
    local parts = {}
    if instance:IsA("BasePart") then
        table.insert(parts, instance)
    end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function boundsFromParts(parts)
    if #parts == 0 then
        return nil, Vector3.new(0, 0, 0)
    end
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, part in ipairs(parts) do
        local half = part.Size / 2
        local position = part.Position
        minX = math.min(minX, position.X - half.X)
        minY = math.min(minY, position.Y - half.Y)
        minZ = math.min(minZ, position.Z - half.Z)
        maxX = math.max(maxX, position.X + half.X)
        maxY = math.max(maxY, position.Y + half.Y)
        maxZ = math.max(maxZ, position.Z + half.Z)
    end
    local min = Vector3.new(minX, minY, minZ)
    local max = Vector3.new(maxX, maxY, maxZ)
    return (min + max) / 2, max - min
end

local function nameContains(instance, patterns)
    local name = string.lower(instance.Name or "")
    for _, pattern in ipairs(patterns) do
        if string.find(name, pattern, 1, true) then
            return true
        end
    end
    return false
end

local function averagePartPosition(parts)
    if #parts == 0 then return nil end
    local sum = Vector3.new(0, 0, 0)
    for _, part in ipairs(parts) do
        sum = sum + part.Position
    end
    return sum / #parts
end

local function namedPartGroups(instance)
    local heads, tails, bodies = {}, {}, {}
    for _, part in ipairs(getVisibleParts(instance)) do
        if nameContains(part, { "head", "skull", "snout", "jaw", "horn", "face" }) then
            table.insert(heads, part)
        elseif nameContains(part, { "tail" }) then
            table.insert(tails, part)
        else
            table.insert(bodies, part)
        end
    end
    return heads, tails, bodies
end

local function horizontalUnit(vector)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    if flat.Magnitude < 0.001 then return nil end
    return flat.Unit
end

local function signedYawBetween(fromVector, toVector)
    local from = horizontalUnit(fromVector)
    local to = horizontalUnit(toVector)
    if not from or not to then return 0 end
    return math.atan2(from:Cross(to).Y, from:Dot(to))
end

local function rotateLooseVisualAroundPivot(instance, pivotCFrame, yawRadians)
    local rotation = CFrame.Angles(0, yawRadians, 0)
    if instance:IsA("BasePart") then
        instance.CFrame = pivotCFrame * rotation * pivotCFrame:ToObjectSpace(instance.CFrame)
        return
    end
    for _, part in ipairs(getVisibleParts(instance)) do
        part.CFrame = pivotCFrame * rotation * pivotCFrame:ToObjectSpace(part.CFrame)
    end
end

function CharacterVisualService:_readableScaleForSize(size)
    local heightScale = size.Y > 0 and (self.MinimumDinosaurHeight / size.Y) or 1
    local lengthScale = axisMax(size) > 0 and (self.MinimumDinosaurLength / axisMax(size)) or 1
    return math.max(1, heightScale, lengthScale)
end

function CharacterVisualService:GrowthVisualScaleForState(state)
    local growth = state and tonumber(state.Growth) or 0
    growth = math.max(0, math.min(100, growth))
    return 1 + (growth / 100) * 0.8
end

function CharacterVisualService:_applyGrowthVisualScale(model, state)
    local growthScale = self:GrowthVisualScaleForState(state)
    if growthScale <= 1 then
        model:SetAttribute("GrowthVisualScale", growthScale)
        model:SetAttribute("GrowthValue", state and state.Growth or 0)
        return
    end

    if model:IsA("Model") then
        local ok = pcall(function()
            local currentScale = model.GetScale and model:GetScale() or 1
            model:ScaleTo(currentScale * growthScale)
        end)
        if not ok then
            local center = model:GetBoundingBox()
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Size = descendant.Size * growthScale
                    descendant.CFrame = CFrame.new(center.Position + (descendant.Position - center.Position) * growthScale) * descendant.CFrame.Rotation
                end
            end
        end
        local _, size = model:GetBoundingBox()
        model:SetAttribute("ReadableHeight", size.Y)
        model:SetAttribute("ReadableLength", axisMax(size))
    elseif model:IsA("BasePart") then
        model.Size = model.Size * growthScale
        model:SetAttribute("ReadableHeight", model.Size.Y)
        model:SetAttribute("ReadableLength", axisMax(model.Size))
    else
        local parts = getVisibleParts(model)
        local center, size = boundsFromParts(parts)
        if center then
            for _, part in ipairs(parts) do
                part.Size = part.Size * growthScale
                part.CFrame = CFrame.new(center + (part.Position - center) * growthScale) * part.CFrame.Rotation
            end
            _, size = boundsFromParts(parts)
        end
        model:SetAttribute("ReadableHeight", size.Y)
        model:SetAttribute("ReadableLength", axisMax(size))
    end

    model:SetAttribute("GrowthVisualScale", growthScale)
    model:SetAttribute("GrowthValue", state and state.Growth or 0)
end

function CharacterVisualService:_normalizeDinosaurScale(model)
    if model:IsA("Model") then
        local _, size = model:GetBoundingBox()
        local scale = self:_readableScaleForSize(size)
        if scale > 1 then
            local ok = pcall(function()
                model:ScaleTo(scale)
            end)
            if not ok then
                for _, descendant in ipairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.Size = descendant.Size * scale
                    end
                end
            end
        end
        local _, normalizedSize = model:GetBoundingBox()
        model:SetAttribute("ReadableScaleApplied", scale)
        model:SetAttribute("ReadableHeight", normalizedSize.Y)
        model:SetAttribute("ReadableLength", axisMax(normalizedSize))
        return normalizedSize
    elseif model:IsA("BasePart") then
        local scale = self:_readableScaleForSize(model.Size)
        if scale > 1 then
            model.Size = model.Size * scale
        end
        model:SetAttribute("ReadableScaleApplied", scale)
        model:SetAttribute("ReadableHeight", model.Size.Y)
        model:SetAttribute("ReadableLength", axisMax(model.Size))
        return model.Size
    end
    local parts = getVisibleParts(model)
    local center, size = boundsFromParts(parts)
    local scale = self:_readableScaleForSize(size)
    if scale > 1 and center then
        for _, part in ipairs(parts) do
            part.Size = part.Size * scale
            part.CFrame = CFrame.new(center + (part.Position - center) * scale) * part.CFrame.Rotation
        end
        _, size = boundsFromParts(parts)
    end
    model:SetAttribute("ReadableScaleApplied", scale)
    model:SetAttribute("ReadableHeight", size.Y)
    model:SetAttribute("ReadableLength", axisMax(size))
    return size
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

function CharacterVisualService:_prepareDinosaurClone(model, state)
    local clone = self:_prepareVisualClone(model, self.DinosaurVisualName)
    clone:SetAttribute("VisualKind", "ImportedDinosaur")
    self:_normalizeDinosaurScale(clone)
    self:_applyGrowthVisualScale(clone, state)
    return clone
end

function CharacterVisualService:_inferDinosaurHeading(model)
    local heads, tails, bodies = namedPartGroups(model)
    local headCenter = averagePartPosition(heads)
    local tailCenter = averagePartPosition(tails)
    local bodyCenter = averagePartPosition(bodies)

    if headCenter and tailCenter then
        return horizontalUnit(headCenter - tailCenter), "head_tail"
    end
    if tailCenter and bodyCenter then
        return horizontalUnit(bodyCenter - tailCenter), "body_tail"
    end
    if headCenter and bodyCenter then
        return horizontalUnit(headCenter - bodyCenter), "head_body"
    end

    local pivot = model:IsA("Model") and model:GetPivot() or (model:IsA("BasePart") and model.CFrame or nil)
    if pivot then
        return horizontalUnit(pivot.LookVector), "pivot_look"
    end
    return nil, "unknown"
end

function CharacterVisualService:_orientDinosaurForward(model, root)
    local heading, source = self:_inferDinosaurHeading(model)
    local target = horizontalUnit(root.CFrame.LookVector)
    if not heading or not target then
        model:SetAttribute("ForwardCorrectionSource", source or "unknown")
        model:SetAttribute("ForwardCorrectionDegrees", 0)
        model:SetAttribute("ForwardFacingDot", 0)
        return 0, 0, source or "unknown"
    end

    local yaw = signedYawBetween(heading, target)
    if math.abs(yaw) > 0.001 then
        if model:IsA("Model") then
            model:PivotTo(model:GetPivot() * CFrame.Angles(0, yaw, 0))
        elseif model:IsA("BasePart") then
            model.CFrame = model.CFrame * CFrame.Angles(0, yaw, 0)
        else
            rotateLooseVisualAroundPivot(model, root.CFrame, yaw)
        end
    end

    local correctedHeading = self:_inferDinosaurHeading(model)
    local dot = correctedHeading and correctedHeading:Dot(target) or 0
    local degrees = math.deg(yaw)
    model:SetAttribute("ForwardCorrectionSource", source)
    model:SetAttribute("ForwardCorrectionDegrees", degrees)
    model:SetAttribute("ForwardFacingDot", dot)
    model:SetAttribute("ForwardFacingVerified", dot >= 0.92)
    return degrees, dot, source
end

function CharacterVisualService:_attachModel(character, root, model)
    local primary = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)) or (model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart", true))
    if not primary then
        model:Destroy()
        return nil
    end

    local folder = self:_visualFolder(character)
    local offsets = {}
    if not model:IsA("Model") and not model:IsA("BasePart") then
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                offsets[descendant] = primary.CFrame:ToObjectSpace(descendant.CFrame)
            end
        end
    end
    model.Parent = folder
    local attachCFrame = root.CFrame
    if model:IsA("Model") then
        model.PrimaryPart = primary
        model:PivotTo(attachCFrame)
    elseif model:IsA("BasePart") then
        model.CFrame = attachCFrame
    else
        for part, offset in pairs(offsets) do
            part.CFrame = attachCFrame * offset
        end
    end
    if model:GetAttribute("VisualKind") == "ImportedDinosaur" then
        self:_orientDinosaurForward(model, root)
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            self:_weldToRoot(descendant, root, model:IsA("Model") or offsets[descendant] ~= nil)
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
        local attached = self:_attachModel(character, root, self:_prepareDinosaurClone(sourceModel, state))
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
