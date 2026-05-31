--!strict
-- ──────────────────────────────────────────────────────────────────────────────
-- WorldDressingService  [ADDITIVE / NOT WIRED INTO ServerMain]
--
-- A reusable placement engine. The leader feeds in already-sourced asset Models
-- (e.g. imported trees, rocks, props) and this service scatters clones of them
-- around a biome center, grounds each clone onto Terrain/parts via raycast so
-- nothing floats, randomizes yaw + adds slight scale jitter, tags each clone for
-- discoverability, and parents them under Workspace.Map.BiomeDressing.<biomeId>.
--
-- Design notes:
--   * Biome centers come from MapLayoutService:BiomeCenters() (a dict
--     {biomeId -> Vector3}). When that service / Terrain is unavailable the
--     engine degrades to a no-op (or to opts.center) rather than erroring, so it
--     stays test-safe when the world has not populated.
--   * Determinism: pass opts.seed to get a repeatable scatter. We use a tiny LCG
--     instead of math.random at module scope so concurrent callers never share
--     or mutate global RNG state.
--   * Scripts are stripped from every clone (visual dressing only).
--
-- API:
--   WorldDressingService:DressBiome(biomeId, sourceModel, opts) -> {Model}
--   WorldDressingService:ClearBiome(biomeId)                    -> boolean
--   WorldDressingService.DressingPlan                           -> per-biome defaults
-- ──────────────────────────────────────────────────────────────────────────────

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local WorldDressingService = {}

-- ── Tunable defaults the leader can edit per biome ──────────────────────────────
-- count  = how many clones to scatter
-- radius = horizontal scatter radius (studs) around the biome center
WorldDressingService.DressingPlan = {
    NurseryGrove      = { count = 24, radius = 220 },
    FernPlains        = { count = 30, radius = 320 },
    RiverDelta        = { count = 18, radius = 240 },
    RedwoodForest     = { count = 36, radius = 300 },
    VolcanicBadlands  = { count = 14, radius = 280 },
    CoastalCliffs     = { count = 16, radius = 260 },
    -- Fallback used when a biomeId is not listed above:
    __default         = { count = 20, radius = 250 },
}

local DRESSING_TAG = "BiomeDressing"
local VISIBLE_TAG = "ImportedVisibleAsset"

local RAY_UP = 500      -- start the ground ray this far above the sampled point
local RAY_DOWN = 4000   -- and cast this far down to find ground
local SCALE_JITTER = 0.15 -- +/- fraction of scale variation

-- ── Tiny deterministic LCG (numerical recipes constants) ────────────────────────
-- Returns a closure yielding floats in [0,1). Never touches the global RNG.
local function makeRng(seed: number?)
    local state = (seed or os.clock() * 1e6) % 2147483647
    state = math.floor(state)
    if state <= 0 then
        state = state + 2147483646
    end
    return function(): number
        state = (state * 48271) % 2147483647
        return state / 2147483647
    end
end

-- ── Safe lookups (no error when world / services absent) ────────────────────────
local function tryRequireMapLayout()
    local servicesFolder = ServerScriptService:FindFirstChild("Services")
    if not servicesFolder then
        return nil
    end
    local moduleScript = servicesFolder:FindFirstChild("MapLayoutService")
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getBiomeCenter(biomeId: string, opts): Vector3?
    -- Explicit override always wins.
    if opts and typeof(opts.center) == "Vector3" then
        return opts.center
    end
    local mapLayout = tryRequireMapLayout()
    if not mapLayout or type(mapLayout.BiomeCenters) ~= "function" then
        return nil
    end
    local ok, centers = pcall(function()
        return mapLayout:BiomeCenters()
    end)
    if not ok or type(centers) ~= "table" then
        return nil
    end
    local center = centers[biomeId]
    if typeof(center) == "Vector3" then
        return center
    end
    return nil
end

local function getMapFolder(): Instance?
    return Workspace:FindFirstChild("Map")
end

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

-- Removes any Script/LocalScript/ModuleScript descendants from a clone so dressing
-- is purely visual and can never inject behaviour.
local function stripScripts(model: Instance)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") then
            descendant:Destroy()
        end
    end
end

-- Returns the model's pivot CFrame regardless of whether it is a Model/BasePart.
local function getPivot(instance: Instance): CFrame
    if instance:IsA("Model") then
        return instance:GetPivot()
    elseif instance:IsA("BasePart") then
        return instance.CFrame
    end
    return CFrame.new()
end

local function setPivot(instance: Instance, cf: CFrame)
    if instance:IsA("Model") then
        instance:PivotTo(cf)
    elseif instance:IsA("BasePart") then
        instance.CFrame = cf
    end
end

-- Raycasts straight down to find ground (Terrain or parts), ignoring the clone
-- and any existing dressing. Returns the ground Y, or nil if nothing is hit.
local function groundY(x: number, z: number, topY: number, ignore: { Instance }): number?
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local origin = Vector3.new(x, topY + RAY_UP, z)
    local result = Workspace:Raycast(origin, Vector3.new(0, -(RAY_DOWN + RAY_UP), 0), params)
    if result then
        return result.Position.Y
    end
    return nil
end

-- ──────────────────────────────────────────────────────────────────────────────
-- DressBiome(biomeId, sourceModel, opts) -> { clones }
--   opts = {
--     count   : number?   -- overrides DressingPlan
--     radius  : number?   -- overrides DressingPlan
--     center  : Vector3?  -- overrides MapLayoutService center
--     seed    : number?   -- deterministic scatter
--     scaleJitter : number? -- +/- fraction, default SCALE_JITTER
--     reDress : boolean?  -- clear existing folder first (default true)
--   }
-- Returns the list of placed clones (empty when no-op).
-- ──────────────────────────────────────────────────────────────────────────────
function WorldDressingService:DressBiome(biomeId: string, sourceModel: Instance?, opts)
    opts = opts or {}
    local placed: { Instance } = {}

    -- Validate inputs early; never error.
    if type(biomeId) ~= "string" or biomeId == "" then
        warn("[WorldDressingService] DressBiome: invalid biomeId")
        return placed
    end
    if not sourceModel or not (sourceModel:IsA("Model") or sourceModel:IsA("BasePart")) then
        warn(string.format("[WorldDressingService] DressBiome(%s): sourceModel is not a Model/BasePart", biomeId))
        return placed
    end

    local plan = self.DressingPlan[biomeId] or self.DressingPlan.__default
    local count = opts.count or plan.count
    local radius = opts.radius or plan.radius
    local jitter = opts.scaleJitter or SCALE_JITTER

    if count <= 0 or radius <= 0 then
        return placed
    end

    local center = getBiomeCenter(biomeId, opts)
    if not center then
        -- World / MapLayoutService unavailable and no opts.center supplied: no-op.
        warn(string.format("[WorldDressingService] DressBiome(%s): no biome center available; skipping", biomeId))
        return placed
    end

    local mapFolder = getMapFolder()
    if not mapFolder then
        warn("[WorldDressingService] DressBiome: Workspace.Map missing; skipping")
        return placed
    end

    -- Idempotent re-dress unless explicitly disabled.
    if opts.reDress ~= false then
        self:ClearBiome(biomeId)
    end

    local dressingRoot = getOrCreateFolder(mapFolder, "BiomeDressing")
    local biomeFolder = getOrCreateFolder(dressingRoot, biomeId)

    local rng = makeRng(opts.seed)
    local topY = center.Y

    for i = 1, count do
        -- Uniform disc sampling: sqrt to avoid center clustering.
        local angle = rng() * math.pi * 2
        local dist = math.sqrt(rng()) * radius
        local x = center.X + math.cos(angle) * dist
        local z = center.Z + math.sin(angle) * dist

        local clone = sourceModel:Clone()
        stripScripts(clone)

        -- Resolve ground height, ignoring clone + already-placed dressing + the
        -- dressing root so trees never stack on each other.
        local ignore = { clone, biomeFolder }
        local y = groundY(x, z, topY, ignore)
        if not y then
            -- No ground found (e.g. Terrain absent): drop on the biome plane.
            y = topY
        end

        -- Randomize yaw + apply slight uniform scale jitter.
        local yaw = rng() * math.pi * 2
        local scale = 1 + (rng() * 2 - 1) * jitter

        if clone:IsA("Model") then
            pcall(function()
                clone:ScaleTo(scale)
            end)
        end

        -- Anchor the placement so dressing never falls or drifts.
        if clone:IsA("BasePart") then
            clone.Anchored = true
        else
            for _, descendant in ipairs(clone:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Anchored = true
                end
            end
        end

        local placement = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
        setPivot(clone, placement)

        clone:SetAttribute("BiomeId", biomeId)
        CollectionService:AddTag(clone, DRESSING_TAG)
        CollectionService:AddTag(clone, VISIBLE_TAG)

        clone.Parent = biomeFolder
        table.insert(placed, clone)
    end

    biomeFolder:SetAttribute("DressedCount", #placed)
    biomeFolder:SetAttribute("DressedAt", os.time())

    return placed
end

-- ──────────────────────────────────────────────────────────────────────────────
-- ClearBiome(biomeId) -> boolean
--   Removes this biome's dressing folder. Idempotent: returns false (no error)
--   when the folder / world is absent. Enables clean re-dressing.
-- ──────────────────────────────────────────────────────────────────────────────
function WorldDressingService:ClearBiome(biomeId: string): boolean
    if type(biomeId) ~= "string" or biomeId == "" then
        return false
    end
    local mapFolder = getMapFolder()
    if not mapFolder then
        return false
    end
    local dressingRoot = mapFolder:FindFirstChild("BiomeDressing")
    if not dressingRoot then
        return false
    end
    local biomeFolder = dressingRoot:FindFirstChild(biomeId)
    if not biomeFolder then
        return false
    end
    biomeFolder:Destroy()
    return true
end

return WorldDressingService
