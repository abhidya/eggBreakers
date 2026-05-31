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
--
-- Fields:
--   .SeaLevel : number (default 34)

local WorldTerrainBuilder = {}
WorldTerrainBuilder.__index = WorldTerrainBuilder

-- Default sea level (studs, world Y). Water is filled DOWN from here.
WorldTerrainBuilder.SeaLevel = 34

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

return WorldTerrainBuilder
