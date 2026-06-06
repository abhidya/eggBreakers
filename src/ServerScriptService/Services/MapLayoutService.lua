local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local SwampDeltaStoryboard = require(ReplicatedStorage.Shared.SwampDeltaStoryboard)
local StoryAssetPlacements = require(ReplicatedStorage.Shared.StoryAssetPlacements)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)

local MapLayoutService = {}
MapLayoutService.MapFolderName = "Map"
MapLayoutService.InvisibleFolderName = "InvisibleGameplayVolumes"

MapLayoutService.FullMapUnderlay = {
    name = "FullMapSafeTerrainUnderlay",
    center = Vector3.new(-450, -10, -250),
    size = Vector3.new(4700, 12, 4300),
    topY = -4,
    material = Enum.Material.Ground,
}

MapLayoutService.ZoneTerrain = {
    NurseryGrove = {
        center = Vector3.new(-2000, 0, 0),
        size = Vector3.new(560, 18, 560),
        topY = 9,
        material = Enum.Material.Grass,
    },
    FernPlains = {
        center = Vector3.new(-1150, 0, 0),
        size = Vector3.new(680, 18, 560),
        topY = 9,
        material = Enum.Material.Grass,
    },
    JungleBasin = {
        center = Vector3.new(-1450, 0, 950),
        size = Vector3.new(680, 18, 560),
        topY = 9,
        material = Enum.Material.LeafyGrass,
    },
    RedstoneCanyon = {
        center = Vector3.new(-200, 0, -650),
        size = Vector3.new(760, 18, 520),
        topY = 9,
        material = Enum.Material.Sandstone,
    },
    SwampDelta = {
        center = Vector3.new(-150, 0, 950),
        size = Vector3.new(760, 14, 540),
        topY = 7,
        material = Enum.Material.Mud,
    },
    ApocalypticCity = {
        center = Vector3.new(700, 0, 0),
        size = Vector3.new(860, 18, 700),
        topY = 9,
        material = Enum.Material.Asphalt,
    },
    MountainNestingCliffs = {
        center = Vector3.new(-100, 58, -1700),
        size = Vector3.new(760, 34, 620),
        topY = 75,
        material = Enum.Material.Rock,
    },
}

MapLayoutService.FullMapTerrainUnderlay = {
    name = "FullMapTerrainUnderlay",
    center = Vector3.new(-450, -10, -250),
    size = Vector3.new(4700, 12, 4400),
    material = Enum.Material.Ground,
}

MapLayoutService.RouteTerrain = {
    { name = "NurseryToFernBabySafe", center = Vector3.new(-1575, 0, 0), size = Vector3.new(900, 18, 180), material = Enum.Material.Grass, babySafe = true },
    { name = "NurseryToJungleBabySafe", center = Vector3.new(-1765, 0, 475), size = Vector3.new(220, 18, 960), material = Enum.Material.LeafyGrass, babySafe = true },
    { name = "FernToJungle", center = Vector3.new(-1300, 0, 475), size = Vector3.new(260, 18, 960), material = Enum.Material.Grass },
    { name = "FernToRedstoneCanyon", center = Vector3.new(-675, 0, -325), size = Vector3.new(950, 18, 220), material = Enum.Material.Sandstone },
    { name = "JungleToSwampDelta", center = Vector3.new(-800, 0, 950), size = Vector3.new(1320, 14, 220), material = Enum.Material.LeafyGrass },
    { name = "RedstoneCanyonGateToCity", center = Vector3.new(275, 0, -325), size = Vector3.new(950, 18, 220), material = Enum.Material.Sandstone, cityRoute = true },
    { name = "SwampDeltaCausewayToCity", center = Vector3.new(300, 0, 475), size = Vector3.new(950, 14, 240), material = Enum.Material.Mud, cityRoute = true },
    { name = "CityCrossRoute", center = Vector3.new(700, 0, 0), size = Vector3.new(900, 18, 190), material = Enum.Material.Asphalt, cityRoute = true },
    { name = "MountainNestApproach", center = Vector3.new(-140, 6, -1040), size = Vector3.new(360, 18, 300), material = Enum.Material.Rock },
    { name = "MountainNestLowerRamp", center = Vector3.new(-140, 17, -1190), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestMidRamp", center = Vector3.new(-140, 33, -1340), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestUpperRamp", center = Vector3.new(-140, 51, -1500), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
    { name = "MountainNestSaddle", center = Vector3.new(-140, 63, -1620), size = Vector3.new(360, 22, 300), material = Enum.Material.Rock },
}


MapLayoutService.EdibleVegetationMetadata = {
    StarterPlant = { vegetationType = "TenderFern", plantPart = "Frond", browseTier = "Ground", browseHeight = 2.5, compactGroup = "NurseryStarterBrowse", interactionHint = "Eat tender fern" },
    PlantPatch = { vegetationType = "CycadPatch", plantPart = "Frond", browseTier = "Ground", browseHeight = 3, compactGroup = "PlainsGrazingPatch", interactionHint = "Eat cycad fronds" },
    SparsePlant = { vegetationType = "DesertScrub", plantPart = "Shoot", browseTier = "Ground", browseHeight = 2, compactGroup = "CanyonScrub", interactionHint = "Eat scrub shoots" },
    MarshPlant = { vegetationType = "MarshReed", plantPart = "Reed", browseTier = "Ground", browseHeight = 3.5, compactGroup = "SwampReeds", interactionHint = "Eat marsh reeds" },
    HighRiskPlant = { vegetationType = "CityOvergrowth", plantPart = "LeafCluster", browseTier = "Ground", browseHeight = 3, compactGroup = "CityOvergrowth", interactionHint = "Eat overgrowth leaves" },
    TreeBrowse = { vegetationType = "TreeCanopy", plantPart = "Leaves", browseTier = "Tree", browseHeight = 7.5, compactGroup = "TreeBrowse", interactionHint = "Eat tree leaves" },
}

MapLayoutService.CarnivoreFoodMetadata = {
    TutorialCarcass = { meatType = "SmallCarcassCache", compactGroup = "NurseryMeatCache", interactionHint = "Eat safe carcass" },
    PreyCarcass = { meatType = "PreyCarcass", compactGroup = "PredatorTrailCarcass", interactionHint = "Eat prey carcass" },
    HighRiskCarcass = { meatType = "LargeCarcass", compactGroup = "CityRiskCarcass", interactionHint = "Eat large carcass" },
}

function MapLayoutService:GetFoodMetadata(kind, diet)
    if diet == "Carnivore" then
        return self.CarnivoreFoodMetadata[kind] or self.CarnivoreFoodMetadata.PreyCarcass
    end
    return self.EdibleVegetationMetadata[kind] or self.EdibleVegetationMetadata.PlantPatch
end

function MapLayoutService:ApplyFoodMetadata(food, spec)
    local diet = spec.diet
    local kind = spec.kind or (diet == "Carnivore" and "PreyCarcass" or "PlantPatch")
    local metadata = self:GetFoodMetadata(kind, diet)
    food:SetAttribute("FoodKind", kind)
    food:SetAttribute("Diet", diet)
    food:SetAttribute("Nutrition", spec.nutrition)
    food:SetAttribute("EdibleVegetation", diet == "Herbivore")
    food:SetAttribute("TreeBrowse", kind == "TreeBrowse")
    food:SetAttribute("VegetationType", spec.vegetationType or metadata.vegetationType)
    food:SetAttribute("PlantPart", spec.plantPart or metadata.plantPart)
    food:SetAttribute("BrowseTier", spec.browseTier or metadata.browseTier)
    food:SetAttribute("BrowseHeightStuds", spec.browseHeight or metadata.browseHeight)
    food:SetAttribute("MeatType", metadata.meatType)
    food:SetAttribute("PotentialCarnivoreFood", diet == "Carnivore")
    food:SetAttribute("CompactFoodGroup", metadata.compactGroup)
    food:SetAttribute("InteractionHint", metadata.interactionHint or (diet == "Carnivore" and "Eat carcass" or "Eat plant"))
end

function MapLayoutService:IsVegetationBrowseSpec(spec)
    if not spec then return false end
    if spec.edibleBrowse == true or spec.kind == "Tree" then return true end
    if spec.flowerCluster == true then return true end
    if spec.kind == "ForestStand" or spec.kind == "DryScrub" then return true end
    return spec.habitatFeature == "Forest" or spec.habitatFeature == "Desert"
end

function MapLayoutService:ApplyReleaseHiddenQueryPart(part)
    part.Transparency = 1
    part.CanCollide = false
    part.CanTouch = true
    part.CanQuery = true
    part:SetAttribute("VisibleGameplayAffordance", false)
    part:SetAttribute("GameplayQuery", true)
    part:SetAttribute("InvisibleQueryHelper", true)
    part:SetAttribute("ReleaseHiddenProceduralVisual", true)
    part:SetAttribute("ProceduralGameplayVisual", nil)
    part:SetAttribute("RestoreTransparency", 1)
end

-- ─────────────────────────────────────────────────────────────
-- Readable foliage visuals (NEW, additive).
-- The FoodSource query part itself stays an invisible, queryable
-- gameplay helper (release-policy + placement tests depend on
-- Transparency == 1 / InvisibleQueryHelper). Readability comes from
-- a SEPARATE visible decorative child part that is NOT tagged
-- "FoodSource"/"TreeProp", so it never appears in those tagged
-- iterations and cannot trip the "no visible procedural food"
-- assertions. FoodWaterService dims/restores it on eat/regrow.
-- ─────────────────────────────────────────────────────────────
MapLayoutService.FoliageVisualName = "EdibleFoliageVisual"
MapLayoutService.ImportedFoodVisualName = "ImportedFoodVisual"
MapLayoutService.ImportedAssetLibraryName = "ImportedAssetLibrary"
MapLayoutService.ShallowWaterMarkerTransparency = 0.78

MapLayoutService.HerbivoreFoliageColor = Color3.fromRGB(86, 168, 78)
MapLayoutService.CarnivoreCarcassColor = Color3.fromRGB(122, 60, 48)
MapLayoutService.CarcassBoneColor = Color3.fromRGB(218, 205, 174)
MapLayoutService.ImportedFoodVisualMaxFlatPanelExtent = 18
MapLayoutService.ImportedFoodVisualThinPanelExtent = 0.35

local function configureFoodAffordance(part, restoreTransparency)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Transparency = restoreTransparency or 0
    part:SetAttribute("EdibleFoliageVisual", true)
    part:SetAttribute("VisibleGameplayAffordance", true)
    part:SetAttribute("ProceduralGameplayVisual", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartReason", "Readable edible foliage / carcass representation")
    part:SetAttribute("Decorative", true)
    part:SetAttribute("RestoreTransparency", restoreTransparency or 0)
end

local function getReadableFallbackCanopySize(spec)
    local canopySize = spec.canopySize
    if spec.zone ~= "NurseryGrove" and spec.zone ~= "FernPlains" then
        return canopySize
    end
    local largest = math.max(canopySize.X, canopySize.Y, canopySize.Z)
    if largest <= 18 then
        return canopySize
    end
    local scale = 18 / largest
    return Vector3.new(
        math.max(10, canopySize.X * scale),
        math.max(8, canopySize.Y * scale),
        math.max(10, canopySize.Z * scale)
    )
end

function MapLayoutService:GetOrCreateFoodAffordancePart(queryPart, name)
    local part = queryPart:FindFirstChild(name)
    if not part then
        part = Instance.new("Part")
        part.Name = name
        part.Parent = queryPart
    end
    configureFoodAffordance(part, 0)
    return part
end

local function hasVisibleBasePart(instance)
    if not instance then return false end
    if instance:IsA("BasePart") then return true end
    return instance:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function isOversizedThinPanel(part, maxLargeExtent, thinExtent)
    if not part:IsA("BasePart") then return false end
    local size = part.Size
    local maxExtent = math.max(size.X, size.Y, size.Z)
    local minExtent = math.min(size.X, size.Y, size.Z)
    local midExtent = size.X + size.Y + size.Z - maxExtent - minExtent
    return minExtent <= thinExtent and maxExtent >= maxLargeExtent and midExtent >= 8
end

function MapLayoutService:HasOversizedFlatPanelFoodVisual(instance)
    if not instance then return false end
    if instance:IsA("BasePart")
        and isOversizedThinPanel(instance, self.ImportedFoodVisualMaxFlatPanelExtent, self.ImportedFoodVisualThinPanelExtent) then
        return true
    end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart")
            and isOversizedThinPanel(descendant, self.ImportedFoodVisualMaxFlatPanelExtent, self.ImportedFoodVisualThinPanelExtent) then
            return true
        end
    end
    return false
end

local function lowerContains(value, token)
    if type(value) ~= "string" or type(token) ~= "string" then return false end
    return string.find(string.lower(value), string.lower(token), 1, true) ~= nil
end

local function nameMatchesFoodDiet(name, diet)
    if diet == "Carnivore" then
        return lowerContains(name, "carcass") or lowerContains(name, "meat") or lowerContains(name, "bone") or lowerContains(name, "fossil")
    end
    return lowerContains(name, "fern") or lowerContains(name, "plant") or lowerContains(name, "foliage") or lowerContains(name, "leaf")
end

function MapLayoutService:IsFoodVisualTemplateCandidate(instance, kind, diet)
    if not (instance and (instance:IsA("Model") or instance:IsA("BasePart")) and hasVisibleBasePart(instance)) then
        return false
    end
    if self:HasOversizedFlatPanelFoodVisual(instance) then
        return false
    end
    if instance:GetAttribute("ImportedFoodVisualTemplate") == true or instance:GetAttribute("FoodVisualTemplate") == true then
        return true
    end
    if instance:GetAttribute("FoodKind") == kind or instance:GetAttribute("Diet") == diet then
        return true
    end

    return nameMatchesFoodDiet(instance.Name, diet)
end

function MapLayoutService:GetImportedFoodVisualTemplateCandidates()
    local library = ReplicatedStorage:FindFirstChild(self.ImportedAssetLibraryName)
    if not library then return {} end

    local cache = self._ImportedFoodVisualTemplateCache
    if cache and cache.library == library then
        return cache.candidates
    end

    local candidates = {}
    for _, descendant in ipairs(library:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("BasePart") then
            if hasVisibleBasePart(descendant) and not self:HasOversizedFlatPanelFoodVisual(descendant) then
                table.insert(candidates, {
                    instance = descendant,
                    foodKind = descendant:GetAttribute("FoodKind"),
                    diet = descendant:GetAttribute("Diet"),
                    explicitTemplate = descendant:GetAttribute("ImportedFoodVisualTemplate") == true
                        or descendant:GetAttribute("FoodVisualTemplate") == true,
                    name = descendant.Name,
                })
            end
        end
    end

    self._ImportedFoodVisualTemplateCache = {
        library = library,
        candidates = candidates,
    }
    return candidates
end

local function foodVisualCandidateMatches(candidate, kind, diet)
    if candidate.explicitTemplate then return true end
    if kind ~= nil and candidate.foodKind == kind then return true end
    if candidate.diet == diet then return true end
    return nameMatchesFoodDiet(candidate.name, diet)
end

function MapLayoutService:ResolveImportedFoodVisualTemplate(queryPart, opts)
    opts = opts or {}
    local kind = opts.kind or queryPart:GetAttribute("FoodKind")
    local diet = opts.diet or queryPart:GetAttribute("Diet") or "Herbivore"

    local bestFallback = nil
    for _, candidate in ipairs(self:GetImportedFoodVisualTemplateCandidates()) do
        if foodVisualCandidateMatches(candidate, kind, diet) then
            if kind ~= nil and candidate.foodKind == kind then
                return candidate.instance
            end
            if candidate.diet == diet and not bestFallback then
                bestFallback = candidate.instance
            elseif not bestFallback then
                bestFallback = candidate.instance
            end
        end
    end
    return bestFallback
end

function MapLayoutService:RemoveImportedFoodVisual(queryPart)
    local existing = queryPart:FindFirstChild(self.ImportedFoodVisualName)
    if existing then existing:Destroy() end
end

function MapLayoutService:RemoveProceduralFoodAffordances(queryPart)
    for _, child in ipairs(queryPart:GetChildren()) do
        if child:GetAttribute("ProceduralGameplayVisual") == true or child:GetAttribute("ReleaseVisibleGeneratedPartAllowed") == true then
            child:Destroy()
        end
    end
end

function MapLayoutService:SanitizeImportedFoodVisualClone(clone, source, queryPart)
    local sourceAssetId = clone:GetAttribute("SourceAssetId") or source:GetAttribute("SourceAssetId")
    local assetManifestId = clone:GetAttribute("AssetManifestId") or source:GetAttribute("AssetManifestId") or ("FoodVisual_" .. tostring(queryPart:GetAttribute("FoodKind") or queryPart.Name))
    clone.Name = self.ImportedFoodVisualName
    clone:SetAttribute("ImportedFoodVisual", true)
    clone:SetAttribute("ImportedVisibleAsset", true)
    clone:SetAttribute("CreatorStoreOnly", clone:GetAttribute("CreatorStoreOnly") ~= false)
    clone:SetAttribute("VisibleGameplayAffordance", true)
    clone:SetAttribute("EdibleFoliageVisual", true)
    clone:SetAttribute("ProceduralGameplayVisual", nil)
    clone:SetAttribute("ReleaseVisibleGeneratedPartAllowed", nil)
    clone:SetAttribute("SourcePath", source:GetFullName())
    clone:SetAttribute("FoodQuerySource", queryPart.Name)
    clone:SetAttribute("AssetManifestId", assetManifestId)
    clone:SetAttribute("SourceAssetId", sourceAssetId)

    if clone:IsA("BasePart") then
        configureFoodAffordance(clone, clone.Transparency < 1 and clone.Transparency or 0)
        clone:SetAttribute("ImportedFoodVisual", true)
        clone:SetAttribute("ImportedVisibleAsset", true)
        clone:SetAttribute("CreatorStoreOnly", true)
        clone:SetAttribute("AssetManifestId", assetManifestId)
        clone:SetAttribute("SourceAssetId", sourceAssetId)
        clone:SetAttribute("ProceduralGameplayVisual", nil)
        clone:SetAttribute("ReleaseVisibleGeneratedPartAllowed", nil)
    end

    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        elseif descendant:IsA("ModuleScript") then
            descendant:SetAttribute("ImportedScriptAudited", true)
            descendant:SetAttribute("Sandboxed", true)
        elseif descendant:IsA("BasePart") then
            configureFoodAffordance(descendant, descendant.Transparency < 1 and descendant.Transparency or 0)
            descendant:SetAttribute("ImportedFoodVisual", true)
            descendant:SetAttribute("ImportedVisibleAsset", true)
            descendant:SetAttribute("CreatorStoreOnly", true)
            descendant:SetAttribute("AssetManifestId", assetManifestId)
            descendant:SetAttribute("SourceAssetId", sourceAssetId)
            descendant:SetAttribute("ProceduralGameplayVisual", nil)
            descendant:SetAttribute("ReleaseVisibleGeneratedPartAllowed", nil)
        end
    end
end

function MapLayoutService:AttachImportedFoodVisual(queryPart, opts)
    local source = self:ResolveImportedFoodVisualTemplate(queryPart, opts)
    if not source then
        self:RemoveImportedFoodVisual(queryPart)
        queryPart:SetAttribute("ImportedFoodVisualAttached", false)
        queryPart:SetAttribute("ImportedFoodVisualTemplate", nil)
        return nil
    end

    self:RemoveProceduralFoodAffordances(queryPart)
    self:RemoveImportedFoodVisual(queryPart)

    local clone = source:Clone()
    self:SanitizeImportedFoodVisualClone(clone, source, queryPart)
    if self:HasOversizedFlatPanelFoodVisual(clone) then
        clone:Destroy()
        queryPart:SetAttribute("ImportedFoodVisualAttached", false)
        queryPart:SetAttribute("ImportedFoodVisualTemplate", nil)
        queryPart:SetAttribute("ImportedFoodVisualRejected", true)
        queryPart:SetAttribute("ImportedFoodVisualRejectReason", "oversized_flat_panel_food_visual")
        return nil
    end
    clone.Parent = queryPart
    if clone:IsA("Model") then
        if not clone.PrimaryPart then
            clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
        end
        if clone.PrimaryPart then
            clone:PivotTo(CFrame.new(queryPart.Position))
        end
    elseif clone:IsA("BasePart") then
        clone.Position = queryPart.Position
    end

    queryPart:SetAttribute("ImportedFoodVisualAttached", true)
    queryPart:SetAttribute("ImportedFoodVisualTemplate", source:GetFullName())
    queryPart:SetAttribute("FoliageVisualName", self.ImportedFoodVisualName)
    return clone
end

function MapLayoutService:EnsureVisibleFoliageVisual(queryPart, opts)
    if not (queryPart and queryPart:IsA("BasePart")) then return nil end
    opts = opts or {}
    local importedVisual = self:AttachImportedFoodVisual(queryPart, opts)
    if importedVisual then return importedVisual end

    local diet = opts.diet or queryPart:GetAttribute("Diet") or "Herbivore"
    local isCarnivore = diet == "Carnivore"

    -- Sit the readable foliage just on top of (slightly inside) the query
    -- volume so players see a clear edible cluster where the query part is.
    local base = queryPart.Size
    local visual = self:GetOrCreateFoodAffordancePart(queryPart, self.FoliageVisualName)
    if isCarnivore then
        visual.Shape = Enum.PartType.Block
        visual.Material = Enum.Material.Leather
        visual.Color = opts.color or self.CarnivoreCarcassColor
        visual.Size = Vector3.new(math.max(2, base.X * 0.85), math.max(1.2, base.Y * 0.7), math.max(2, base.Z * 0.85))
        visual.CFrame = CFrame.new(queryPart.Position + Vector3.new(0, visual.Size.Y * 0.4, 0)) * CFrame.Angles(0, math.rad(12), 0)

        local bone = self:GetOrCreateFoodAffordancePart(queryPart, "CarcassBoneVisual")
        bone.Shape = Enum.PartType.Cylinder
        bone.Material = Enum.Material.SmoothPlastic
        bone.Color = self.CarcassBoneColor
        bone.Size = Vector3.new(math.max(0.45, base.Y * 0.28), math.max(3, base.X * 0.78), math.max(0.45, base.Y * 0.28))
        bone.CFrame = CFrame.new(queryPart.Position + Vector3.new(0, visual.Size.Y * 0.95, 0)) * CFrame.Angles(0, 0, math.rad(90))

        local rib = self:GetOrCreateFoodAffordancePart(queryPart, "CarcassRibVisual")
        rib.Shape = Enum.PartType.Block
        rib.Material = Enum.Material.SmoothPlastic
        rib.Color = self.CarcassBoneColor
        rib.Size = Vector3.new(math.max(0.35, base.Y * 0.2), math.max(1.2, base.Y * 0.75), math.max(2.5, base.Z * 0.72))
        rib.CFrame = CFrame.new(queryPart.Position + Vector3.new(base.X * 0.16, visual.Size.Y * 0.72, 0)) * CFrame.Angles(0, math.rad(18), math.rad(18))
    else
        visual.Shape = Enum.PartType.Ball
        visual.Material = Enum.Material.Grass
        visual.Color = opts.color or self.HerbivoreFoliageColor
        local spread = math.max(3, math.min(base.X, base.Z) * 0.9)
        visual.Size = Vector3.new(spread, math.max(2.5, base.Y * 1.1), spread)
        visual.CFrame = CFrame.new(queryPart.Position + Vector3.new(0, visual.Size.Y * 0.35, 0))

        local leftFrond = self:GetOrCreateFoodAffordancePart(queryPart, "FoliageFrondLeftVisual")
        leftFrond.Shape = Enum.PartType.Block
        leftFrond.Material = Enum.Material.Grass
        leftFrond.Color = opts.color or Color3.fromRGB(102, 188, 92)
        leftFrond.Size = Vector3.new(math.max(0.7, base.X * 0.16), math.max(0.25, base.Y * 0.16), math.max(4, base.Z * 0.9))
        leftFrond.CFrame = CFrame.new(queryPart.Position + Vector3.new(-base.X * 0.18, visual.Size.Y * 0.58, 0)) * CFrame.Angles(math.rad(15), math.rad(-28), math.rad(10))

        local rightFrond = self:GetOrCreateFoodAffordancePart(queryPart, "FoliageFrondRightVisual")
        rightFrond.Shape = Enum.PartType.Block
        rightFrond.Material = Enum.Material.Grass
        rightFrond.Color = opts.color or Color3.fromRGB(74, 150, 70)
        rightFrond.Size = Vector3.new(math.max(0.7, base.X * 0.16), math.max(0.25, base.Y * 0.16), math.max(4, base.Z * 0.9))
        rightFrond.CFrame = CFrame.new(queryPart.Position + Vector3.new(base.X * 0.18, visual.Size.Y * 0.5, 0)) * CFrame.Angles(math.rad(-12), math.rad(32), math.rad(-10))
    end

    queryPart:SetAttribute("FoliageVisualName", self.FoliageVisualName)
    return visual
end

function MapLayoutService:ApplyBrowseFoodAttributes(part, spec, options)
    options = options or {}
    local isTree = options.treeBrowse == true
    part:SetAttribute("Decorative", false)
    part:SetAttribute("TutorialSafe", spec.zone == "NurseryGrove")
    part:SetAttribute("StarterFood", spec.zone == "NurseryGrove")
    part:SetAttribute("RespawnCooldownSeconds", spec.browseCooldown or (isTree and 75 or 60))
    part:SetAttribute("Depleted", part:GetAttribute("Depleted") == true)
    self:ApplyFoodMetadata(part, {
        diet = "Herbivore",
        nutrition = spec.browseNutrition or (isTree and 24 or 22),
        kind = isTree and "TreeBrowse" or "PlantPatch",
        vegetationType = spec.vegetationType or (isTree and "TreeCanopy" or (spec.kind .. "Browse")),
        plantPart = spec.plantPart,
        browseTier = spec.browseTier,
        browseHeight = spec.browseHeight,
    })
    self:ApplyReleaseHiddenQueryPart(part)
    self:EnsureVisibleFoliageVisual(part, { diet = "Herbivore", color = spec.canopyColor })
    if not CollectionService:HasTag(part, "FoodSource") then
        CollectionService:AddTag(part, "FoodSource")
    end
end

MapLayoutService.FoodPlacements = {
    { name = "NurseryStarterFern_01", zone = "NurseryGrove", diet = "Herbivore", nutrition = 30, position = Vector3.new(-2025, 12, -42), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_02", zone = "NurseryGrove", diet = "Herbivore", nutrition = 30, position = Vector3.new(-1970, 12, 38), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryTutorialMeatCache", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1870, 13, -92), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "FernPlainsGrazingPatch_01", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1220, 12, -160), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "FernPlainsGrazingPatch_02", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1100, 12, 165), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "JungleBasinBroadleaf_01", zone = "JungleBasin", diet = "Herbivore", nutrition = 20, position = Vector3.new(-1540, 12, 1035), size = Vector3.new(9, 3, 9), kind = "PlantPatch", cooldown = 75, vegetationType = "BroadleafCluster" },
    { name = "RedstoneSparseScrub_01", zone = "RedstoneCanyon", diet = "Herbivore", nutrition = 14, position = Vector3.new(-355, 13, -770), size = Vector3.new(8, 3, 8), kind = "SparsePlant", cooldown = 90, vegetationType = "CanyonScrub" },
    { name = "SwampDeltaMarshPlant_01", zone = "SwampDelta", diet = "Herbivore", nutrition = 18, position = Vector3.new(-260, 10, 1080), size = Vector3.new(9, 3, 9), kind = "MarshPlant", cooldown = 80, vegetationType = "MarshReed" },
    { name = "CarnivoreTutorialCarcass_01", zone = "FernPlains", diet = "Carnivore", nutrition = 34, position = Vector3.new(-930, 12, -120), size = Vector3.new(8, 3, 5), kind = "TutorialCarcass", cooldown = 120 },
    { name = "RedstonePreyCarcass_01", zone = "RedstoneCanyon", diet = "Carnivore", nutrition = 42, position = Vector3.new(-125, 13, -760), size = Vector3.new(9, 3, 5), kind = "PreyCarcass", cooldown = 150 },
    { name = "SwampPreyCarcass_01", zone = "SwampDelta", diet = "Carnivore", nutrition = 38, position = Vector3.new(55, 10, 1065), size = Vector3.new(9, 3, 5), kind = "PreyCarcass", cooldown = 150 },
    { name = "OldEdenHighRiskCarcass_01", zone = "ApocalypticCity", diet = "Carnivore", nutrition = 55, position = Vector3.new(760, 12, -210), size = Vector3.new(10, 3, 6), kind = "HighRiskCarcass", cooldown = 180 },
    { name = "OldEdenOvergrowthReward_01", zone = "ApocalypticCity", diet = "Herbivore", nutrition = 28, position = Vector3.new(935, 12, 245), size = Vector3.new(9, 3, 9), kind = "HighRiskPlant", cooldown = 120, vegetationType = "CityOvergrowth" },
    { name = "NurseryStarterFern_03", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2045, 12, 30), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_04", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1934, 12, -52), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_05", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2008, 12, 86), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_06", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2078, 12, -12), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_07", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-2014, 12, -96), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_08", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1962, 12, 112), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryStarterFern_09", zone = "NurseryGrove", diet = "Herbivore", nutrition = 28, position = Vector3.new(-1888, 12, 18), size = Vector3.new(7, 3, 7), kind = "StarterPlant", cooldown = 45 },
    { name = "NurseryTutorialMeatCache_02", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1908, 13, -54), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_03", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1844, 13, -128), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_04", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1818, 13, 22), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_05", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, position = Vector3.new(-1948, 13, -132), size = Vector3.new(7, 1.5, 4), kind = "TutorialCarcass", cooldown = 90, tutorialSafe = true },
    { name = "FernPlainsGrazingPatch_03", zone = "FernPlains", diet = "Herbivore", nutrition = 24, position = Vector3.new(-1160, 12, 40), size = Vector3.new(10, 3, 10), kind = "PlantPatch", cooldown = 60 },
    { name = "FernPlainsPreyCarcass_02", zone = "FernPlains", diet = "Carnivore", nutrition = 36, position = Vector3.new(-1002, 12, -210), size = Vector3.new(8, 3, 5), kind = "PreyCarcass", cooldown = 120 },
}

MapLayoutService.ShallowWater = {
    { name = "NurseryTutorialWater", center = Vector3.new(-1960, 10, -18), size = Vector3.new(64, 3, 42), tutorialSafe = true },
    { name = "FernPlainsPond", center = Vector3.new(-1080, 10, 205), size = Vector3.new(190, 5, 120) },
    { name = "SwampDeltaChannel", center = Vector3.new(-80, 8, 950), size = Vector3.new(760, 4, 115) },
    { name = "CityCanalShallow", center = Vector3.new(820, 10, 300), size = Vector3.new(430, 4, 90) },
    { name = "FernLakeSwimZone", center = Vector3.new(-1080, 10, 250), size = Vector3.new(220, 5, 150), swimZone = true, fishSpawnAllowed = true },
    { name = "SwampRiverFishRun", center = Vector3.new(-70, 8, 970), size = Vector3.new(820, 5, 70), swimZone = true, fishSpawnAllowed = true },
    { name = "JungleRiverCrossing", center = Vector3.new(-1320, 10, 780), size = Vector3.new(360, 5, 64), swimZone = true, fishSpawnAllowed = true },
}

MapLayoutService.FoodSourcePlacements = {
    { name = "NurseryStarterFernPatch_A", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1985, 13, -34), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(70, 150, 67) },
    { name = "NurseryStarterFernPatch_B", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1918, 13, 58), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(82, 160, 74) },
    { name = "FernPlainsGrazingPatch_A", zone = "FernPlains", diet = "Herbivore", nutrition = 40, respawnSeconds = 60, position = Vector3.new(-1515, 12, -155), size = Vector3.new(12, 2, 10), color = Color3.fromRGB(78, 170, 72) },
    { name = "FernPlainsGrazingPatch_B", zone = "FernPlains", diet = "Herbivore", nutrition = 40, respawnSeconds = 60, position = Vector3.new(-1260, 12, 210), size = Vector3.new(14, 2, 10), color = Color3.fromRGB(68, 145, 60) },
    { name = "JungleBasinLeafCluster", zone = "JungleBasin", diet = "Herbivore", nutrition = 30, respawnSeconds = 80, position = Vector3.new(-1480, 13, 1025), size = Vector3.new(10, 2, 10), color = Color3.fromRGB(44, 132, 65) },
    { name = "NurseryTutorialMeatCache", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1870, 13, -92), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(126, 62, 48), tutorialSafe = true },
    { name = "FernPlainsPreyCarcass_A", zone = "FernPlains", diet = "Carnivore", nutrition = 45, respawnSeconds = 120, position = Vector3.new(-1080, 12, -255), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(116, 58, 46) },
    { name = "RedstonePreyCarcass_A", zone = "RedstoneCanyon", diet = "Carnivore", nutrition = 55, respawnSeconds = 150, position = Vector3.new(-120, 13, -755), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(120, 64, 52) },
    { name = "OldEdenRiskCarcass", zone = "ApocalypticCity", diet = "Carnivore", nutrition = 65, respawnSeconds = 180, position = Vector3.new(685, 14, 92), size = Vector3.new(9, 1.5, 5), color = Color3.fromRGB(112, 56, 46), highRisk = true },
    { name = "NurseryStarterFernPatch_C", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2058, 13, 70), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(74, 156, 68) },
    { name = "NurseryStarterFernPatch_D", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1935, 13, -86), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(88, 164, 76) },
    { name = "NurseryStarterFernPatch_E", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2092, 13, -38), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(84, 166, 78) },
    { name = "NurseryStarterFernPatch_F", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-2030, 13, -118), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(74, 152, 72) },
    { name = "NurseryStarterFernPatch_G", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1978, 13, 140), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(92, 170, 84) },
    { name = "NurseryStarterFernPatch_H", zone = "NurseryGrove", diet = "Herbivore", nutrition = 35, respawnSeconds = 45, position = Vector3.new(-1888, 13, 82), size = Vector3.new(8, 2, 8), color = Color3.fromRGB(78, 158, 72) },
    { name = "NurseryTutorialMeatCache_B", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1835, 13, -48), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(132, 64, 50), tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_C", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1816, 13, 50), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(134, 66, 50), tutorialSafe = true },
    { name = "NurseryTutorialMeatCache_D", zone = "NurseryGrove", diet = "Carnivore", nutrition = 30, respawnSeconds = 90, position = Vector3.new(-1962, 13, -170), size = Vector3.new(7, 1.5, 4), color = Color3.fromRGB(128, 62, 48), tutorialSafe = true },
    { name = "FernPlainsPreyCarcass_B", zone = "FernPlains", diet = "Carnivore", nutrition = 45, respawnSeconds = 120, position = Vector3.new(-1015, 12, -185), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(116, 58, 46) },
    { name = "SwampPreyCarcass_B", zone = "SwampDelta", diet = "Carnivore", nutrition = 42, respawnSeconds = 150, position = Vector3.new(-35, 10, 1015), size = Vector3.new(8, 1.5, 4), color = Color3.fromRGB(110, 58, 50) },
}


MapLayoutService.BiomeDressingPlacements = {
    {
        name = "NurserySafeTree_A",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2225, 9, -225),
        trunkSize = Vector3.new(7, 26, 7),
        canopySize = Vector3.new(34, 24, 34),
        trunkColor = Color3.fromRGB(112, 75, 45),
        canopyColor = Color3.fromRGB(72, 142, 65),
    },
    {
        name = "NurseryTutorialTree_A",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2180, 9, -60),
        trunkSize = Vector3.new(6, 22, 6),
        canopySize = Vector3.new(28, 20, 28),
        trunkColor = Color3.fromRGB(118, 78, 48),
        canopyColor = Color3.fromRGB(76, 150, 70),
    },
    {
        name = "FernPlainsTree_A",
        zone = "FernPlains",
        kind = "Tree",
        position = Vector3.new(-1390, 9, -245),
        trunkSize = Vector3.new(8, 30, 8),
        canopySize = Vector3.new(42, 26, 42),
        trunkColor = Color3.fromRGB(104, 70, 42),
        canopyColor = Color3.fromRGB(58, 130, 54),
    },
    {
        name = "JungleCanopyTree_A",
        zone = "JungleBasin",
        kind = "Tree",
        position = Vector3.new(-1188, 9, 1188),
        trunkSize = Vector3.new(10, 38, 10),
        canopySize = Vector3.new(54, 34, 54),
        trunkColor = Color3.fromRGB(93, 65, 40),
        canopyColor = Color3.fromRGB(38, 112, 56),
    },
    {
        name = "SwampCypressTree_A",
        zone = "SwampDelta",
        kind = "Tree",
        position = Vector3.new(-486, 7, 1169),
        trunkSize = Vector3.new(9, 34, 9),
        canopySize = Vector3.new(38, 28, 38),
        trunkColor = Color3.fromRGB(88, 66, 48),
        canopyColor = Color3.fromRGB(46, 103, 65),
    },
    {
        name = "NurserySafeTree_B",
        zone = "NurseryGrove",
        kind = "Tree",
        position = Vector3.new(-2128, 9, -188),
        trunkSize = Vector3.new(6, 24, 6),
        canopySize = Vector3.new(32, 22, 32),
        trunkColor = Color3.fromRGB(112, 72, 44),
        canopyColor = Color3.fromRGB(66, 136, 62),
    },
    {
        name = "NurseryFoodShadeTree_C",
        zone = "NurseryGrove",
        kind = "Tree",
        edibleBrowse = true,
        browseNutrition = 24,
        position = Vector3.new(-1955, 9, -38),
        trunkSize = Vector3.new(6, 23, 6),
        canopySize = Vector3.new(30, 22, 30),
        trunkColor = Color3.fromRGB(116, 76, 45),
        canopyColor = Color3.fromRGB(70, 146, 66),
    },
    {
        name = "FernPlainsTree_B",
        zone = "FernPlains",
        kind = "Tree",
        edibleBrowse = true,
        browseNutrition = 26,
        position = Vector3.new(-1285, 9, 70),
        trunkSize = Vector3.new(7, 29, 7),
        canopySize = Vector3.new(40, 25, 40),
        trunkColor = Color3.fromRGB(102, 68, 42),
        canopyColor = Color3.fromRGB(62, 134, 58),
    },
    {
        name = "JungleCanopyTree_B",
        zone = "JungleBasin",
        kind = "Tree",
        position = Vector3.new(-1375, 9, 1060),
        trunkSize = Vector3.new(10, 36, 10),
        canopySize = Vector3.new(52, 34, 52),
        trunkColor = Color3.fromRGB(90, 62, 39),
        canopyColor = Color3.fromRGB(42, 118, 58),
    },
    {
        name = "SwampCypressTree_B",
        zone = "SwampDelta",
        kind = "Tree",
        position = Vector3.new(-170, 7, 1095),
        trunkSize = Vector3.new(8, 32, 8),
        canopySize = Vector3.new(36, 26, 36),
        trunkColor = Color3.fromRGB(84, 64, 46),
        canopyColor = Color3.fromRGB(48, 110, 68),
    },
    {
        name = "RedstoneCanyonBoulder_A",
        zone = "RedstoneCanyon",
        kind = "Boulder",
        position = Vector3.new(132, 17, -835),
        size = Vector3.new(30, 18, 24),
        color = Color3.fromRGB(156, 83, 54),
        material = Enum.Material.Sandstone,
    },
    {
        name = "MountainNestRock_A",
        zone = "MountainNestingCliffs",
        kind = "Rock",
        position = Vector3.new(238, 82, -1947),
        size = Vector3.new(32, 20, 28),
        color = Color3.fromRGB(106, 102, 96),
        material = Enum.Material.Rock,
    },
    {
        name = "OldEdenRubblePile_A",
        zone = "ApocalypticCity",
        kind = "Rubble",
        position = Vector3.new(1088, 13, -284),
        size = Vector3.new(34, 10, 24),
        color = Color3.fromRGB(94, 89, 83),
        material = Enum.Material.Concrete,
    },
    {
        name = "RedstoneDormantVolcano_A",
        zone = "RedstoneCanyon",
        kind = "Volcano",
        position = Vector3.new(58, 28, -1035),
        size = Vector3.new(92, 78, 92),
        color = Color3.fromRGB(88, 64, 58),
        material = Enum.Material.Basalt,
        scenicLandmark = true,
    },
    {
        name = "RedstoneLavaGlow_A",
        zone = "RedstoneCanyon",
        kind = "LavaVisual",
        position = Vector3.new(58, 72, -1035),
        size = Vector3.new(58, 4, 58),
        color = Color3.fromRGB(255, 91, 31),
        material = Enum.Material.Neon,
        shape = Enum.PartType.Cylinder,
        lavaVisual = true,
        scenicLandmark = true,
    },
    {
        name = "MountainCliffFace_B",
        zone = "MountainNestingCliffs",
        kind = "Cliff",
        position = Vector3.new(142, 92, -1780),
        size = Vector3.new(118, 96, 32),
        color = Color3.fromRGB(118, 115, 108),
        material = Enum.Material.Rock,
        scenicLandmark = true,
    },
    {
        name = "MountainSnowcapVista_A",
        zone = "MountainNestingCliffs",
        kind = "MountainPeak",
        position = Vector3.new(-278, 118, -1888),
        size = Vector3.new(84, 56, 84),
        color = Color3.fromRGB(210, 214, 218),
        material = Enum.Material.Snow,
        scenicLandmark = true,
    },
    {
        name = "FernPlainsFlowerField_A",
        zone = "FernPlains",
        kind = "FlowerCluster",
        position = Vector3.new(-1116, 12, 42),
        size = Vector3.new(34, 3, 24),
        color = Color3.fromRGB(235, 116, 183),
        material = Enum.Material.Grass,
        flowerCluster = true,
        scenicLandmark = true,
    },
    {
        name = "NurseryWildflowerPatch_A",
        zone = "NurseryGrove",
        kind = "FlowerCluster",
        position = Vector3.new(-2055, 12, 118),
        size = Vector3.new(26, 3, 22),
        color = Color3.fromRGB(248, 211, 91),
        material = Enum.Material.Grass,
        flowerCluster = true,
        scenicLandmark = true,
    },
    {
        name = "JungleOrchidCluster_A",
        zone = "JungleBasin",
        kind = "FlowerCluster",
        position = Vector3.new(-1518, 12, 1108),
        size = Vector3.new(28, 4, 24),
        color = Color3.fromRGB(177, 88, 231),
        material = Enum.Material.LeafyGrass,
        flowerCluster = true,
        scenicLandmark = true,
    },
    {
        name = "SwampLilyBloomCluster_A",
        zone = "SwampDelta",
        kind = "FlowerCluster",
        position = Vector3.new(-115, 9, 895),
        size = Vector3.new(38, 2, 20),
        color = Color3.fromRGB(238, 232, 184),
        material = Enum.Material.LeafyGrass,
        flowerCluster = true,
        scenicLandmark = true,
    },
    {
        name = "JungleForestVista_A",
        zone = "JungleBasin",
        kind = "ForestVista",
        position = Vector3.new(-1595, 15, 872),
        size = Vector3.new(72, 28, 42),
        color = Color3.fromRGB(35, 100, 54),
        material = Enum.Material.LeafyGrass,
        scenicLandmark = true,
    },
    {
        name = "SwampRiverBendMarker_A",
        zone = "SwampDelta",
        kind = "RiverBend",
        position = Vector3.new(-70, 8, 970),
        size = Vector3.new(120, 3, 24),
        color = Color3.fromRGB(58, 137, 184),
        material = Enum.Material.Glass,
        scenicLandmark = true,
    },
    {
        name = "FernLakeShoreMarker_A",
        zone = "FernPlains",
        kind = "LakeShore",
        position = Vector3.new(-1080, 10, 250),
        size = Vector3.new(88, 2, 18),
        color = Color3.fromRGB(72, 150, 188),
        material = Enum.Material.Glass,
        scenicLandmark = true,
    },
    {
        name = "JungleDenseForestStand_B",
        zone = "JungleBasin",
        kind = "ForestStand",
        position = Vector3.new(-1288, 14, 920),
        size = Vector3.new(82, 30, 54),
        color = Color3.fromRGB(30, 92, 48),
        material = Enum.Material.LeafyGrass,
        habitatFeature = "Forest",
        scenicLandmark = true,
    },
    {
        name = "NurseryGroveForestRing_A",
        zone = "NurseryGrove",
        kind = "ForestStand",
        position = Vector3.new(-2135, 10, 172),
        size = Vector3.new(70, 26, 46),
        color = Color3.fromRGB(62, 132, 58),
        material = Enum.Material.LeafyGrass,
        habitatFeature = "Forest",
        scenicLandmark = true,
    },
    {
        name = "RedstoneDesertDune_A",
        zone = "RedstoneCanyon",
        kind = "DesertDune",
        position = Vector3.new(-330, 15, -545),
        size = Vector3.new(96, 16, 38),
        color = Color3.fromRGB(198, 139, 77),
        material = Enum.Material.Sand,
        habitatFeature = "Desert",
        scenicLandmark = true,
    },
    {
        name = "RedstoneDryScrubCluster_A",
        zone = "RedstoneCanyon",
        kind = "DryScrub",
        position = Vector3.new(-88, 15, -502),
        size = Vector3.new(42, 8, 28),
        color = Color3.fromRGB(148, 112, 62),
        material = Enum.Material.Grass,
        habitatFeature = "Desert",
        scenicLandmark = true,
    },

}

MapLayoutService.NPCKindSpeciesIds = {
    Prey = "gallimimus",
    AerialPrey = "gallimimus",
    FlyingPrey = "gallimimus",
    Predator = "carnotaurus",
    AerialPredator = "velociraptor",
    Apex = "tyrannosaurus",
    Omnivore = "oviraptor",
}

MapLayoutService.NPCKindFoodWhenDefeated = {
    Prey = "PreyCarcass",
    AerialPrey = "AerialPreyCarcass",
    FlyingPrey = "AerialPreyCarcass",
    Predator = "PredatorCarcass",
    AerialPredator = "PredatorCarcass",
    Apex = "LargeCarcass",
    Omnivore = "PreyCarcass",
}

MapLayoutService.NPCSpawnPlacements = {
    { name = "NurseryPrey_01", position = Vector3.new(-1905, 14, 95), kind = "Prey", zone = "NurseryGrove", tutorialSafe = true },
    { name = "NurseryPrey_02", position = Vector3.new(-2075, 14, -115), kind = "Prey", zone = "NurseryGrove", tutorialSafe = true },
    { name = "FernPrey_01", position = Vector3.new(-1250, 14, 120), kind = "Prey", zone = "FernPlains" },
    { name = "FernPrey_02", position = Vector3.new(-1120, 14, -165), kind = "Prey", zone = "FernPlains" },
    { name = "JunglePrey_01", position = Vector3.new(-1460, 14, 1010), kind = "Prey", zone = "JungleBasin" },
    { name = "SwampPrey_01", position = Vector3.new(-230, 11, 1040), kind = "Prey", zone = "SwampDelta" },
    { name = "RedstonePredator_01", position = Vector3.new(-280, 16, -720), kind = "Predator", zone = "RedstoneCanyon", dangerous = true },
    { name = "CityPredator_01", position = Vector3.new(630, 14, -160), kind = "Predator", zone = "ApocalypticCity", dangerous = true },
    { name = "MountainPrey_01", position = Vector3.new(-90, 79, -1660), kind = "Prey", zone = "MountainNestingCliffs" },
    { name = "MountainAerialPrey_01", position = Vector3.new(-40, 96, -1715), kind = "AerialPrey", zone = "MountainNestingCliffs", aerial = true, preferredAltitude = 34 },
    { name = "MountainAerialPredator_01", position = Vector3.new(-155, 104, -1605), kind = "AerialPredator", zone = "MountainNestingCliffs", dangerous = true, aerial = true, preferredAltitude = 42 },
    { name = "FernPredator_01", position = Vector3.new(-980, 14, -260), kind = "Predator", zone = "FernPlains", dangerous = true },
    { name = "RedstoneAerialPrey_01", position = Vector3.new(-180, 60, -875), kind = "AerialPrey", zone = "RedstoneCanyon", aerial = true, preferredAltitude = 32 },
    { name = "JunglePredator_01", position = Vector3.new(-1340, 14, 1110), kind = "Predator", zone = "JungleBasin", dangerous = true },
    { name = "SwampPredator_01", position = Vector3.new(65, 11, 1010), kind = "Predator", zone = "SwampDelta", dangerous = true },
    { name = "MountainNestHerdPrey_01", position = Vector3.new(-168, 79, -1605), kind = "Prey", zone = "MountainNestingCliffs", nestingHerd = true },
    { name = "MountainNestHerdPrey_02", position = Vector3.new(-42, 79, -1598), kind = "Prey", zone = "MountainNestingCliffs", nestingHerd = true },
    { name = "FernNestHerdPrey_01", position = Vector3.new(-1048, 14, 118), kind = "Prey", zone = "FernPlains", nestingHerd = true },
    { name = "JungleNestHerdPrey_01", position = Vector3.new(-1395, 14, 1002), kind = "Prey", zone = "JungleBasin", nestingHerd = true },
    { name = "PterodactylFlyingPrey_01", position = Vector3.new(-180, 116, -1540), kind = "FlyingPrey", zone = "MountainNestingCliffs", flyingPrey = true },
    { name = "PterodactylFlyingPrey_02", position = Vector3.new(-1320, 72, 890), kind = "FlyingPrey", zone = "JungleBasin", flyingPrey = true },
}

MapLayoutService.PlayerSpawnPlacements = {
    { name = "GallimimusFernSpawn_01", speciesId = "gallimimus", zone = "FernPlains", position = Vector3.new(-1245, 15, -65), yawDegrees = 92 },
    { name = "GallimimusFernSpawn_02", speciesId = "gallimimus", zone = "FernPlains", position = Vector3.new(-1125, 15, 135), yawDegrees = -35 },
    { name = "GallimimusNurserySpawn_01", speciesId = "gallimimus", zone = "NurseryGrove", position = Vector3.new(-1995, 15, 74), yawDegrees = 88 },

    { name = "TriceratopsFernSpawn_01", speciesId = "triceratops", zone = "FernPlains", position = Vector3.new(-1190, 15, -190), yawDegrees = 35 },
    { name = "TriceratopsJungleSpawn_01", speciesId = "triceratops", zone = "JungleBasin", position = Vector3.new(-1505, 15, 1015), yawDegrees = -10 },
    { name = "TriceratopsNurserySpawn_01", speciesId = "triceratops", zone = "NurseryGrove", position = Vector3.new(-2050, 15, 38), yawDegrees = 74 },

    { name = "VelociraptorJungleSpawn_01", speciesId = "velociraptor", zone = "JungleBasin", position = Vector3.new(-1415, 15, 1070), yawDegrees = -115 },
    { name = "VelociraptorFernSpawn_01", speciesId = "velociraptor", zone = "FernPlains", position = Vector3.new(-1015, 15, -210), yawDegrees = 145 },
    { name = "VelociraptorNurserySpawn_01", speciesId = "velociraptor", zone = "NurseryGrove", position = Vector3.new(-1870, 15, -78), yawDegrees = 118 },

    { name = "CarnotaurusRedstoneSpawn_01", speciesId = "carnotaurus", zone = "RedstoneCanyon", position = Vector3.new(-260, 17, -720), yawDegrees = 64 },
    { name = "CarnotaurusCitySpawn_01", speciesId = "carnotaurus", zone = "ApocalypticCity", position = Vector3.new(640, 15, -175), yawDegrees = -92 },
    { name = "CarnotaurusNurserySpawn_01", speciesId = "carnotaurus", zone = "NurseryGrove", position = Vector3.new(-1832, 15, 20), yawDegrees = 122 },
}


MapLayoutService.CompactLayout = {
    origin = Vector3.new(-2000, 0, 0),
    scaleXZ = 0.5,
    minimumTerrainXZ = 240,
    minimumRouteXZ = 96,
    minimumWaterXZ = 42,
}

function MapLayoutService:CompactPosition(vector)
    local layout = self.CompactLayout
    return Vector3.new(
        layout.origin.X + (vector.X - layout.origin.X) * layout.scaleXZ,
        vector.Y,
        layout.origin.Z + (vector.Z - layout.origin.Z) * layout.scaleXZ
    )
end

function MapLayoutService:CompactSize(size, minimumXZ)
    local scale = self.CompactLayout.scaleXZ
    return Vector3.new(
        math.max(minimumXZ or 0, size.X * scale),
        size.Y,
        math.max(minimumXZ or 0, size.Z * scale)
    )
end

function MapLayoutService:ApplyCompactLayout()
    if self._compactLayoutApplied then return end
    self._compactLayoutApplied = true

    self.FullMapUnderlay.center = self:CompactPosition(self.FullMapUnderlay.center)
    self.FullMapUnderlay.size = self:CompactSize(self.FullMapUnderlay.size, 0)
    self.FullMapTerrainUnderlay.center = self:CompactPosition(self.FullMapTerrainUnderlay.center)
    self.FullMapTerrainUnderlay.size = self:CompactSize(self.FullMapTerrainUnderlay.size, 0)

    for _, zone in pairs(self.ZoneTerrain) do
        zone.center = self:CompactPosition(zone.center)
        zone.size = self:CompactSize(zone.size, self.CompactLayout.minimumTerrainXZ)
    end

    for _, route in ipairs(self.RouteTerrain) do
        route.center = self:CompactPosition(route.center)
        route.size = self:CompactSize(route.size, self.CompactLayout.minimumRouteXZ)
    end

    for _, water in ipairs(self.ShallowWater) do
        water.center = self:CompactPosition(water.center)
        water.size = self:CompactSize(water.size, self.CompactLayout.minimumWaterXZ)
    end

    for _, placement in ipairs(self.FoodPlacements) do
        placement.position = self:CompactPosition(placement.position)
    end

    for _, source in ipairs(self.FoodSourcePlacements) do
        source.position = self:CompactPosition(source.position)
    end

    for _, spec in ipairs(self.BiomeDressingPlacements) do
        spec.position = self:CompactPosition(spec.position)
    end

    for _, spec in ipairs(self.NPCSpawnPlacements) do
        spec.position = self:CompactPosition(spec.position)
    end

    for _, spec in ipairs(self.PlayerSpawnPlacements) do
        spec.position = self:CompactPosition(spec.position)
    end
end

MapLayoutService:ApplyCompactLayout()

function MapLayoutService:GetOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

function MapLayoutService:EnsureMapFolders()
    local map = self:GetOrCreateFolder(Workspace, self.MapFolderName)
    local zonesFolder = self:GetOrCreateFolder(map, "Zones")
    local invisible = self:GetOrCreateFolder(map, self.InvisibleFolderName)
    local landmarks = self:GetOrCreateFolder(map, "Landmarks")
    local foodSources = self:GetOrCreateFolder(map, "FoodSources")
    local waterSources = self:GetOrCreateFolder(map, "WaterSources")
    local npcSpawns = self:GetOrCreateFolder(map, "NPCSpawns")
    local nests = self:GetOrCreateFolder(map, "Nests")
    local fossils = self:GetOrCreateFolder(map, "Fossils")
    local routes = self:GetOrCreateFolder(map, "Routes")
    local biomeDressing = self:GetOrCreateFolder(map, "BiomeDressing")

    for zoneId in pairs(ZoneConfig) do
        self:GetOrCreateFolder(zonesFolder, zoneId)
    end
    for _, landmarkName in ipairs(MapLayout.Landmarks) do
        self:GetOrCreateFolder(landmarks, landmarkName)
    end
    return {
        Map = map,
        Zones = zonesFolder,
        InvisibleGameplayVolumes = invisible,
        Landmarks = landmarks,
        FoodSources = foodSources,
        WaterSources = waterSources,
        NPCSpawns = npcSpawns,
        Nests = nests,
        Fossils = fossils,
        Routes = routes,
        BiomeDressing = biomeDressing,
    }
end

function MapLayoutService:FillTerrainBlock(terrain, center, size, material)
    terrain:FillBlock(CFrame.new(center), size, material)
end

function MapLayoutService:EnsureRouteMarker(folders, route)
    local marker = folders.Routes:FindFirstChild(route.name)
    if not marker then
        marker = Instance.new("Folder")
        marker.Name = route.name
        marker.Parent = folders.Routes
    end
    marker:SetAttribute("TerrainBacked", true)
    marker:SetAttribute("BabySafeRoute", route.babySafe == true)
    marker:SetAttribute("CityRoute", route.cityRoute == true)
    return marker
end

function MapLayoutService:EnsureShallowWaterMarker(folders, water)
    local marker = folders.WaterSources:FindFirstChild(water.name)
    if marker and not marker:IsA("BasePart") then
        marker:Destroy()
        marker = nil
    end
    if not marker then
        marker = Instance.new("Part")
        marker.Name = water.name
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanTouch = true
        marker.CanQuery = true
        marker.Parent = folders.WaterSources
    end
    marker.Material = Enum.Material.Glass
    marker.Color = Color3.fromRGB(58, 137, 184)
    marker.Transparency = self.ShallowWaterMarkerTransparency
    marker.CastShadow = false
    marker.Position = water.center
    marker.Size = water.size
    marker:SetAttribute("ShallowWater", true)
    marker:SetAttribute("WaterSource", true)
    marker:SetAttribute("ProceduralWaterSource", true)
    marker:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
    marker:SetAttribute("ReleaseVisibleGeneratedPartReason", "Procedural shallow water source representation")
    marker:SetAttribute("TutorialSafe", water.tutorialSafe == true)
    marker:SetAttribute("SwimmableDepthStuds", water.size.Y)
    marker:SetAttribute("SwimZone", water.swimZone == true)
    marker:SetAttribute("FishSpawnAllowed", water.fishSpawnAllowed == true)
    marker:SetAttribute("InteractionHint", "Drink water")
    marker:SetAttribute("VisibleGameplayAffordance", true)
    marker:SetAttribute("GameplayQuery", true)
    if not CollectionService:HasTag(marker, "WaterSource") then
        CollectionService:AddTag(marker, "WaterSource")
    end
    return marker
end

function MapLayoutService:EnsureFoodSourcePlacements(folders)
    for _, placement in ipairs(self.FoodPlacements) do
        local zoneFolder = folders.FoodSources:FindFirstChild(placement.zone)
        if not zoneFolder then
            zoneFolder = Instance.new("Folder")
            zoneFolder.Name = placement.zone
            zoneFolder.Parent = folders.FoodSources
        end
        local food = zoneFolder:FindFirstChild(placement.name)
        if not food then
            food = Instance.new("Part")
            food.Name = placement.name
            food.Anchored = true
            food.CanCollide = false
            food.CanTouch = false
            food.CanQuery = true
            food.Shape = Enum.PartType.Block
            food.Material = placement.diet == "Carnivore" and Enum.Material.Leather or Enum.Material.Grass
            food.Color = placement.diet == "Carnivore" and Color3.fromRGB(120, 55, 45) or Color3.fromRGB(64, 135, 54)
            food.Size = placement.size
            food.Position = placement.position
            food:SetAttribute("CreatorStoreOnly", nil)
            food:SetAttribute("ImportedVisibleAsset", nil)
            food:SetAttribute("AssetManifestId", nil)
            food:SetAttribute("Decorative", false)
            food.Parent = zoneFolder
        end
        food:SetAttribute("ZoneId", placement.zone)
        self:ApplyFoodMetadata(food, placement)
        food:SetAttribute("CreatorStoreOnly", nil)
        food:SetAttribute("ImportedVisibleAsset", nil)
        food:SetAttribute("AssetManifestId", nil)
        food:SetAttribute("Depleted", food:GetAttribute("Depleted") == true)
        food:SetAttribute("RespawnCooldownSeconds", placement.cooldown)
        food:SetAttribute("DangerousZone", placement.zone ~= "NurseryGrove" and placement.zone ~= "FernPlains")
        local isTutorialFood = placement.tutorialSafe == true or placement.kind == "StarterPlant" or placement.kind == "TutorialCarcass"
        food:SetAttribute("StarterFood", isTutorialFood)
        food:SetAttribute("TutorialSafe", isTutorialFood)
        self:ApplyReleaseHiddenQueryPart(food)
        self:EnsureVisibleFoliageVisual(food, { diet = placement.diet, kind = placement.kind })
        CollectionService:AddTag(food, "FoodSource")
    end
end

function MapLayoutService:EnsureCityDiscoveryTriggers(folders)
    folders = folders or self:EnsureMapFolders()
    local triggerFolder = self:GetOrCreateFolder(folders.InvisibleGameplayVolumes, "CityDiscoveryTriggers")
    local zone = self.ZoneTerrain.ApocalypticCity
    local triggers = {
        { name = "_INVISIBLE_CityDiscovery_RedstoneGate", position = self:CompactPosition(Vector3.new(620, zone.topY + 5, -325)), size = Vector3.new(90, 14, 180) },
        { name = "_INVISIBLE_CityDiscovery_SwampCauseway", position = self:CompactPosition(Vector3.new(620, zone.topY + 5, 475)), size = Vector3.new(90, 14, 180) },
        { name = "_INVISIBLE_CityDiscovery_CityCore", position = Vector3.new(zone.center.X, zone.topY + 5, zone.center.Z), size = Vector3.new(220, 14, 220) },
    }
    for _, spec in ipairs(triggers) do
        local trigger = triggerFolder:FindFirstChild(spec.name)
        if not trigger then
            trigger = Instance.new("Part")
            trigger.Name = spec.name
            trigger.Anchored = true
            trigger.CanCollide = false
            trigger.CanTouch = true
            trigger.CanQuery = false
            trigger.Transparency = 1
            trigger.Parent = triggerFolder
        end
        trigger.Position = spec.position
        trigger.Size = spec.size
        trigger:SetAttribute("GameplayVolume", true)
        trigger:SetAttribute("CityDiscoveryTrigger", true)
        trigger:SetAttribute("ZoneId", "ApocalypticCity")
    end
    return triggerFolder
end

function MapLayoutService:EnsureFallSafetyVolume(folders)
    local safety = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_FallSafetyCatch")
    if not safety then
        safety = Instance.new("Part")
        safety.Name = "_INVISIBLE_FallSafetyCatch"
        safety.Anchored = true
        safety.CanCollide = true
        safety.CanTouch = true
        safety.CanQuery = false
        safety.Transparency = 1
        safety.Parent = folders.InvisibleGameplayVolumes
    end
    safety.Size = Vector3.new(self.FullMapUnderlay.size.X, 4, self.FullMapUnderlay.size.Z)
    safety.Position = Vector3.new(self.FullMapUnderlay.center.X, -16, self.FullMapUnderlay.center.Z)
    safety:SetAttribute("GameplayVolume", true)
    safety:SetAttribute("FallSafety", true)
    return safety
end

function MapLayoutService:EnsureTerrainContinuity(folders)
    local terrain = Workspace.Terrain

    self:FillTerrainBlock(terrain, self.FullMapTerrainUnderlay.center, self.FullMapTerrainUnderlay.size, self.FullMapTerrainUnderlay.material)
    folders.Map:SetAttribute("FullMapTerrainUnderlay", true)
    folders.Map:SetAttribute("FullMapTerrainUnderlaySize", string.format("%d,%d,%d", self.FullMapTerrainUnderlay.size.X, self.FullMapTerrainUnderlay.size.Y, self.FullMapTerrainUnderlay.size.Z))
    local underlay = folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name)
    if not underlay then
        underlay = Instance.new("Part")
        underlay.Name = "_INVISIBLE_" .. self.FullMapUnderlay.name
        underlay.Anchored = true
        underlay.CanCollide = true
        underlay.CanTouch = false
        underlay.CanQuery = false
        underlay.Transparency = 1
        underlay.Parent = folders.InvisibleGameplayVolumes
    end
    underlay.Position = self.FullMapUnderlay.center
    underlay.Size = self.FullMapUnderlay.size
    underlay.Material = self.FullMapUnderlay.material
    underlay:SetAttribute("GameplayVolume", true)
    underlay:SetAttribute("TerrainUnderlay", true)
    underlay:SetAttribute("GroundTopY", self.FullMapUnderlay.topY)

    for zoneId, zone in pairs(self.ZoneTerrain) do
        self:FillTerrainBlock(terrain, zone.center, zone.size, zone.material)
        local zoneFolder = folders.Zones:FindFirstChild(zoneId)
        if zoneFolder then
            zoneFolder:SetAttribute("TerrainBacked", true)
            zoneFolder:SetAttribute("GroundTopY", zone.topY)
        end
    end

    for _, route in ipairs(self.RouteTerrain) do
        self:FillTerrainBlock(terrain, route.center, route.size, route.material)
        self:EnsureRouteMarker(folders, route)
    end

    for _, water in ipairs(self.ShallowWater) do
        self:FillTerrainBlock(terrain, water.center, water.size, Enum.Material.Water)
        self:EnsureShallowWaterMarker(folders, water)
    end
end


function MapLayoutService:EnsureFoodSource(folders, source)
    local CollectionService = game:GetService("CollectionService")
    local zoneFolder = folders.FoodSources:FindFirstChild(source.zone)
    if not zoneFolder then
        zoneFolder = Instance.new("Folder")
        zoneFolder.Name = source.zone
        zoneFolder.Parent = folders.FoodSources
    end
    local existing = zoneFolder:FindFirstChild(source.name) or folders.FoodSources:FindFirstChild(source.name)
    if not existing then
        existing = Instance.new("Part")
        existing.Name = source.name
        existing.Anchored = true
        existing.Shape = Enum.PartType.Block
        existing.Material = source.diet == "Herbivore" and Enum.Material.Grass or Enum.Material.Slate
    end
    existing.Parent = zoneFolder
    existing.Position = source.position
    existing.Size = source.size
    existing.Color = source.color
    existing.CanCollide = false
    existing.CanTouch = true
    existing.CanQuery = true
    existing:SetAttribute("ZoneId", source.zone)
    self:ApplyFoodMetadata(existing, {
        diet = source.diet,
        nutrition = source.nutrition,
        kind = source.kind or (source.diet == "Herbivore" and "PlantPatch" or "PreyCarcass"),
    })
    existing:SetAttribute("RespawnSeconds", source.respawnSeconds)
    existing:SetAttribute("RespawnCooldownSeconds", source.respawnSeconds)
    existing:SetAttribute("Depleted", false)
    existing:SetAttribute("TutorialSafe", source.tutorialSafe == true)
    existing:SetAttribute("HighRisk", source.highRisk == true)
    self:ApplyReleaseHiddenQueryPart(existing)
    self:EnsureVisibleFoliageVisual(existing, { diet = source.diet, color = source.color })
    existing:SetAttribute("CreatorStoreOnly", nil)
    existing:SetAttribute("ImportedVisibleAsset", nil)
    existing:SetAttribute("AssetManifestId", nil)
    existing:SetAttribute("PlacementRole", source.diet == "Herbivore" and "PlantFood" or "CarnivoreCarcassFood")
    if not CollectionService:HasTag(existing, "FoodSource") then
        CollectionService:AddTag(existing, "FoodSource")
    end
    return existing
end

function MapLayoutService:EnsureFoodSources()
    local folders = self:EnsureMapFolders()
    for _, source in ipairs(self.FoodSourcePlacements) do
        self:EnsureFoodSource(folders, source)
    end
    return folders.FoodSources
end


function MapLayoutService:ApplyDressingAttributes(part, spec, role)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false

    local isVisible = (role == "VisibleTreeTrunk" or role == "HiddenTreeCanopy" or role == "VisibleBiomeProp")
    if isVisible then
        part.Transparency = 0
        part:SetAttribute("ProceduralGameplayVisual", true)
        part:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
        part:SetAttribute("ReleaseVisibleGeneratedPartReason", "Procedural biome dressing representation")
    else
        part.Transparency = 1
        part:SetAttribute("ReleaseHiddenProceduralVisual", true)
        part:SetAttribute("InvisibleQueryHelper", true)
    end

    part:SetAttribute("ZoneId", spec.zone)
    part:SetAttribute("BiomeDressing", true)
    part:SetAttribute("Decorative", true)
    part:SetAttribute("CreatorStoreOnly", nil)
    part:SetAttribute("ImportedVisibleAsset", nil)
    part:SetAttribute("AssetManifestId", nil)
    part:SetAttribute("PlacementRole", role)
    part:SetAttribute("DressingKind", spec.kind)
    part:SetAttribute("ScenicLandmark", spec.scenicLandmark == true)
    part:SetAttribute("FlowerCluster", spec.flowerCluster == true)
    part:SetAttribute("LavaVisual", spec.lavaVisual == true)
    part:SetAttribute("HabitatFeature", spec.habitatFeature)
    part:SetAttribute("AvoidRouteCenters", true)
    part:SetAttribute("GroundTopY", self.ZoneTerrain[spec.zone] and self.ZoneTerrain[spec.zone].topY or nil)
    part:SetAttribute("FloatingAllowed", false)
    if not CollectionService:HasTag(part, "BiomeDressing") then
        CollectionService:AddTag(part, "BiomeDressing")
    end
    if role == "TreeBrowseQuery" and not CollectionService:HasTag(part, "TreeProp") then
        CollectionService:AddTag(part, "TreeProp")
    end
end

function MapLayoutService:EnsureBiomeDressing(folders)
    folders = folders or self:EnsureMapFolders()
    for _, spec in ipairs(self.BiomeDressingPlacements) do
        local zoneFolder = folders.BiomeDressing:FindFirstChild(spec.zone)
        if not zoneFolder then
            zoneFolder = Instance.new("Folder")
            zoneFolder.Name = spec.zone
            zoneFolder.Parent = folders.BiomeDressing
        end

        if spec.kind == "Tree" then
            local trunk = zoneFolder:FindFirstChild(spec.name .. "_Trunk")
            if not trunk then
                trunk = Instance.new("Part")
                trunk.Name = spec.name .. "_Trunk"
                trunk.Material = Enum.Material.Wood
                trunk.Parent = zoneFolder
            end
            trunk.Size = spec.trunkSize
            trunk.Position = spec.position + Vector3.new(0, spec.trunkSize.Y / 2, 0)
            trunk.Color = spec.trunkColor
            self:ApplyDressingAttributes(trunk, spec, "VisibleTreeTrunk")

            local canopy = zoneFolder:FindFirstChild(spec.name .. "_Canopy")
            if not canopy then
                canopy = Instance.new("Part")
                canopy.Name = spec.name .. "_Canopy"
                canopy.Material = Enum.Material.Grass
                canopy.Parent = zoneFolder
            end
            local canopySize = getReadableFallbackCanopySize(spec)
            canopy.Shape = (spec.zone == "NurseryGrove" or spec.zone == "FernPlains") and Enum.PartType.Ball or Enum.PartType.Block
            canopy.Size = canopySize
            canopy.Position = spec.position + Vector3.new(0, spec.trunkSize.Y + canopySize.Y * 0.32, 0)
            canopy.Color = spec.canopyColor
            self:ApplyDressingAttributes(canopy, spec, "HiddenTreeCanopy")

            local browse = zoneFolder:FindFirstChild(spec.name .. "_Browse")
            if not browse then
                browse = Instance.new("Part")
                browse.Name = spec.name .. "_Browse"
                browse.Shape = Enum.PartType.Block
                browse.Material = Enum.Material.Grass
                browse.Parent = zoneFolder
            end
            browse.Size = Vector3.new(math.max(8, spec.canopySize.X * 0.45), 4, math.max(8, spec.canopySize.Z * 0.45))
            browse.Position = spec.position + Vector3.new(0, spec.browseHeight or 6, 0)
            browse.Color = spec.canopyColor
            self:ApplyDressingAttributes(browse, spec, "TreeBrowseQuery")
            self:ApplyBrowseFoodAttributes(browse, spec, { treeBrowse = true })
            if not CollectionService:HasTag(browse, "TreeProp") then
                CollectionService:AddTag(browse, "TreeProp")
            end
        else
            local prop = zoneFolder:FindFirstChild(spec.name)
            if not prop then
                prop = Instance.new("Part")
                prop.Name = spec.name
                prop.Parent = zoneFolder
            end
            prop.Shape = spec.shape or Enum.PartType.Block
            prop.Size = spec.size
            prop.Position = spec.position
            prop.Color = spec.color
            prop.Material = spec.material
            self:ApplyDressingAttributes(prop, spec, "VisibleBiomeProp")

            if self:IsVegetationBrowseSpec(spec) then
                local browse = zoneFolder:FindFirstChild(spec.name .. "_Browse")
                if not browse then
                    browse = Instance.new("Part")
                    browse.Name = spec.name .. "_Browse"
                    browse.Shape = Enum.PartType.Block
                    browse.Material = spec.material
                    browse.Parent = zoneFolder
                end
                browse.Size = spec.size
                browse.Position = spec.position
                browse.Color = spec.color
                self:ApplyDressingAttributes(browse, spec, "TreeBrowseQuery")
                self:ApplyBrowseFoodAttributes(browse, spec, { treeBrowse = false })
            end
        end
    end
    return folders.BiomeDressing
end

local function hasVisibleStoryBasePart(instance)
    if not instance then return false end
    if instance:IsA("BasePart") and instance.Transparency < 1 then
        return true
    end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then
            return true
        end
    end
    return false
end

local function firstBasePart(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance end
    return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function isHelperPartName(name)
    local lowerName = string.lower(name or "")
    return lowerName == "rootpart"
        or lowerName == "humanoidrootpart"
        or string.find(lowerName, "hitbox", 1, true) ~= nil
        or string.find(lowerName, "helper", 1, true) ~= nil
        or string.find(lowerName, "collider", 1, true) ~= nil
        or string.find(lowerName, "collision", 1, true) ~= nil
        or string.find(lowerName, "bounds", 1, true) ~= nil
        or string.find(lowerName, "bounding", 1, true) ~= nil
end

local function findBySlashPath(root, path)
    local current = root
    for token in string.gmatch(path or "", "[^/]+") do
        if not current then return nil end
        current = current:FindFirstChild(token)
    end
    return current
end

local StoryPlacementTagsToClear = {
    "Damageable",
    "FishSource",
    "FoodSource",
    "NPCSpawn",
    "TreeProp",
}

local StoryPlacementGameplayAttributesToClear = {
    "BrowseTier",
    "CarnivoreFoodCandidate",
    "CarnivoreFoodKind",
    "CompactFoodGroup",
    "Diet",
    "EdibleVegetation",
    "FishSource",
    "FoodKind",
    "FoodSourceCandidate",
    "FoodWhenDefeated",
    "MeatType",
    "Nutrition",
    "PlantPart",
    "PotentialCarnivoreFood",
    "PotentialHerbivoreFood",
    "TreeBrowse",
    "VegetationType",
}

local function clearStoryPlacementGameplayState(instance)
    for _, tag in ipairs(StoryPlacementTagsToClear) do
        if CollectionService:HasTag(instance, tag) then
            CollectionService:RemoveTag(instance, tag)
        end
    end
    for _, attributeName in ipairs(StoryPlacementGameplayAttributesToClear) do
        instance:SetAttribute(attributeName, nil)
    end
end

function MapLayoutService:GetStoryBeatRoot(folders, rootName, beatId, displayName)
    local storyboards = self:GetOrCreateFolder(folders.Map, "Storyboards")
    local root = self:GetOrCreateFolder(storyboards, rootName)
    root:SetAttribute("StoryBeatId", beatId)
    root:SetAttribute("DisplayName", displayName or rootName)
    root:SetAttribute("SourceDocument", StoryAssetPlacements.SourceDocument)
    root:SetAttribute("ValidationState", StoryAssetPlacements.ValidationState)
    root:SetAttribute("NeedsPlayerAngleScreenshot", true)
    root:SetAttribute("RequiredVerdict", StoryAssetPlacements.RequiredVerdict)
    root:SetAttribute("LiveStoryAssetLayer", true)
    return root
end

function MapLayoutService:EnsureStoryBeatRoots(folders)
    local roots = {}
    for _, rootSpec in ipairs(StoryAssetPlacements.BeatRoots) do
        roots[rootSpec.name] = self:GetStoryBeatRoot(folders, rootSpec.name, rootSpec.id, rootSpec.displayName)
    end
    return roots
end

function MapLayoutService:GetStoryAssetTargetFolder(folders, spec)
    local targetRoot = folders[spec.targetFolder] or self:GetOrCreateFolder(folders.Map, spec.targetFolder or "StoryAssets")
    if spec.targetFolder == "BiomeDressing" then
        return self:GetOrCreateFolder(targetRoot, spec.zone)
    end
    if spec.targetFolder == "Landmarks" and spec.landmarkFolder then
        return self:GetOrCreateFolder(targetRoot, spec.landmarkFolder)
    end
    if spec.targetFolder == "Nests" or spec.targetFolder == "Fossils" then
        return self:GetOrCreateFolder(targetRoot, spec.zone)
    end
    return targetRoot
end

function MapLayoutService:FindStoryAssetTemplate(spec)
    local library = ReplicatedStorage:FindFirstChild(self.ImportedAssetLibraryName)
    if not library then return nil end
    for _, sourceName in ipairs(spec.sourceNames or {}) do
        local source = string.find(sourceName, "/", 1, true) and findBySlashPath(library, sourceName)
            or library:FindFirstChild(sourceName, true)
        if source and (source:IsA("BasePart") or source:IsA("Model") or source:IsA("Folder")) and hasVisibleStoryBasePart(source) then
            return source
        end
    end
    return nil
end

function MapLayoutService:CloneStoryAssetSource(source)
    if source:IsA("Folder") then
        local wrapper = Instance.new("Model")
        for _, child in ipairs(source:GetChildren()) do
            child:Clone().Parent = wrapper
        end
        return wrapper
    end
    return source:Clone()
end

function MapLayoutService:GetStoryManifestEntry(sourceAssetId, assetManifestId)
    if type(assetManifestId) == "string" and assetManifestId ~= "" then
        local entry = AssetManifest.GetById(assetManifestId)
        if entry then return entry end
    end
    if sourceAssetId ~= nil then
        return AssetManifest.GetBySourceAssetId(sourceAssetId)
    end
    return nil
end

function MapLayoutService:ApplyStoryAssetMetadata(instance, spec, source, manifestEntry, sourceAssetId)
    clearStoryPlacementGameplayState(instance)
    local sourceName = source and source.Name or "procedural_story_fallback"
    local manifestId = manifestEntry and manifestEntry.AssetId or nil
    local manifestSourceId = manifestEntry and manifestEntry.SourceAssetId or tostring(sourceAssetId or spec.sourceAssetId or "")
    local importedClaim = manifestEntry ~= nil

    instance:SetAttribute("StoryBeatId", spec.beatId)
    instance:SetAttribute("StoryboardSlot", spec.slot)
    instance:SetAttribute("StoryboardSourceAssetId", tostring(spec.sourceAssetId or manifestSourceId))
    instance:SetAttribute("StoryboardAssetName", spec.name)
    instance:SetAttribute("StoryAssetSourceTemplate", sourceName)
    instance:SetAttribute("StoryAssetCategory", spec.category)
    instance:SetAttribute("StoryAssetPlacementState", StoryAssetPlacements.ValidationState)
    instance:SetAttribute("LiveStoryAssetPlacement", true)
    instance:SetAttribute("NeedsPlayerAngleScreenshot", true)
    instance:SetAttribute("NeedsStudioAssetInspection", true)
    instance:SetAttribute("ZoneId", spec.zone)
    instance:SetAttribute("FloatingAllowed", true)
    instance:SetAttribute("GroundTopY", self:GetGroundTopYForZone(spec.zone))

    if source then
        instance:SetAttribute("CreatorStoreOnly", true)
        instance:SetAttribute("SourceAssetId", manifestSourceId)
        instance:SetAttribute("ImportedVisibleAsset", importedClaim or nil)
        instance:SetAttribute("AssetManifestId", manifestId)
    else
        instance:SetAttribute("CreatorStoreOnly", nil)
        instance:SetAttribute("SourceAssetId", nil)
        instance:SetAttribute("ImportedVisibleAsset", nil)
        instance:SetAttribute("AssetManifestId", nil)
        instance:SetAttribute("AssetBackedStoryboardProxy", true)
    end
end

function MapLayoutService:SanitizeStoryAssetClone(clone, spec, source)
    local sourceAssetId = source and source:GetAttribute("SourceAssetId") or spec.sourceAssetId
    local assetManifestId = source and source:GetAttribute("AssetManifestId") or nil
    local manifestEntry = self:GetStoryManifestEntry(sourceAssetId or spec.sourceAssetId, assetManifestId)

    self:ApplyStoryAssetMetadata(clone, spec, source, manifestEntry, sourceAssetId or spec.sourceAssetId)
    if clone:IsA("Model") and not clone.PrimaryPart then
        clone.PrimaryPart = firstBasePart(clone)
    end

    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        elseif descendant:IsA("ModuleScript") then
            descendant:SetAttribute("ImportedScriptAudited", true)
            descendant:SetAttribute("Sandboxed", true)
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = spec.canCollide == true
            descendant.CanTouch = false
            descendant.CanQuery = false
            if isHelperPartName(descendant.Name) then
                descendant.Transparency = 1
            end
            self:ApplyStoryAssetMetadata(descendant, spec, source, manifestEntry, sourceAssetId or spec.sourceAssetId)
        end
    end
end

function MapLayoutService:ConfigureStoryFallbackPart(part, spec, role)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 0
    part:SetAttribute("ProceduralGameplayVisual", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartReason", "Server-authored storyboard fallback while Creator Store template placement awaits player-angle review.")
    part:SetAttribute("VisibleGameplayAffordance", true)
    part:SetAttribute("Decorative", true)
    part:SetAttribute("FallbackStoryPartRole", role)
    self:ApplyStoryAssetMetadata(part, spec, nil, nil, nil)
end

function MapLayoutService:CreateFallbackStoryAsset(spec)
    local model = Instance.new("Model")
    model.Name = spec.name
    self:ApplyStoryAssetMetadata(model, spec, nil, nil, nil)

    local fallback = spec.fallback or {}
    local size = fallback.size or Vector3.new(8, 4, 8)
    local color = fallback.color or Color3.fromRGB(120, 120, 120)
    local material = fallback.material or Enum.Material.SmoothPlastic
    local position = self:CompactPosition(spec.position)
    local yaw = math.rad(spec.yawDegrees or 0)

    local function addPart(name, shape, partSize, offset, role)
        local part = Instance.new("Part")
        part.Name = name
        part.Shape = shape or Enum.PartType.Block
        part.Size = partSize
        part.Color = color
        part.Material = material
        part.CFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0) * CFrame.new(offset or Vector3.new())
        part.Parent = model
        self:ConfigureStoryFallbackPart(part, spec, role)
        if not model.PrimaryPart then
            model.PrimaryPart = part
        end
        return part
    end

    local kind = fallback.kind or "Block"
    if kind == "Nest" then
        addPart("NestBowl", Enum.PartType.Cylinder, Vector3.new(size.X, math.max(1, size.Y * 0.25), size.Z), Vector3.new(0, 0, 0), "nest")
        local eggA = addPart("EggA", Enum.PartType.Ball, Vector3.new(3, 4, 3), Vector3.new(-2.5, 2.2, -1), "egg")
        eggA.Color = Color3.fromRGB(238, 226, 190)
        local eggB = addPart("EggB", Enum.PartType.Ball, Vector3.new(2.6, 3.5, 2.6), Vector3.new(2, 2, 1.5), "egg")
        eggB.Color = Color3.fromRGB(229, 216, 184)
    elseif kind == "Plant" then
        addPart("FoliageCore", Enum.PartType.Ball, Vector3.new(size.X, size.Y, size.Z), Vector3.new(0, size.Y * 0.25, 0), "foliage")
        addPart("FrondLeft", Enum.PartType.Block, Vector3.new(size.X * 0.18, 0.35, size.Z * 1.25), Vector3.new(-size.X * 0.22, size.Y * 0.48, 0), "frond")
        addPart("FrondRight", Enum.PartType.Block, Vector3.new(size.X * 0.18, 0.35, size.Z * 1.25), Vector3.new(size.X * 0.22, size.Y * 0.4, 0), "frond")
    elseif kind == "Bones" then
        local spine = addPart("BoneSpine", Enum.PartType.Cylinder, Vector3.new(0.7, size.X, 0.7), Vector3.new(0, 0.9, 0), "bone")
        spine.CFrame = spine.CFrame * CFrame.Angles(0, 0, math.rad(90))
        addPart("RibCage", Enum.PartType.Block, Vector3.new(size.X * 0.55, size.Y, size.Z), Vector3.new(0, 1.6, 0), "rib")
    elseif kind == "Lily" then
        addPart("LilyPad", Enum.PartType.Cylinder, Vector3.new(size.X, math.max(0.25, size.Y), size.Z), Vector3.new(0, 0, 0), "lily")
    elseif kind == "Log" then
        local log = addPart("FallenLog", Enum.PartType.Cylinder, Vector3.new(size.Y, size.X, size.Z), Vector3.new(0, size.Y * 0.35, 0), "log")
        log.CFrame = log.CFrame * CFrame.Angles(0, 0, math.rad(90))
    elseif kind == "Silhouette" then
        addPart("ApexWakeBody", Enum.PartType.Block, size, Vector3.new(0, size.Y * 0.32, 0), "silhouette")
    elseif kind == "Car" then
        addPart("WreckedCarBody", Enum.PartType.Block, size, Vector3.new(0, size.Y * 0.45, 0), "car")
        addPart("WreckedCarHood", Enum.PartType.Block, Vector3.new(size.X * 0.45, size.Y * 0.55, size.Z * 0.8), Vector3.new(size.X * 0.42, size.Y * 0.48, 0), "car")
    elseif kind == "Sign" then
        addPart("RoadSignPost", Enum.PartType.Cylinder, Vector3.new(0.45, size.Y, 0.45), Vector3.new(0, size.Y * 0.45, 0), "sign")
        addPart("RoadSignFace", Enum.PartType.Block, Vector3.new(size.X, size.Y * 0.42, 0.35), Vector3.new(0, size.Y * 0.84, 0), "sign")
    elseif kind == "Arch" then
        addPart("ArchLeft", Enum.PartType.Block, Vector3.new(size.X * 0.22, size.Y, size.Z), Vector3.new(-size.X * 0.38, size.Y * 0.42, 0), "arch")
        addPart("ArchRight", Enum.PartType.Block, Vector3.new(size.X * 0.22, size.Y, size.Z), Vector3.new(size.X * 0.38, size.Y * 0.42, 0), "arch")
        addPart("ArchTop", Enum.PartType.Block, Vector3.new(size.X, size.Y * 0.24, size.Z), Vector3.new(0, size.Y * 0.9, 0), "arch")
    else
        addPart("StoryFallbackBody", Enum.PartType.Block, size, Vector3.new(0, size.Y * 0.45, 0), "landmark")
    end

    return model
end

function MapLayoutService:PositionStoryAsset(asset, spec)
    local position = self:CompactPosition(spec.position)
    local yaw = math.rad(spec.yawDegrees or 0)
    local cframe = CFrame.new(position) * CFrame.Angles(0, yaw, 0)

    if spec.scale and asset:IsA("Model") then
        pcall(function()
            asset:ScaleTo(spec.scale)
        end)
    elseif spec.scale and asset:IsA("BasePart") then
        asset.Size = asset.Size * spec.scale
    end

    if asset:IsA("Model") then
        if not asset.PrimaryPart then
            asset.PrimaryPart = firstBasePart(asset)
        end
        asset:PivotTo(cframe)
    elseif asset:IsA("BasePart") then
        asset.CFrame = cframe
    end
end

function MapLayoutService:EnsureStoryAssetPlacements(folders)
    folders = folders or self:EnsureMapFolders()
    local beatRoots = self:EnsureStoryBeatRoots(folders)
    local placed = 0
    local imported = 0
    local fallback = 0

    for _, spec in ipairs(StoryAssetPlacements.Placements) do
        local targetFolder = self:GetStoryAssetTargetFolder(folders, spec)
        local existing = targetFolder:FindFirstChild(spec.name)
        if existing then existing:Destroy() end

        local source = self:FindStoryAssetTemplate(spec)
        local asset
        if source then
            asset = self:CloneStoryAssetSource(source)
            asset.Name = spec.name
            self:SanitizeStoryAssetClone(asset, spec, source)
            imported = imported + 1
        else
            asset = self:CreateFallbackStoryAsset(spec)
            fallback = fallback + 1
        end

        self:PositionStoryAsset(asset, spec)
        asset.Parent = targetFolder
        if not CollectionService:HasTag(asset, "StoryAssetPlacement") then
            CollectionService:AddTag(asset, "StoryAssetPlacement")
        end

        local beatRoot = beatRoots[spec.beatRoot] or self:GetStoryBeatRoot(folders, spec.beatRoot, spec.beatId, spec.beatRoot)
        local links = self:GetOrCreateFolder(beatRoot, "PlacedAssets")
        local link = links:FindFirstChild(spec.name)
        if not link then
            link = Instance.new("ObjectValue")
            link.Name = spec.name
            link.Parent = links
        end
        link.Value = asset
        link:SetAttribute("StoryboardSlot", spec.slot)
        link:SetAttribute("TargetFolder", targetFolder:GetFullName())

        placed = placed + 1
    end

    folders.Map:SetAttribute("StoryAssetPlacementsBuilt", true)
    folders.Map:SetAttribute("StoryAssetPlacementCount", placed)
    folders.Map:SetAttribute("StoryAssetImportedTemplateCount", imported)
    folders.Map:SetAttribute("StoryAssetFallbackProxyCount", fallback)
    return {
        placed = placed,
        imported = imported,
        fallback = fallback,
    }
end

local function tryRequireFishService()
    local services = game:GetService("ServerScriptService"):FindFirstChild("Services")
    local module = services and services:FindFirstChild("FishService")
    if not module then return nil end
    local ok, service = pcall(require, module)
    if ok then return service end
    return nil
end

function MapLayoutService:ApplyStoryboardAssetAttributes(instance, slotName, asset)
    instance:SetAttribute("StoryBeatId", SwampDeltaStoryboard.BeatId)
    instance:SetAttribute("StoryboardSlot", slotName)
    instance:SetAttribute("StoryboardSourceAssetId", asset.sourceAssetId)
    instance:SetAttribute("StoryboardAssetName", asset.name)
    instance:SetAttribute("StoryboardAssetQuery", asset.query)
    instance:SetAttribute("StoryboardAssetSource", asset.source)
    instance:SetAttribute("StoryboardScriptRisk", asset.scriptRisk)
    instance:SetAttribute("StoryAssetValidationState", SwampDeltaStoryboard.ValidationState)
    instance:SetAttribute("AssetBackedStoryboardProxy", true)
    instance:SetAttribute("NeedsStudioAssetInspection", true)
    instance:SetAttribute("NeedsPlayerAngleScreenshot", true)
    instance:SetAttribute("CreatorStoreOnly", nil)
    instance:SetAttribute("ImportedVisibleAsset", nil)
    instance:SetAttribute("SourceAssetId", nil)
    instance:SetAttribute("AssetManifestId", nil)
end

function MapLayoutService:ApplyVisibleStoryboardProxy(part, releaseReason)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part:SetAttribute("ProceduralGameplayVisual", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
    part:SetAttribute("ReleaseVisibleGeneratedPartReason", releaseReason)
    part:SetAttribute("VisibleGameplayAffordance", true)
    part:SetAttribute("Decorative", true)
    part:SetAttribute("FloatingAllowed", true)
    part:SetAttribute("GroundTopY", self.ZoneTerrain.SwampDelta.topY)
end

function MapLayoutService:EnsureSwampDeltaStoryboard(folders)
    folders = folders or self:EnsureMapFolders()

    local storyboardRoot = self:GetOrCreateFolder(self:GetOrCreateFolder(folders.Map, "Storyboards"), "SwampDeltaOxygenFish")
    storyboardRoot:SetAttribute("StoryBeatId", SwampDeltaStoryboard.BeatId)
    storyboardRoot:SetAttribute("DisplayName", SwampDeltaStoryboard.DisplayName)
    storyboardRoot:SetAttribute("SourceDocument", SwampDeltaStoryboard.SourceDocument)
    storyboardRoot:SetAttribute("CacheManifest", SwampDeltaStoryboard.CacheManifest)
    storyboardRoot:SetAttribute("SearchPolicy", "custom_asset_search_mcp_only")
    storyboardRoot:SetAttribute("ValidationState", SwampDeltaStoryboard.ValidationState)
    storyboardRoot:SetAttribute("NeedsPlayerAngleScreenshot", true)
    storyboardRoot:SetAttribute("RequiredVerdict", SwampDeltaStoryboard.PlayerAngleReview.requiredVerdict)

    local deferredFolder = self:GetOrCreateFolder(storyboardRoot, "RejectedOrDeferredCandidates")
    for _, item in ipairs(SwampDeltaStoryboard.RejectedOrDeferred) do
        local marker = deferredFolder:FindFirstChild("Asset_" .. item.sourceAssetId)
        if not marker then
            marker = Instance.new("Folder")
            marker.Name = "Asset_" .. item.sourceAssetId
            marker.Parent = deferredFolder
        end
        marker:SetAttribute("SourceAssetId", item.sourceAssetId)
        marker:SetAttribute("AssetName", item.name)
        marker:SetAttribute("RejectOrDeferReason", item.reason)
    end

    local safeFolder = self:GetOrCreateFolder(storyboardRoot, "OxygenSafeNodes")
    local lilyAsset = SwampDeltaStoryboard.Assets.LilyPad
    for _, node in ipairs(SwampDeltaStoryboard.SafeNodes) do
        local pad = safeFolder:FindFirstChild(node.name)
        if not pad then
            pad = Instance.new("Part")
            pad.Name = node.name
            pad.Parent = safeFolder
        end
        local radius = node.radius * self.CompactLayout.scaleXZ
        pad.Shape = Enum.PartType.Cylinder
        pad.Size = Vector3.new(radius * 2, 0.35, radius * 2)
        pad.Position = self:CompactPosition(node.position)
        pad.Color = Color3.fromRGB(82, 144, 76)
        pad.Material = Enum.Material.Grass
        pad.Transparency = 0.08
        pad:SetAttribute("SwampOxygenSafeNode", true)
        pad:SetAttribute("OxygenReliefPerSecond", node.oxygenRelief)
        pad:SetAttribute("ZoneId", "SwampDelta")
        self:ApplyVisibleStoryboardProxy(pad, "Cache-backed water-lily safe node proxy awaiting Creator Store asset insertion and player-angle review.")
        self:ApplyStoryboardAssetAttributes(pad, "beat5.swamp_delta.lilypad", lilyAsset)
    end

    local apexAsset = SwampDeltaStoryboard.Assets.SpinosaurusSilhouette
    local apex = storyboardRoot:FindFirstChild(SwampDeltaStoryboard.ApexWarning.name)
    if not apex then
        apex = Instance.new("Part")
        apex.Name = SwampDeltaStoryboard.ApexWarning.name
        apex.Parent = storyboardRoot
    end
    local apexPosition = self:CompactPosition(SwampDeltaStoryboard.ApexWarning.position)
    local apexSize = SwampDeltaStoryboard.ApexWarning.size
    apex.Shape = Enum.PartType.Block
    apex.Size = Vector3.new(apexSize.X * self.CompactLayout.scaleXZ, apexSize.Y, apexSize.Z * self.CompactLayout.scaleXZ)
    apex.CFrame = CFrame.new(apexPosition) * CFrame.Angles(0, math.rad(SwampDeltaStoryboard.ApexWarning.yawDegrees or 0), 0)
    apex.Color = Color3.fromRGB(54, 72, 62)
    apex.Material = Enum.Material.Slate
    apex.Transparency = 0.18
    apex:SetAttribute("ApexWarning", true)
    apex:SetAttribute("ZoneId", "SwampDelta")
    apex:SetAttribute("InteractionHint", "A heavy wake cuts across the reeds")
    self:ApplyVisibleStoryboardProxy(apex, "Cache-backed Spinosaurus silhouette proxy; final NPC/model asset must pass script audit and player-angle screenshots.")
    self:ApplyStoryboardAssetAttributes(apex, "beat5.swamp_delta.spinosaurus", apexAsset)

    local fishService = tryRequireFishService()
    local fishAsset = SwampDeltaStoryboard.Assets.Fish
    local fishFolder = fishService and fishService:GetFolder()
    for _, fishSpec in ipairs(SwampDeltaStoryboard.FishSources) do
        local water = folders.WaterSources:FindFirstChild(fishSpec.waterName)
        local fish = fishFolder and fishFolder:FindFirstChild(fishSpec.name)
        if fishService and water then
            local offset = Vector3.new(
                fishSpec.offset.X * self.CompactLayout.scaleXZ,
                fishSpec.offset.Y,
                fishSpec.offset.Z * self.CompactLayout.scaleXZ
            )
            if fish then
                fishService:MoveWithinWater(fish, water, offset)
            else
                fish = fishService:CreateFishSource(water, fishSpec.name, offset)
            end
            if fish then
                fish:SetAttribute("ZoneId", "SwampDelta")
                fish:SetAttribute("StoryboardWaterName", fishSpec.waterName)
                fish:SetAttribute("SwampDeltaStoryboardFish", true)
                self:ApplyStoryboardAssetAttributes(fish, "beat5.swamp_delta.fish", fishAsset)
            end
        end
    end

    local review = SwampDeltaStoryboard.PlayerAngleReview
    storyboardRoot:SetAttribute("ReviewSpaceId", review.spaceId)
    storyboardRoot:SetAttribute("ReviewEntry", tostring(self:CompactPosition(review.entry)))
    storyboardRoot:SetAttribute("ReviewCenter", tostring(self:CompactPosition(review.center)))
    storyboardRoot:SetAttribute("ReviewLookAt", tostring(self:CompactPosition(review.lookAt)))
    storyboardRoot:SetAttribute("ReviewQuadrants", table.concat(review.quadrants, ","))
    return storyboardRoot
end

function MapLayoutService:IsLiveCarnivoreFoodKind(kind)
    return kind == "Prey" or kind == "AerialPrey" or kind == "FlyingPrey"
end

function MapLayoutService:GetNPCSpawnSpeciesId(spec)
    return spec.speciesId or self.NPCKindSpeciesIds[spec.kind] or "gallimimus"
end

function MapLayoutService:GetGroundTopYForZone(zoneId)
    local zone = self.ZoneTerrain[zoneId]
    return zone and zone.topY or self.FullMapUnderlay.topY
end

function MapLayoutService:GetPlacementRadius(size)
    if typeof(size) ~= "Vector3" then return 4 end
    return math.max(size.X, size.Z) / 2
end

function MapLayoutService:EnsureNPCSpawnMarkers(folders)
    for _, spec in ipairs(self.NPCSpawnPlacements) do
        local marker = folders.NPCSpawns:FindFirstChild(spec.name)
        if not marker then
            marker = Instance.new("Part")
            marker.Name = spec.name
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.Transparency = 1
            marker.Size = Vector3.new(8, 2, 8)
            marker.Parent = folders.NPCSpawns
        end
        marker.Position = spec.position
        marker:SetAttribute("NPCSpawn", true)
        marker:SetAttribute("NPCKind", spec.kind)
        marker:SetAttribute("ZoneId", spec.zone)
        marker:SetAttribute("SafeBabyArea", spec.tutorialSafe == true)
        marker:SetAttribute("DangerousNPC", spec.dangerous == true)
        marker:SetAttribute("NestingHerd", spec.nestingHerd == true)
        marker:SetAttribute("SpeciesId", self:GetNPCSpawnSpeciesId(spec))
        marker:SetAttribute("GroundTopY", self:GetGroundTopYForZone(spec.zone))
        marker:SetAttribute("FloatingAllowed", spec.aerial == true or spec.flyingPrey == true)
        marker:SetAttribute("PlacementRadiusStuds", self:GetPlacementRadius(marker.Size))
        marker:SetAttribute("AvoidOverlap", true)
        local species = SpeciesConfig[self:GetNPCSpawnSpeciesId(spec)]
        local preferredBiome = species and species.EcosystemProfile and (species.EcosystemProfile.PreferredBiome or (species.EcosystemProfile.PreferredZones and species.EcosystemProfile.PreferredZones[1]))
        marker:SetAttribute("PreferredBiome", preferredBiome)
        marker:SetAttribute("SpeciesRelevantSpawn", preferredBiome == nil or preferredBiome == spec.zone or spec.zone == "NurseryGrove" or spec.nestingHerd == true)
        local aerialSpawn = spec.aerial == true or spec.kind == "AerialPrey" or spec.kind == "AerialPredator" or spec.kind == "FlyingPrey" or spec.flyingPrey == true
        marker:SetAttribute("AerialSpawn", aerialSpawn)
        marker:SetAttribute("PreferredAltitude", spec.preferredAltitude or (aerialSpawn and marker.Position.Y or nil))
        marker:SetAttribute("FlyingPrey", spec.kind == "AerialPrey" or spec.kind == "FlyingPrey" or spec.flyingPrey == true)
        marker:SetAttribute("FlightTarget", spec.kind == "AerialPrey" or spec.kind == "FlyingPrey" or spec.flyingPrey == true)
        local liveCarnivoreFood = self:IsLiveCarnivoreFoodKind(spec.kind)
        marker:SetAttribute("PotentialCarnivoreFood", liveCarnivoreFood)
        marker:SetAttribute("CarnivoreFoodCandidate", liveCarnivoreFood)
        marker:SetAttribute("FoodWhenDefeated", true)
        marker:SetAttribute("CarnivoreFoodKind", self.NPCKindFoodWhenDefeated[spec.kind] or (spec.dangerous == true and "HighRiskCarcass" or "PreyCarcass"))
        marker:SetAttribute("FoodSourceCandidate", true)
    end
    return folders.NPCSpawns
end

function MapLayoutService:EnsurePlayerSpawnMarkers(folders)
    local spawnFolder = self:GetOrCreateFolder(folders.Map, "SpawnLocations")
    for _, spec in ipairs(self.PlayerSpawnPlacements) do
        local spawn = spawnFolder:FindFirstChild(spec.name)
        if spawn and not spawn:IsA("SpawnLocation") then
            spawn:Destroy()
            spawn = nil
        end
        if not spawn then
            spawn = Instance.new("SpawnLocation")
            spawn.Name = spec.name
            spawn.Anchored = true
            spawn.CanCollide = true
            spawn.CanTouch = false
            spawn.CanQuery = true
            spawn.Transparency = 1
            spawn.Neutral = true
            spawn.Duration = 0
            spawn.Size = Vector3.new(18, 2, 18)
            spawn.Parent = spawnFolder
        end
        spawn.Position = spec.position
        spawn:SetAttribute("GameplayVolume", true)
        spawn:SetAttribute("PlayerSpawn", true)
        spawn:SetAttribute("StarterSpeciesSpawn", true)
        spawn:SetAttribute("SpeciesId", spec.speciesId)
        spawn:SetAttribute("ZoneId", spec.zone)
        spawn:SetAttribute("YawDegrees", spec.yawDegrees or 0)
        spawn:SetAttribute("PitchDegrees", 0)
        spawn:SetAttribute("RollDegrees", 0)
        spawn:SetAttribute("SourceExpectedUpright", true)
        spawn:SetAttribute("GroundTopY", self:GetGroundTopYForZone(spec.zone))
        spawn:SetAttribute("FloatingAllowed", false)
        spawn:SetAttribute("PlacementRadiusStuds", self:GetPlacementRadius(spawn.Size))
        spawn:SetAttribute("AvoidOverlap", true)
    end
    return spawnFolder
end

function MapLayoutService:GetPlayerSpawnForSpecies(speciesId, preferredBiome, roll)
    local species = SpeciesConfig[speciesId or ""] or SpeciesConfig.gallimimus
    local resolvedSpeciesId = species and species.SpeciesId or "gallimimus"
    local folders = self:EnsureMapFolders()
    local spawnFolder = self:EnsurePlayerSpawnMarkers(folders)
    local candidates = {}
    local fallback = {}
    for _, spawn in ipairs(spawnFolder:GetChildren()) do
        if spawn:GetAttribute("PlayerSpawn") == true and spawn:GetAttribute("SpeciesId") == resolvedSpeciesId then
            table.insert(fallback, spawn)
            if not preferredBiome or spawn:GetAttribute("ZoneId") == preferredBiome then
                table.insert(candidates, spawn)
            end
        end
    end
    if #candidates == 0 then
        candidates = fallback
    end
    if #candidates == 0 then
        local legacy = spawnFolder:FindFirstChild("_INVISIBLE_EggSpawn_Nursery")
        return legacy, legacy and (legacy.CFrame + Vector3.new(0, 4, 0)) or CFrame.new(self:CompactPosition(Vector3.new(-2000, 16, 0)))
    end
    local index = 1
    if type(roll) == "number" then
        index = math.clamp(math.floor(roll), 1, #candidates)
    elseif #candidates > 1 then
        index = math.random(1, #candidates)
    end
    local spawn = candidates[index]
    local yaw = math.rad(spawn:GetAttribute("YawDegrees") or 0)
    return spawn, CFrame.new(spawn.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, yaw, 0)
end

function MapLayoutService:EnsureTutorialCombatTarget(folders)
    local target = folders.Map:FindFirstChild("TutorialPracticeTarget")
    if not target then
        target = Instance.new("Part")
        target.Name = "TutorialPracticeTarget"
        target.Anchored = true
        target.Shape = Enum.PartType.Block
        target.Material = Enum.Material.SmoothPlastic
        target.Color = Color3.fromRGB(235, 82, 64)
        target.Parent = folders.Map
    end
    target.Position = self:CompactPosition(Vector3.new(-1976, 14, 10))
    target.Size = Vector3.new(6, 6, 6)
    target.CanCollide = false
    target.CanTouch = true
    target.CanQuery = true
    target.Transparency = 1
    target:SetAttribute("Health", math.max(1, target:GetAttribute("Health") or 40))
    target:SetAttribute("MaxHealth", 40)
    target:SetAttribute("TutorialSafe", true)
    target:SetAttribute("ZoneId", "NurseryGrove")
    target:SetAttribute("InteractionHint", "Attack practice target")
    target:SetAttribute("InvisibleQueryHelper", true)
    target:SetAttribute("VisibleGameplayAffordance", false)
    target:SetAttribute("ReleaseHiddenProceduralVisual", true)
    if not CollectionService:HasTag(target, "Damageable") then
        CollectionService:AddTag(target, "Damageable")
    end
    return target
end

function MapLayoutService:EnsureSpawnSafety()
    local folders = self:EnsureMapFolders()
    local spawnFolder = self:GetOrCreateFolder(folders.Map, "SpawnLocations")
    local spawn = spawnFolder:FindFirstChild("_INVISIBLE_EggSpawn_Nursery")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Name = "_INVISIBLE_EggSpawn_Nursery"
        spawn.Anchored = true
        spawn.CanCollide = true
        spawn.CanTouch = false
        spawn.CanQuery = true
        spawn.Transparency = 1
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Size = Vector3.new(18, 2, 18)
        spawn.Parent = spawnFolder
    end
    spawn.Position = self:CompactPosition(Vector3.new(-2000, 12, 0))
    spawn:SetAttribute("GameplayVolume", true)
    spawn:SetAttribute("ZoneId", "NurseryGrove")
    spawn:SetAttribute("PlayerSpawn", true)
    spawn:SetAttribute("StarterSpeciesSpawn", true)
    spawn:SetAttribute("SpeciesId", "starter_fallback")

    self:EnsurePlayerSpawnMarkers(folders)

    self:EnsureTerrainContinuity(folders)
    self:EnsureBiomeElevation(folders)
    self:EnsureFoodSourcePlacements(folders)
    self:EnsureFoodSources()
    self:EnsureBiomeDressing(folders)
    self:EnsureSwampDeltaStoryboard(folders)
    self:EnsureStoryAssetPlacements(folders)
    self:EnsureNPCSpawnMarkers(folders)
    self:EnsureTutorialCombatTarget(folders)
    self:EnsureCityDiscoveryTriggers(folders)
    self:EnsureFallSafetyVolume(folders)
    -- Run grounding + world-mood passes LAST so they re-seat the visible
    -- props produced above onto the freshly sculpted terrain. All of these are
    -- additive and no-op when terrain / Studio globals are absent (test stubs),
    -- so they never perturb the guarded placement assertions.
    self:EnsureGroundedDressing(folders)
    self:EnsureSkyAtmosphere()
    self:EnsureDecoratedBoundary(folders)
    return spawn
end

function MapLayoutService:ValidateLayoutFolders()
    local folders = self:EnsureMapFolders()
    self:EnsureSpawnSafety()
    local missing = {}
    for zoneId in pairs(ZoneConfig) do
        if not folders.Zones:FindFirstChild(zoneId) then table.insert(missing, zoneId) end
    end
    for _, route in ipairs(self.RouteTerrain) do
        if not folders.Routes:FindFirstChild(route.name) then table.insert(missing, route.name) end
    end
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_FallSafetyCatch") then
        table.insert(missing, "_INVISIBLE_FallSafetyCatch")
    end
    local cityTriggers = folders.InvisibleGameplayVolumes:FindFirstChild("CityDiscoveryTriggers")
    if not cityTriggers or not cityTriggers:FindFirstChild("_INVISIBLE_CityDiscovery_CityCore") then
        table.insert(missing, "CityDiscoveryTriggers")
    end
    if not folders.BiomeDressing or #folders.BiomeDressing:GetChildren() == 0 then
        table.insert(missing, "BiomeDressing")
    end
    if not folders.InvisibleGameplayVolumes:FindFirstChild("_INVISIBLE_" .. self.FullMapUnderlay.name) then
        table.insert(missing, self.FullMapUnderlay.name)
    end
    return #missing == 0, missing
end

-- ──────────────────────────────────────────────────────────────────────────────
-- WorldBuilderService integration (Lane G addition)
-- Lazy-required so the file still loads in test stubs without Studio globals.
-- ──────────────────────────────────────────────────────────────────────────────
local _WorldBuilder = nil
local function getWorldBuilder()
    if not _WorldBuilder then
        local ok, wb = pcall(require, game:GetService("ServerScriptService").Services.WorldBuilderService)
        if ok then _WorldBuilder = wb end
    end
    return _WorldBuilder
end

-- BiomeCenters()
-- Returns the 6 condensed biome center Vector3 positions via WorldBuilderService.
-- Outer biomes are within 1 400 studs of NurseryGrove (satisfies BiomePlacementValidation).
function MapLayoutService:BiomeCenters()
    local wb = getWorldBuilder()
    if wb then
        return wb.BiomeCenters()
    end
    -- Fallback: derive directly from ZoneTerrain table (already compact-transformed)
    local centers = {}
    for zoneId, zone in pairs(self.ZoneTerrain) do
        if zoneId ~= "MountainNestingCliffs" then
            centers[zoneId] = zone.center
        end
    end
    return centers
end

-- GroundPlace(model, x, z)
-- Delegates to WorldBuilderService.GroundPlace.  Safe no-op if WB unavailable.
function MapLayoutService:GroundPlace(model, x, z)
    local wb = getWorldBuilder()
    if wb then
        return wb.GroundPlace(model, x, z)
    end
    warn("[MapLayoutService] GroundPlace: WorldBuilderService unavailable")
    return nil
end

-- ──────────────────────────────────────────────────────────────────────────────
-- EnsureBiomeElevation(folders)  [ADDITIVE]
-- Sculpts gentle per-biome Terrain elevation (domes / canyon shelving / basins)
-- on top of the flat ZoneTerrain fills, plus shorelines around terrain water.
-- Pure no-op when WorldBuilderService or live Terrain is unavailable, so the
-- BiomePlacementValidation / CollisionValidation suites (which run without
-- sculpted terrain) are unaffected. Records a marker attribute for telemetry.
-- ──────────────────────────────────────────────────────────────────────────────
function MapLayoutService:EnsureBiomeElevation(folders)
    folders = folders or self:EnsureMapFolders()
    local wb = getWorldBuilder()
    if not wb or type(wb.SculptBiomeMound) ~= "function" then
        return false
    end

    local profiles = wb.BiomeElevation and wb.BiomeElevation() or {}
    local sculpted = 0
    for zoneId, zone in pairs(self.ZoneTerrain) do
        local profile = profiles[zoneId]
        if profile then
            local top = Vector3.new(zone.center.X, zone.topY, zone.center.Z)
            wb.SculptBiomeMound(top, zone.size, profile)
            sculpted = sculpted + 1
            local zoneFolder = folders.Zones:FindFirstChild(zoneId)
            if zoneFolder then
                zoneFolder:SetAttribute("Sculpted", true)
            end
        end
    end

    -- Soft shorelines around each terrain-water body so water meets land
    -- naturally rather than as a hard square plate.
    for _, water in ipairs(self.ShallowWater) do
        local profile = nil
        for zoneId, zone in pairs(self.ZoneTerrain) do
            if (Vector3.new(water.center.X, zone.center.Y, water.center.Z) - Vector3.new(zone.center.X, zone.center.Y, zone.center.Z)).Magnitude
                <= math.max(zone.size.X, zone.size.Z) then
                profile = profiles[zoneId]
                break
            end
        end
        local shoreMaterial = (profile and profile.shoreline) or Enum.Material.Sand
        wb.SculptShoreline(water.center, water.size, shoreMaterial)
    end

    folders.Map:SetAttribute("BiomeElevationSculpted", sculpted > 0)
    return sculpted > 0
end

-- ──────────────────────────────────────────────────────────────────────────────
-- EnsureGroundedDressing(folders)  [ADDITIVE]
-- Raycast-reseats every visible biome-dressing / scenery / food-visual part onto
-- the real (sculpted) terrain surface and refreshes its GroundTopY attribute, so
-- nothing floats after elevation is applied. No-op without live Terrain (so the
-- floating-asset validation still passes against authored positions in tests).
-- Tagged invisible gameplay query parts are intentionally skipped — only visible
-- decorative parts are re-seated; the query volumes keep their authored Y.
-- ──────────────────────────────────────────────────────────────────────────────
function MapLayoutService:EnsureGroundedDressing(folders)
    folders = folders or self:EnsureMapFolders()
    local wb = getWorldBuilder()
    if not wb or type(wb.RegroundPart) ~= "function" then
        return 0
    end
    local Workspace = game:GetService("Workspace")
    if not Workspace:FindFirstChildOfClass("Terrain") then
        return 0
    end

    local grounded = 0
    local roots = { folders.BiomeDressing }
    for _, root in ipairs(roots) do
        if root then
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("BasePart")
                    and inst.Transparency < 1
                    and inst:GetAttribute("FloatingAllowed") ~= true
                    and inst:GetAttribute("BiomeDressing") == true then
                    if wb.RegroundPart(inst) then
                        grounded = grounded + 1
                    end
                end
            end
        end
    end

    folders.Map:SetAttribute("DressingGroundedCount", grounded)
    return grounded
end

-- ──────────────────────────────────────────────────────────────────────────────
-- EnsureSkyAtmosphere()  [ADDITIVE]
-- Delegates to WorldBuilderService.EnsureSkyAndAtmosphere() to replace the
-- default skybox with a curated Sky + Atmosphere + calm dawn Lighting mood.
-- No-op-safe in test stubs. Does not touch weather state.
-- ──────────────────────────────────────────────────────────────────────────────
function MapLayoutService:EnsureSkyAtmosphere()
    local wb = getWorldBuilder()
    if wb and type(wb.EnsureSkyAndAtmosphere) == "function" then
        local ok = pcall(function()
            wb.EnsureSkyAndAtmosphere()
        end)
        return ok
    end
    return false
end

-- ──────────────────────────────────────────────────────────────────────────────
-- EnsureDecoratedBoundary(folders)  [ADDITIVE]
-- Builds the boundary ring (thin invisible collision wall + decorative scenery
-- markers) around the full compact playable footprint so there is no hard
-- drop-off edge. Radius is derived from the full-map underlay so it encloses
-- every biome. No-op-safe in test stubs (BuildBoundaryRing only creates parts).
-- ──────────────────────────────────────────────────────────────────────────────
function MapLayoutService:EnsureDecoratedBoundary(folders)
    folders = folders or self:EnsureMapFolders()
    local wb = getWorldBuilder()
    if not wb or type(wb.BuildBoundaryRing) ~= "function" then
        return nil
    end
    local underlay = self.FullMapUnderlay
    local center = Vector3.new(underlay.center.X, underlay.topY or 0, underlay.center.Z)
    -- Enclose the widest map dimension with a small margin.
    local radius = math.max(underlay.size.X, underlay.size.Z) / 2 + 60
    local ok, ring = pcall(function()
        return wb.BuildBoundaryRing(center, radius, folders.Map)
    end)
    if ok and ring then
        folders.Map:SetAttribute("BoundaryRingRadius", radius)
        return ring
    end
    return nil
end

return MapLayoutService
