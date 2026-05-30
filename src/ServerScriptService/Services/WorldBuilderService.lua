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

return WorldBuilderService
