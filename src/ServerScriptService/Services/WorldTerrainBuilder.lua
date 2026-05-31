--!strict
-- WorldTerrainBuilder.lua
-- A Terrain-sculpting helper the leader runs to build water biomes.
--
-- All operations are additive, guarded (no error if Terrain is absent), and
-- deterministic (no randomness, no time-dependence). NOTHING runs at module
-- scope -- the leader must explicitly call the API.
--
-- API:
--   :SetSeaLevel(n)                              -> set the sea-level Y used by water carving
--   :Lake(center, radius, depth)                 -> circular water lake (cylinder down from sea level)
--   :Pond(center, radius, depth)                 -> small lake
--   :River(points, width, depth)                 -> water along a polyline
--   :Beach(center, radius)                       -> sand ring around a point
--   :PaintBiome(biomeId, opts)                   -> repaint terrain material in a biome disc
--   :PaintAllBiomes()                            -> paint every known biome
--
-- Fields:
--   .SeaLevel : number (default 34)
--   .BiomeCenters : { [string]: Vector3 }
--   .BiomePalette : { [string]: Enum.Material }

local WorldTerrainBuilder = {}
WorldTerrainBuilder.__index = WorldTerrainBuilder

-- Default sea level (studs, world Y). Water is filled DOWN from here.
WorldTerrainBuilder.SeaLevel = 34

-- Canonical biome centers (world position). Sourced from the project spec.
WorldTerrainBuilder.BiomeCenters = {
	NurseryGrove = Vector3.new(-2000, 0, 0),
	FernPlains = Vector3.new(-1575, 0, 0),
	JungleBasin = Vector3.new(-1725, 0, 475),
	SwampDelta = Vector3.new(-1075, 0, 475),
	RedstoneCanyon = Vector3.new(-1100, 0, -325),
	ApocalypticCity = Vector3.new(-650, 0, 0),
}

-- Surface material each biome should be painted with.
-- (Materials chosen to read as the biome's ground; reddish/cracked use the
-- closest stock Terrain materials.)
WorldTerrainBuilder.BiomePalette = {
	NurseryGrove = Enum.Material.LeafyGrass,
	FernPlains = Enum.Material.Grass,
	JungleBasin = Enum.Material.LeafyGrass,
	SwampDelta = Enum.Material.Mud,
	RedstoneCanyon = Enum.Material.Sandstone,
	ApocalypticCity = Enum.Material.Slate,
}

-- Default disc radius (studs) per biome paint pass.
WorldTerrainBuilder.BiomePaintRadius = 200

-- ----------------------------------------------------------------------------
-- Internal helpers
-- ----------------------------------------------------------------------------

-- Safely resolve the Terrain instance. Returns nil if absent (test/headless).
local function getTerrain(): Terrain?
	local Workspace = game and game:GetService("Workspace")
	if not Workspace then
		return nil
	end
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		-- Workspace.Terrain is a property on live games; guard it too.
		local ok, t = pcall(function()
			return Workspace.Terrain
		end)
		if ok then
			terrain = t
		end
	end
	return terrain
end

local function num(value: any, fallback: number): number
	if type(value) == "number" and value == value then -- reject NaN
		return value
	end
	return fallback
end

local function isVector3(v: any): boolean
	return typeof(v) == "Vector3"
end

-- ----------------------------------------------------------------------------
-- Water carving primitives
-- ----------------------------------------------------------------------------

-- Fill a vertical water cylinder centered at (center.X, center.Z), spanning
-- from SeaLevel down by `depth`. `radius` is the cylinder radius.
local function fillWaterCylinder(self, terrain: Terrain, centerX: number, centerZ: number, radius: number, depth: number)
	radius = math.max(num(radius, 1), 0.5)
	depth = math.max(num(depth, 1), 0.5)

	local seaLevel = num(self.SeaLevel, WorldTerrainBuilder.SeaLevel)
	local topY = seaLevel
	local centerY = topY - depth * 0.5

	-- FillCylinder takes a CFrame (cylinder axis = local Y by default in Roblox),
	-- a height along that axis, a radius, and a material.
	-- We orient the cylinder upright so its axis is world-Y.
	local cf = CFrame.new(centerX, centerY, centerZ)
	pcall(function()
		terrain:FillCylinder(cf, depth, radius, Enum.Material.Water)
	end)
end

-- ----------------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------------

function WorldTerrainBuilder:SetSeaLevel(n: number)
	self.SeaLevel = num(n, WorldTerrainBuilder.SeaLevel)
	return self.SeaLevel
end

-- Carve a circular water lake: a water cylinder dropped from sea level.
function WorldTerrainBuilder:Lake(center: Vector3, radius: number, depth: number)
	local terrain = getTerrain()
	if not terrain or not isVector3(center) then
		return false
	end
	fillWaterCylinder(self, terrain, center.X, center.Z, num(radius, 32), num(depth, 12))
	return true
end

-- A small lake. Same shape, smaller defaults.
function WorldTerrainBuilder:Pond(center: Vector3, radius: number, depth: number)
	local terrain = getTerrain()
	if not terrain or not isVector3(center) then
		return false
	end
	fillWaterCylinder(self, terrain, center.X, center.Z, num(radius, 10), num(depth, 6))
	return true
end

-- Water along a polyline. For each consecutive pair of points we fill a
-- cylinder at each endpoint (rounded ends) and a block spanning the segment.
function WorldTerrainBuilder:River(points: { Vector3 }, width: number, depth: number)
	local terrain = getTerrain()
	if not terrain or type(points) ~= "table" or #points < 2 then
		return false
	end

	width = math.max(num(width, 12), 1)
	depth = math.max(num(depth, 8), 0.5)
	local radius = width * 0.5
	local seaLevel = num(self.SeaLevel, WorldTerrainBuilder.SeaLevel)
	local centerY = seaLevel - depth * 0.5

	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		if isVector3(a) and isVector3(b) then
			-- Flatten to sea-level plane for a consistent water surface.
			local ax, az = a.X, a.Z
			local bx, bz = b.X, b.Z

			-- Rounded joint at the start point.
			fillWaterCylinder(self, terrain, ax, az, radius, depth)

			-- Block spanning the segment in the XZ plane.
			local dx = bx - ax
			local dz = bz - az
			local length = math.sqrt(dx * dx + dz * dz)
			if length > 1e-3 then
				local midX = (ax + bx) * 0.5
				local midZ = (az + bz) * 0.5
				local angle = math.atan2(dz, dx)
				-- Orient block so its X axis runs along the segment.
				local cf = CFrame.new(midX, centerY, midZ)
					* CFrame.Angles(0, -angle, 0)
				local size = Vector3.new(length, depth, width)
				pcall(function()
					terrain:FillBlock(cf, size, Enum.Material.Water)
				end)
			end
		end
	end

	-- Rounded joint at the final point.
	local last = points[#points]
	if isVector3(last) then
		fillWaterCylinder(self, terrain, last.X, last.Z, radius, depth)
	end

	return true
end

-- A sand ring around a point, sitting at sea level. Uses a flat sand
-- cylinder (a disc) so it reads as a beach edge.
function WorldTerrainBuilder:Beach(center: Vector3, radius: number)
	local terrain = getTerrain()
	if not terrain or not isVector3(center) then
		return false
	end

	radius = math.max(num(radius, 24), 1)
	local seaLevel = num(self.SeaLevel, WorldTerrainBuilder.SeaLevel)
	-- Thin sand disc straddling the waterline.
	local thickness = 4
	local cf = CFrame.new(center.X, seaLevel - thickness * 0.5, center.Z)
	pcall(function()
		terrain:FillCylinder(cf, thickness, radius, Enum.Material.Sand)
	end)
	return true
end

-- ----------------------------------------------------------------------------
-- Biome surface painting
-- ----------------------------------------------------------------------------

-- Repaint the Terrain ground material inside a biome's disc to match the biome.
--
-- Paints a vertical column above sea level (a tall cylinder) using
-- ReplaceMaterial so that ONLY existing solid terrain is recolored -- air stays
-- air, and water below sea level is untouched. This is additive (no new mass)
-- and deterministic.
--
-- biomeId : string key into BiomeCenters / BiomePalette, OR a Vector3 center.
-- opts    : optional table {
--             center   = Vector3,        -- override center
--             radius   = number,         -- disc radius (default BiomePaintRadius)
--             material = Enum.Material,   -- override target material
--             height   = number,         -- column height above sea level (default 120)
--             below    = number,         -- studs below sea level to include (default 8)
--           }
function WorldTerrainBuilder:PaintBiome(biomeId: any, opts: any?)
	local terrain = getTerrain()
	if not terrain then
		return false
	end

	opts = (type(opts) == "table") and opts or {}

	-- Resolve center.
	local center: Vector3? = nil
	if isVector3(opts.center) then
		center = opts.center
	elseif isVector3(biomeId) then
		center = biomeId
	elseif type(biomeId) == "string" then
		center = WorldTerrainBuilder.BiomeCenters[biomeId]
	end
	if not isVector3(center) then
		return false
	end

	-- Resolve target material.
	local material: Enum.Material? = nil
	if typeof(opts.material) == "EnumItem" then
		material = opts.material
	elseif type(biomeId) == "string" then
		material = WorldTerrainBuilder.BiomePalette[biomeId]
	end
	if typeof(material) ~= "EnumItem" then
		material = Enum.Material.Grass
	end

	local radius = math.max(num(opts.radius, WorldTerrainBuilder.BiomePaintRadius), 1)
	local height = math.max(num(opts.height, 120), 1)
	local below = math.max(num(opts.below, 8), 0)
	local seaLevel = num(self.SeaLevel, WorldTerrainBuilder.SeaLevel)

	-- Column spans from (seaLevel - below) up to (seaLevel + height).
	local bottomY = seaLevel - below
	local topY = seaLevel + height
	local spanY = topY - bottomY
	local centerY = (bottomY + topY) * 0.5

	-- ReplaceMaterial only swaps occupied voxels of any existing material to the
	-- biome material -- it does not create terrain. We bound it to the biome
	-- disc via a region cube; the disc shape is honored by ReplaceMaterial only
	-- operating on a box region, so we additionally fall back to a cylinder fill
	-- guard below if ReplaceMaterial is unavailable.
	local minV = Vector3.new(center.X - radius, bottomY, center.Z - radius)
	local maxV = Vector3.new(center.X + radius, topY, center.Z + radius)

	local replaced = false
	pcall(function()
		local region = Region3.new(minV, maxV):ExpandToGrid(4)
		-- Replace every non-air, non-water material in the region with the
		-- biome material. SwampDelta keeps its water because Water is excluded.
		for _, src in ipairs({
			Enum.Material.Grass,
			Enum.Material.LeafyGrass,
			Enum.Material.Ground,
			Enum.Material.Mud,
			Enum.Material.Sand,
			Enum.Material.Sandstone,
			Enum.Material.Rock,
			Enum.Material.Slate,
			Enum.Material.Asphalt,
			Enum.Material.Snow,
			Enum.Material.Basalt,
			Enum.Material.CrackedLava,
			Enum.Material.Limestone,
			Enum.Material.Pavement,
			Enum.Material.Cobblestone,
		}) do
			if src ~= material then
				terrain:ReplaceMaterial(region, 4, src, material)
			end
		end
		replaced = true
	end)

	if not replaced then
		-- Fallback for environments without ReplaceMaterial: lay a thin solid
		-- disc of the biome material straddling sea level. Still additive and
		-- deterministic; never touches water below.
		local thickness = math.min(spanY, 8)
		local cf = CFrame.new(center.X, seaLevel + thickness * 0.5, center.Z)
		pcall(function()
			terrain:FillCylinder(cf, thickness, radius, material)
		end)
	end

	return true
end

-- Paint every known biome with its palette material. Returns the count of
-- biomes successfully painted.
function WorldTerrainBuilder:PaintAllBiomes(opts: any?)
	local painted = 0
	-- Deterministic order so repeated runs behave identically.
	local order = {
		"NurseryGrove",
		"FernPlains",
		"JungleBasin",
		"SwampDelta",
		"RedstoneCanyon",
		"ApocalypticCity",
	}
	for _, biomeId in ipairs(order) do
		if self:PaintBiome(biomeId, opts) then
			painted += 1
		end
	end
	return painted
end

return WorldTerrainBuilder
