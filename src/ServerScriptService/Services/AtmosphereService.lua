--!strict
-- AtmosphereService
-- Sets up a natural-looking sky/atmosphere/lighting environment for the world.
--
-- Design notes:
--   * Pure module. Does NOT auto-run at require time. Call AtmosphereService:Apply(...)
--     from the leader's wiring (e.g. ServerMain) when the world populates on Play.
--   * Idempotent: re-calling :Apply() reuses (and re-tunes) the same Lighting children
--     instead of duplicating them. Safe to call multiple times.
--   * Guarded: every Instance.new / property write is wrapped in pcall so a hostile
--     or partially-initialized Lighting state can never hard-crash the server boot.
--   * SetBiomeMood(biomeId) lightly nudges fog/atmosphere color for per-biome feel
--     without tearing down the base setup.
--
-- Tags every instance it owns with an Attribute so we can find/reuse our own objects
-- and never clobber instances another system may have created.

local Lighting = game:GetService("Lighting")

local AtmosphereService = {}
AtmosphereService.__index = AtmosphereService

-- Attribute marker stamped on every instance this service owns.
local OWNED_ATTR = "AtmosphereService_Owned"

-- Default base config (warm mid-afternoon look).
local DEFAULTS = {
	ClockTime = 14,
	Brightness = 2.4,
	ExposureCompensation = 0.15,
	OutdoorAmbient = Color3.fromRGB(120, 125, 130),
	Ambient = Color3.fromRGB(70, 70, 75),
	GeographicLatitude = 41.733,
	-- Atmosphere
	AtmosphereDensity = 0.22,
	AtmosphereOffset = 0.25,
	AtmosphereHaze = 0.65,
	AtmosphereColor = Color3.fromRGB(214, 219, 211),
	AtmosphereDecay = Color3.fromRGB(112, 124, 112),
	-- ColorCorrection
	CCBrightness = 0.02,
	CCContrast = 0.06,
	CCSaturation = 0.18,
	CCTintColor = Color3.fromRGB(255, 250, 244),
	-- Bloom (subtle)
	BloomIntensity = 0.55,
	BloomSize = 24,
	BloomThreshold = 1.6,
}

-- Per-biome mood adjustments. Lightly tweaks fog/atmosphere color + density and
-- the color-correction tint. Values are deltas/overrides applied on top of the
-- current base. Unknown biomeIds fall back to "default".
local BIOME_MOODS = {
	default = {
		AtmosphereColor = Color3.fromRGB(214, 219, 211),
		AtmosphereDecay = Color3.fromRGB(112, 124, 112),
		AtmosphereDensity = 0.22,
		AtmosphereHaze = 0.65,
		CCTintColor = Color3.fromRGB(255, 250, 244),
	},
	forest = {
		AtmosphereColor = Color3.fromRGB(180, 205, 185),
		AtmosphereDecay = Color3.fromRGB(92, 110, 96),
		AtmosphereDensity = 0.25,
		AtmosphereHaze = 0.8,
		CCTintColor = Color3.fromRGB(244, 252, 244),
	},
	jungle = {
		AtmosphereColor = Color3.fromRGB(172, 204, 178),
		AtmosphereDecay = Color3.fromRGB(80, 104, 86),
		AtmosphereDensity = 0.28,
		AtmosphereHaze = 0.95,
		CCTintColor = Color3.fromRGB(240, 252, 242),
	},
	desert = {
		AtmosphereColor = Color3.fromRGB(232, 214, 178),
		AtmosphereDecay = Color3.fromRGB(150, 128, 92),
		AtmosphereDensity = 0.20,
		AtmosphereHaze = 0.55,
		CCTintColor = Color3.fromRGB(255, 248, 232),
	},
	swamp = {
		AtmosphereColor = Color3.fromRGB(168, 188, 176),
		AtmosphereDecay = Color3.fromRGB(78, 96, 88),
		AtmosphereDensity = 0.32,
		AtmosphereHaze = 1.15,
		CCTintColor = Color3.fromRGB(238, 246, 240),
	},
	tundra = {
		AtmosphereColor = Color3.fromRGB(206, 220, 235),
		AtmosphereDecay = Color3.fromRGB(120, 134, 152),
		AtmosphereDensity = 0.20,
		AtmosphereHaze = 0.6,
		CCTintColor = Color3.fromRGB(246, 250, 255),
	},
	volcanic = {
		AtmosphereColor = Color3.fromRGB(214, 188, 178),
		AtmosphereDecay = Color3.fromRGB(132, 96, 86),
		AtmosphereDensity = 0.26,
		AtmosphereHaze = 0.85,
		CCTintColor = Color3.fromRGB(255, 242, 236),
	},
	ocean = {
		AtmosphereColor = Color3.fromRGB(188, 210, 230),
		AtmosphereDecay = Color3.fromRGB(96, 118, 140),
		AtmosphereDensity = 0.22,
		AtmosphereHaze = 0.75,
		CCTintColor = Color3.fromRGB(244, 250, 255),
	},
}

-- ---------------------------------------------------------------------------
-- Internal helpers (all guarded)
-- ---------------------------------------------------------------------------

local function safeSet(inst: Instance, prop: string, value: any)
	if not inst then
		return
	end
	pcall(function()
		(inst :: any)[prop] = value
	end)
end

-- Find a child of `parent` of `className` that we previously created (marked with
-- OWNED_ATTR). If none exists, create one, stamp it, and parent it. Idempotent.
local function ensureChild(parent: Instance, className: string, name: string): Instance?
	if not parent then
		return nil
	end

	local found: Instance? = nil
	local okChildren, children = pcall(function()
		return parent:GetChildren()
	end)
	if okChildren and children then
		for _, child in ipairs(children) do
			local isClass = false
			pcall(function()
				isClass = child:IsA(className)
			end)
			if isClass then
				local owned = false
				pcall(function()
					owned = child:GetAttribute(OWNED_ATTR) == true
				end)
				-- Reuse if it's ours, OR if it matches by name (adopt a pre-existing
				-- one so we never create a duplicate of a singleton effect).
				if owned or child.Name == name then
					found = child
					break
				end
			end
		end
	end

	if not found then
		local okNew, created = pcall(function()
			return Instance.new(className)
		end)
		if okNew and created then
			found = created
		else
			return nil
		end
	end

	safeSet(found :: Instance, "Name", name)
	pcall(function()
		(found :: Instance):SetAttribute(OWNED_ATTR, true)
	end)
	pcall(function()
		(found :: Instance).Parent = parent
	end)

	return found
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Apply the base lighting/atmosphere setup.
-- @param config (optional table) overrides for any DEFAULTS key, plus:
--        SkyTextureSet: optional table of skybox face texture asset ids:
--          { Up=, Down=, Left=, Right=, Front=, Back=, Sun=, Moon=, StarCount= }
--        If SkyTextureSet is omitted/empty, the existing/default sky is left alone.
--        biomeId: optional initial biome mood to apply after base setup.
function AtmosphereService:Apply(config: { [string]: any }?)
	config = config or {}
	local cfg: { [string]: any } = config :: any

	local function pick(key: string): any
		local v = cfg[key]
		if v ~= nil then
			return v
		end
		return DEFAULTS[key]
	end

	-- 1) Core Lighting properties -------------------------------------------
	safeSet(Lighting, "Technology", Enum.Technology.Future)
	safeSet(Lighting, "ClockTime", pick("ClockTime"))
	safeSet(Lighting, "Brightness", pick("Brightness"))
	safeSet(Lighting, "ExposureCompensation", pick("ExposureCompensation"))
	safeSet(Lighting, "OutdoorAmbient", pick("OutdoorAmbient"))
	safeSet(Lighting, "Ambient", pick("Ambient"))
	safeSet(Lighting, "GeographicLatitude", pick("GeographicLatitude"))
	safeSet(Lighting, "GlobalShadows", true)
	safeSet(Lighting, "EnvironmentDiffuseScale", 1)
	safeSet(Lighting, "EnvironmentSpecularScale", 1)
	-- Clear any legacy uniform fog so Atmosphere is what shapes depth.
	safeSet(Lighting, "FogEnd", 1e9)

	-- 2) Atmosphere (depth + haze) ------------------------------------------
	local atmosphere = ensureChild(Lighting, "Atmosphere", "Atmosphere")
	if atmosphere then
		safeSet(atmosphere, "Density", pick("AtmosphereDensity"))
		safeSet(atmosphere, "Offset", pick("AtmosphereOffset"))
		safeSet(atmosphere, "Haze", pick("AtmosphereHaze"))
		safeSet(atmosphere, "Color", pick("AtmosphereColor"))
		safeSet(atmosphere, "Decay", pick("AtmosphereDecay"))
		safeSet(atmosphere, "Glare", 0.2)
	end

	-- 3) ColorCorrection -----------------------------------------------------
	local cc = ensureChild(Lighting, "ColorCorrectionEffect", "AtmosphereColorCorrection")
	if cc then
		safeSet(cc, "Brightness", pick("CCBrightness"))
		safeSet(cc, "Contrast", pick("CCContrast"))
		safeSet(cc, "Saturation", pick("CCSaturation"))
		safeSet(cc, "TintColor", pick("CCTintColor"))
		safeSet(cc, "Enabled", true)
	end

	-- 4) Bloom (subtle) ------------------------------------------------------
	local bloom = ensureChild(Lighting, "BloomEffect", "AtmosphereBloom")
	if bloom then
		safeSet(bloom, "Intensity", pick("BloomIntensity"))
		safeSet(bloom, "Size", pick("BloomSize"))
		safeSet(bloom, "Threshold", pick("BloomThreshold"))
		safeSet(bloom, "Enabled", true)
	end

	-- 5) Sky / skybox (only if a texture set is provided) --------------------
	local skySet = cfg.SkyTextureSet
	if type(skySet) == "table" and next(skySet) ~= nil then
		local sky = ensureChild(Lighting, "Sky", "Sky")
		if sky then
			local function face(prop: string, key: string)
				if skySet[key] ~= nil then
					safeSet(sky, prop, skySet[key])
				end
			end
			face("SkyboxUp", "Up")
			face("SkyboxDn", "Down")
			face("SkyboxLf", "Left")
			face("SkyboxRt", "Right")
			face("SkyboxFt", "Front")
			face("SkyboxBk", "Back")
			face("SunTextureId", "Sun")
			face("MoonTextureId", "Moon")
			if skySet.StarCount ~= nil then
				safeSet(sky, "StarCount", skySet.StarCount)
			end
			safeSet(sky, "CelestialBodiesShown", true)
		end
	end
	-- If no SkyTextureSet: leave the default procedural/inherited sky untouched.

	-- 6) Optional initial biome mood ----------------------------------------
	if cfg.biomeId ~= nil then
		self:SetBiomeMood(cfg.biomeId)
	end

	return self
end

-- Lightly adjust fog/atmosphere color + the color-correction tint for a biome.
-- Does NOT recreate the base setup; only nudges the existing owned instances.
-- Safe to call before :Apply() (it will create the atmosphere/cc if missing).
function AtmosphereService:SetBiomeMood(biomeId: string?)
	local key = "default"
	if type(biomeId) == "string" then
		local lowered = string.lower(biomeId)
		if BIOME_MOODS[lowered] then
			key = lowered
		end
	end
	local mood = BIOME_MOODS[key]
	if not mood then
		return self
	end

	local atmosphere = ensureChild(Lighting, "Atmosphere", "Atmosphere")
	if atmosphere then
		if mood.AtmosphereColor then
			safeSet(atmosphere, "Color", mood.AtmosphereColor)
		end
		if mood.AtmosphereDecay then
			safeSet(atmosphere, "Decay", mood.AtmosphereDecay)
		end
		if mood.AtmosphereDensity then
			safeSet(atmosphere, "Density", mood.AtmosphereDensity)
		end
		if mood.AtmosphereHaze then
			safeSet(atmosphere, "Haze", mood.AtmosphereHaze)
		end
	end

	local cc = ensureChild(Lighting, "ColorCorrectionEffect", "AtmosphereColorCorrection")
	if cc and mood.CCTintColor then
		safeSet(cc, "TintColor", mood.CCTintColor)
	end

	return self
end

-- Remove every instance this service owns (marked with OWNED_ATTR). Useful for
-- teardown between play sessions / hot-reload. Guarded.
function AtmosphereService:Clear()
	local okChildren, children = pcall(function()
		return Lighting:GetChildren()
	end)
	if okChildren and children then
		for _, child in ipairs(children) do
			local owned = false
			pcall(function()
				owned = child:GetAttribute(OWNED_ATTR) == true
			end)
			if owned then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
	return self
end

return AtmosphereService
