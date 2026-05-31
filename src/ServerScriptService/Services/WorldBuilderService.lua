-- WorldBuilderService
-- Reusable, deterministic world-building toolkit for eggBreakers.
-- Lane G owns this file only. Do NOT edit FoodWaterService, WaterService,
-- NPCSpawnService, Constants, CombatService, or NPCService.

local WorldBuilderService = {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Condensed 6-biome centers (post 50% compact transform, NurseryGrove = origin)
-- These match MapLayoutService.ZoneTerrain after ApplyCompactLayout().
-- Distances from NurseryGrove stay at or below 1 400 studs per the design doc
-- "condensed contiguous map" constraint and BiomePlacementValidation test.
-- ──────────────────────────────────────────────────────────────────────────────
local BIOME_CENTERS = {
    NurseryGrove         = Vector3.new(-2000,   0,    0),   -- safe spawn / origin
    FernPlains           = Vector3.new(-1575,   0,    0),   -- ~425 studs from Nursery
    JungleBasin          = Vector3.new(-1725,   0,  475),   -- ~677 studs
    RedstoneCanyon       = Vector3.new(-1100,   0, -325),   -- ~995 studs
    SwampDelta           = Vector3.new(-1075,   0,  475),   -- ~978 studs
    ApocalypticCity      = Vector3.new( -650,   0,    0),   -- ~1 350 studs
}
-- Note: MountainNestingCliffs is excluded from the flat biome ring (it is a
-- vertical zone reached via a ramp) — its terrain center is at high Y and is
-- handled separately by MapLayoutService.ZoneTerrain.

-- ──────────────────────────────────────────────────────────────────────────────
-- BiomeCenters()
-- Returns the 6 playable biome center positions (Vector3).  These are the
-- post-compact positions used by ScatterCluster and BuildBoundaryRing callers.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.BiomeCenters()
    local result = {}
    for name, pos in pairs(BIOME_CENTERS) do
        result[name] = pos
    end
    return result
end

-- ──────────────────────────────────────────────────────────────────────────────
-- GroundPlace(model, x, z)
-- Raycast straight down against Workspace.Terrain only; place the model's
-- PrimaryPart (or first BasePart) flush on the terrain surface, anchored.
-- Returns the placed Y position, or nil if terrain was not found.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.GroundPlace(model, x, z)
    local Workspace = game:GetService("Workspace")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        warn("[WorldBuilderService] GroundPlace: Terrain not found, model not placed")
        return nil
    end

    local startY = 500
    local origin = Vector3.new(x, startY, z)
    local direction = Vector3.new(0, -startY - 200, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { terrain }

    local result = Workspace:Raycast(origin, direction, raycastParams)
    if not result then
        warn(string.format("[WorldBuilderService] GroundPlace: no terrain hit at (%.1f, %.1f)", x, z))
        return nil
    end

    local surfaceY = result.Position.Y

    -- Find the primary part or first BasePart to position the model
    local root = nil
    if model:IsA("BasePart") then
        root = model
    elseif model:IsA("Model") then
        root = model.PrimaryPart
        if not root then
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") then
                    root = child
                    break
                end
            end
        end
    end

    if not root then
        warn("[WorldBuilderService] GroundPlace: model has no BasePart")
        return surfaceY
    end

    -- Anchor and place flush on surface
    root.Anchored = true
    local halfHeight = (root:IsA("BasePart") and root.Size.Y / 2) or 0
    if model:IsA("Model") and model.PrimaryPart then
        model:SetPrimaryPartCFrame(CFrame.new(x, surfaceY + halfHeight, z))
    else
        root.Position = Vector3.new(x, surfaceY + halfHeight, z)
    end

    return surfaceY
end

-- ──────────────────────────────────────────────────────────────────────────────
-- ScatterCluster(template, biomeCenter, radius, count, rng)
-- Clone `template` count times, scattered naturally around biomeCenter within
-- `radius` studs.  Uses `rng` (a Random object) for determinism.
-- Each clone is GroundPlaced on terrain.  Returns a table of placed clones.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.ScatterCluster(template, biomeCenter, radius, count, rng)
    if not template then
        warn("[WorldBuilderService] ScatterCluster: template is nil")
        return {}
    end
    rng = rng or Random.new()
    local placed = {}

    for i = 1, count do
        -- Poisson-disk-style: random angle, random radius with sqrt for uniform area distribution
        local angle = rng:NextNumber(0, 2 * math.pi)
        local r     = math.sqrt(rng:NextNumber(0, 1)) * radius
        local dx    = math.cos(angle) * r
        local dz    = math.sin(angle) * r

        local x = biomeCenter.X + dx
        local z = biomeCenter.Z + dz

        local clone
        if template:IsA("Model") then
            clone = template:Clone()
        else
            clone = template:Clone()
        end

        -- Small random yaw rotation for naturalism
        local yaw = rng:NextNumber(0, 2 * math.pi)
        if clone:IsA("Model") and clone.PrimaryPart then
            clone.PrimaryPart.Anchored = true
        elseif clone:IsA("BasePart") then
            clone.Anchored = true
            clone.CFrame = clone.CFrame * CFrame.Angles(0, yaw, 0)
        end

        clone.Parent = game:GetService("Workspace")
        local surfaceY = WorldBuilderService.GroundPlace(clone, x, z)

        -- Apply yaw after grounding for Model case
        if clone:IsA("Model") and clone.PrimaryPart and surfaceY then
            local currentCF = clone.PrimaryPart.CFrame
            clone:SetPrimaryPartCFrame(CFrame.new(currentCF.Position) * CFrame.Angles(0, yaw, 0))
        end

        table.insert(placed, clone)
    end

    return placed
end

-- ──────────────────────────────────────────────────────────────────────────────
-- BuildBoundaryRing(center, radius, parent)
-- Creates a ring of scenery anchors (invisible Part markers) plus a thin
-- invisible collision wall so players cannot walk off the playable area.
-- No hard drop-off: the wall is a continuous ring of thin collision parts at
-- ground level so players are nudged back.
-- `parent` defaults to Workspace.  Returns the folder containing ring parts.
-- ──────────────────────────────────────────────────────────────────────────────
local RING_SEGMENT_COUNT = 48      -- smoothness of the circular wall
local WALL_HEIGHT         = 24     -- studs tall — above max dino height
local WALL_THICKNESS      = 4      -- thin invisible wall

function WorldBuilderService.BuildBoundaryRing(center, radius, parent)
    local Workspace = game:GetService("Workspace")
    parent = parent or Workspace

    local ringFolder = parent:FindFirstChild("_BoundaryRing")
    if not ringFolder then
        ringFolder = Instance.new("Folder")
        ringFolder.Name = "_BoundaryRing"
        ringFolder.Parent = parent
    end

    local segmentAngle = (2 * math.pi) / RING_SEGMENT_COUNT
    local segmentArcLength = 2 * math.pi * radius / RING_SEGMENT_COUNT
    local wallY = center.Y + WALL_HEIGHT / 2

    for i = 0, RING_SEGMENT_COUNT - 1 do
        local angle = i * segmentAngle
        local midAngle = angle + segmentAngle / 2
        local wx = center.X + math.cos(midAngle) * radius
        local wz = center.Z + math.sin(midAngle) * radius

        local segName = string.format("_BoundaryWall_%02d", i)
        local seg = ringFolder:FindFirstChild(segName)
        if not seg then
            seg = Instance.new("Part")
            seg.Name = segName
            seg.Parent = ringFolder
        end

        seg.Anchored     = true
        seg.CanCollide   = true
        seg.CanTouch     = false
        seg.CanQuery     = false
        seg.Transparency = 1
        seg.Size         = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, segmentArcLength + 1)

        -- Orient segment to face inward (tangent to circle)
        local lookDir = Vector3.new(-math.sin(midAngle), 0, math.cos(midAngle))
        local cf = CFrame.lookAt(Vector3.new(wx, wallY, wz), Vector3.new(wx, wallY, wz) + lookDir)
        seg.CFrame = cf

        seg:SetAttribute("BoundaryWall", true)
        seg:SetAttribute("InvisibleCollider", true)
        seg:SetAttribute("GameplayVolume", true)
    end

    -- Decorative scenery marker ring (visible boundary indicators, e.g. cliff edges)
    -- These are placed as invisible markers; actual dressing is done via BiomeDressing
    local sceneryFolder = ringFolder:FindFirstChild("SceneryMarkers")
    if not sceneryFolder then
        sceneryFolder = Instance.new("Folder")
        sceneryFolder.Name = "SceneryMarkers"
        sceneryFolder.Parent = ringFolder
    end

    local SCENERY_COUNT = 12
    local sceneryStep = (2 * math.pi) / SCENERY_COUNT
    for i = 0, SCENERY_COUNT - 1 do
        local angle = i * sceneryStep
        local sx = center.X + math.cos(angle) * (radius - 20)
        local sz = center.Z + math.sin(angle) * (radius - 20)

        local markerName = string.format("_BoundaryScenery_%02d", i)
        local marker = sceneryFolder:FindFirstChild(markerName)
        if not marker then
            marker = Instance.new("Part")
            marker.Name = markerName
            marker.Parent = sceneryFolder
        end

        marker.Anchored     = true
        marker.CanCollide   = false
        marker.CanTouch     = false
        marker.CanQuery     = false
        marker.Transparency = 1
        marker.Size         = Vector3.new(30, 20, 30)
        marker.Position     = Vector3.new(sx, center.Y + 10, sz)
        marker:SetAttribute("BoundaryScenery", true)
        marker:SetAttribute("BiomeDressing", true)
        marker:SetAttribute("Decorative", true)
        marker:SetAttribute("ScenicLandmark", true)
        marker:SetAttribute("ReleaseHiddenProceduralVisual", true)
        marker:SetAttribute("InvisibleQueryHelper", true)
    end

    return ringFolder
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Per-biome elevation profiles (additive).
-- Gentle, contiguous height offsets layered ON TOP of the existing flat
-- ZoneTerrain fills so traversal reads as a sculpted landscape rather than a
-- plane.  These are intentionally small (a few studs) so they never lift props
-- past the floating-validation tolerance and never break the documented
-- GroundTopY contract — visible dressing is re-grounded by RegroundPart().
-- amplitude  = peak height (studs) added above the biome's flat top.
-- material   = terrain material used for the sculpted shell.
-- shoreline  = if set, a softer beach/transition material ringed around water.
-- ──────────────────────────────────────────────────────────────────────────────
local BIOME_ELEVATION = {
    NurseryGrove         = { amplitude = 3,  rings = 2,  material = Enum.Material.Grass },
    FernPlains           = { amplitude = 5,  rings = 3,  material = Enum.Material.Grass, shoreline = Enum.Material.Sand },
    JungleBasin          = { amplitude = 7,  rings = 3,  material = Enum.Material.LeafyGrass, basin = true },
    RedstoneCanyon       = { amplitude = 16, rings = 4,  material = Enum.Material.Sandstone, cliffs = true },
    SwampDelta           = { amplitude = 3,  rings = 2,  material = Enum.Material.Mud, shoreline = Enum.Material.Sand, basin = true },
    ApocalypticCity      = { amplitude = 4,  rings = 2,  material = Enum.Material.Asphalt },
}

-- ──────────────────────────────────────────────────────────────────────────────
-- BiomeElevation()
-- Returns a shallow copy of the per-biome elevation profile table so callers
-- (MapLayoutService:EnsureBiomeElevation) can sculpt without reaching into the
-- private upvalue.  Safe to call from test stubs (pure data, no Studio globals).
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.BiomeElevation()
    local result = {}
    for name, profile in pairs(BIOME_ELEVATION) do
        local copy = {}
        for k, v in pairs(profile) do copy[k] = v end
        result[name] = copy
    end
    return result
end

-- ──────────────────────────────────────────────────────────────────────────────
-- SculptBiomeMound(center, footprint, profile)
-- Lays concentric, shrinking terrain blocks above a biome's flat top to create a
-- gentle dome (or, for `basin` profiles, an inverted bowl) plus optional cliff
-- shelving for the canyon/mountain palette.  Idempotent-friendly: re-filling the
-- same terrain volume with the same material is a no-op visually.
-- `center`     Vector3 biome center (post-compact), Y = flat top of biome.
-- `footprint`  Vector3 biome size (X/Z used; Y ignored).
-- Returns the peak Y reached (for callers that want to seat horizon scenery).
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.SculptBiomeMound(center, footprint, profile)
    local Workspace = game:GetService("Workspace")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return center.Y
    end
    profile = profile or {}
    local rings = math.max(1, profile.rings or 2)
    local amplitude = profile.amplitude or 4
    local material = profile.material or Enum.Material.Ground
    local topY = center.Y
    local baseX = math.max(8, footprint.X)
    local baseZ = math.max(8, footprint.Z)

    for ring = 1, rings do
        local t = ring / rings                 -- 0..1 from outer to inner
        local shrink = profile.basin and t or (1 - t * 0.7)
        local ringX = math.max(8, baseX * shrink)
        local ringZ = math.max(8, baseZ * shrink)
        local layerHeight = math.max(2, amplitude / rings + (profile.cliffs and ring * 2 or 0))
        local layerCenterY
        if profile.basin then
            -- Dig downward to read as a bowl/valley floor.
            layerCenterY = topY - layerHeight / 2 - (ring - 1)
        else
            layerCenterY = topY + (ring - 1) * (amplitude / rings) + layerHeight / 2
        end
        terrain:FillBlock(
            CFrame.new(center.X, layerCenterY, center.Z),
            Vector3.new(ringX, layerHeight, ringZ),
            material
        )
    end

    return profile.basin and topY or (topY + amplitude)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- SculptShoreline(waterCenter, waterSize, material)
-- Rings a terrain-water body with a thin sloped band of beach/bank material so
-- the water meets land naturally instead of a hard square edge.  No-op without
-- terrain.  Kept shallow so the water depth contract (<=5 studs) is untouched.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.SculptShoreline(waterCenter, waterSize, material)
    local Workspace = game:GetService("Workspace")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end
    material = material or Enum.Material.Sand
    local bandWidth = 10
    local shoreY = waterCenter.Y - 0.5
    local halfX = waterSize.X / 2
    local halfZ = waterSize.Z / 2
    local offsets = {
        { CFrame.new(waterCenter.X, shoreY, waterCenter.Z + halfZ + bandWidth / 2), Vector3.new(waterSize.X + bandWidth * 2, 2, bandWidth) },
        { CFrame.new(waterCenter.X, shoreY, waterCenter.Z - halfZ - bandWidth / 2), Vector3.new(waterSize.X + bandWidth * 2, 2, bandWidth) },
        { CFrame.new(waterCenter.X + halfX + bandWidth / 2, shoreY, waterCenter.Z), Vector3.new(bandWidth, 2, waterSize.Z) },
        { CFrame.new(waterCenter.X - halfX - bandWidth / 2, shoreY, waterCenter.Z), Vector3.new(bandWidth, 2, waterSize.Z) },
    }
    for _, band in ipairs(offsets) do
        terrain:FillBlock(band[1], band[2], material)
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- RegroundPart(part)
-- Raycast straight down against Terrain and re-seat an already-placed anchored
-- visible part flush on the real (possibly sculpted) surface, then refresh its
-- GroundTopY attribute so PlacementValidationService:ValidateNoFloatingVisibleAssets
-- stays green against the actual terrain height.  No-op when terrain is absent
-- (test stubs) — the part keeps its authored position and declared GroundTopY.
-- Returns the surface Y it was seated on, or nil if no terrain hit.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldBuilderService.RegroundPart(part)
    if not (part and part:IsA("BasePart")) then
        return nil
    end
    local Workspace = game:GetService("Workspace")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return nil
    end

    local startY = 800
    local origin = Vector3.new(part.Position.X, startY, part.Position.Z)
    local direction = Vector3.new(0, -startY - 400, 0)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Include
    rp.FilterDescendantsInstances = { terrain }

    local hit = Workspace:Raycast(origin, direction, rp)
    if not hit then
        return nil
    end

    local surfaceY = hit.Position.Y
    part.Position = Vector3.new(part.Position.X, surfaceY + part.Size.Y / 2, part.Position.Z)
    part:SetAttribute("GroundTopY", surfaceY)
    part:SetAttribute("Regrounded", true)
    return surfaceY
end

-- ──────────────────────────────────────────────────────────────────────────────
-- EnsureSkyAndAtmosphere()
-- Replaces the default skybox with a curated Sky + Atmosphere and sets a calm
-- dawn-ish Lighting mood (per design doc 2.4).  Idempotent: reuses existing
-- instances.  Does NOT touch Lighting:GetAttribute("CurrentWeather") so the
-- WeatherBiomeService rain test is unaffected.  No-op-safe in test stubs.
-- ──────────────────────────────────────────────────────────────────────────────
local SKYBOX_FACE_IDS = {
    -- Roblox built-in high-quality day skybox faces (stable catalog asset ids).
    SkyboxBk = "rbxassetid://150403228",
    SkyboxDn = "rbxassetid://150403261",
    SkyboxFt = "rbxassetid://150403241",
    SkyboxLf = "rbxassetid://150403269",
    SkyboxRt = "rbxassetid://150403251",
    SkyboxUp = "rbxassetid://150403279",
}

function WorldBuilderService.EnsureSkyAndAtmosphere()
    local okLighting, Lighting = pcall(function()
        return game:GetService("Lighting")
    end)
    if not okLighting or not Lighting then
        return nil
    end

    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "EggBreakersSky"
        sky.Parent = Lighting
    end
    for prop, id in pairs(SKYBOX_FACE_IDS) do
        pcall(function()
            sky[prop] = id
        end)
    end
    sky.CelestialBodiesShown = true
    sky.StarCount = 3000

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "EggBreakersAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.32
    atmosphere.Offset = 0.1
    atmosphere.Color = Color3.fromRGB(199, 199, 199)
    atmosphere.Decay = Color3.fromRGB(106, 112, 125)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 1.6

    -- Calm dawn mood (does not assert over weather state).
    Lighting.ClockTime = 7.5
    Lighting.GeographicLatitude = 12
    Lighting.Brightness = 2.4
    Lighting.ExposureCompensation = 0.1
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 122, 130)
    Lighting.Ambient = Color3.fromRGB(70, 70, 78)
    Lighting:SetAttribute("EggBreakersSkyApplied", true)

    return sky
end

return WorldBuilderService
