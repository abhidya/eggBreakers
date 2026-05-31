--!strict
-- SpeciesRoster.lua
--
-- Generates SpeciesConfig-compatible entries for the FULL staged roster so that
-- every staged dinosaur under Workspace.dinosaur becomes a playable species.
--
-- The eight curated playable species keep their hand-tuned entries in
-- SpeciesConfig.lua. This module supplies a SpeciesConfig-shaped entry for every
-- OTHER staged species, generated from a STATIC name+diet-folder list so config
-- generation is fully world-absent safe (no live Workspace required, e.g. headless
-- tests). Diet is derived from the diet folder. Aquatic -> Carnivore + aquatic flag.
--
-- The static StagedSpecies list mirrors the real Workspace.dinosaur contents,
-- de-duplicated by normalized id (duplicate rigs / parenthetical variants collapse
-- to one playable species). Exact spelling is NOT load-bearing for runtime visuals:
-- StagedMeshLibrary:ResolveAny resolves the staged Model by a normalized name match
-- against the live folders, and :BuildFromWorkspace below can reconcile against the
-- authoritative live names at runtime.
--
-- Diet folder counts (raw models): Herbivores (land)=16, Carnivores (land)=28,
-- Omnivores(land)=4, Aquatic=8 (=56 rigs). After normalized de-duplication the
-- distinct playable roster is 48 staged species (12 + 25 + 3 + 8). Note numbered
-- variants like "Spinosaurus2"/"Tyrannosaurus2"/"Elasmosaurus2" keep their digit and
-- remain DISTINCT ids; only true duplicate names and (male)/(female)/(Baby) variants
-- collapse.

local SpeciesRoster = {}

SpeciesRoster.GrowthStages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }

SpeciesRoster.DietFolders = {
	Herbivore = "Herbivores (land)",
	Carnivore = "Carnivores (land)",
	Omnivore = "Omnivores(land)",
	Aquatic = "Aquatic",
}

-- Stage multipliers applied to Adult-tier base values (mirror of the curated
-- species' Hatchling -> Adult progression).
local STAGE_SCALE = {
	Hatchling = 0.45,
	Juvenile = 0.65,
	SubAdult = 0.82,
	Adult = 1.0,
}

-- Flyers (normalized ids). Flight=true enables FlightService; FlightStaminaDrain > 0.
local FLYERS = {
	pteranodon = true,
	quetzalcoatlus = true,
	microraptor = true,
	archaeopteryx = true,
	pterosaur = true,
	pterodactyl = true,
	rhamphorhynchus = true,
	dimorphodon = true,
	-- Note: Kelenken / Phorusrhacos are flightless terror birds -> NOT flyers
	-- (ground movement, zero flight-stamina drain).
}

-- Static staged roster: { name = <staged model name>, folder = <diet folder> }.
-- Folder drives Diet. Names mirror the real Workspace.dinosaur models (de-duplicated
-- by normalized id). Counts: H=12, C=25, O=3, A=8 => 48 distinct staged species.
local H = SpeciesRoster.DietFolders.Herbivore
local C = SpeciesRoster.DietFolders.Carnivore
local O = SpeciesRoster.DietFolders.Omnivore
local A = SpeciesRoster.DietFolders.Aquatic

SpeciesRoster.StagedSpecies = {
	-- Herbivores (land) -- 12 distinct (raw 16; Antarctosaurus/Maiasaura dupes collapse)
	{ name = "Antarctosaurus", folder = H },
	{ name = "Deinocherius(old)", folder = H },
	{ name = "Diplodocus", folder = H },
	{ name = "Maiasaura", folder = H },
	{ name = "Olorotitan", folder = H },
	{ name = "Omeisaurus", folder = H },
	{ name = "Parasaurolophus", folder = H },
	{ name = "Plateosaurus", folder = H },
	{ name = "Saurolophus", folder = H },
	{ name = "Stegosaurus", folder = H },
	{ name = "Titanosaurus", folder = H },
	{ name = "Triceratops", folder = H },

	-- Carnivores (land) -- 25 distinct (raw 28; Mapusaurus/Tyrannosaurus dupes collapse)
	{ name = "Abelisaurus", folder = C },
	{ name = "Acrocanthosaurus", folder = C },
	{ name = "Archaeopteryx", folder = C },
	{ name = "Aucasaurus", folder = C },
	{ name = "Carnotaurus", folder = C },
	{ name = "Ceratosaurus", folder = C },
	{ name = "Coelophysis", folder = C },
	{ name = "Concavenator", folder = C },
	{ name = "Deltadromeus", folder = C },
	{ name = "Giganotosaurus", folder = C },
	{ name = "Kelenken", folder = C },
	{ name = "Mapusaurus", folder = C },
	{ name = "Megalosaurus", folder = C },
	{ name = "Microraptor", folder = C },
	{ name = "Phorusrhacos", folder = C },
	{ name = "Quetzalcoatlus", folder = C },
	{ name = "Spinosaurus", folder = C },
	{ name = "Spinosaurus2", folder = C },
	{ name = "Suchomimus", folder = C },
	{ name = "Tarbosaurus", folder = C },
	{ name = "Tyrannosaurus", folder = C },
	{ name = "Tyrannosaurus2", folder = C },
	{ name = "Tyrannotitan", folder = C },
	{ name = "Utahraptor", folder = C },
	{ name = "Yangchuanosaurus", folder = C },

	-- Omnivores(land) -- 3 distinct (raw 4; Citipati male/female collapse)
	{ name = "Citipati (female)", folder = O },
	{ name = "Deinocheirus", folder = O },
	{ name = "Gigantoraptor", folder = O },

	-- Aquatic -- 8 distinct
	{ name = "Archelon", folder = A },
	{ name = "Atopodentatus", folder = A },
	{ name = "Elasmosaurus", folder = A },
	{ name = "Elasmosaurus2", folder = A },
	{ name = "Liopleurodon", folder = A },
	{ name = "Megalodon", folder = A },
	{ name = "Plesiosaurus", folder = A },
	{ name = "Styxosaurus", folder = A },
}

-- Normalize a name to a stable lookup key: lowercase, drop parenthetical qualifiers,
-- strip non-alphanumerics. ("Citipati (male)" -> "citipati", "Maiasaura (Baby)" ->
-- "maiasaura"). Keeps trailing digits so "Spinosaurus2" stays distinct.
local function normalize(name: string): string
	if type(name) ~= "string" then
		return ""
	end
	local s = string.lower(name)
	s = string.gsub(s, "%(.-%)", "")
	s = string.gsub(s, "[^%a%d]", "")
	return s
end
SpeciesRoster.normalize = normalize

local function toSpeciesId(name: string): string
	return normalize(name)
end
SpeciesRoster.toSpeciesId = toSpeciesId

-- Diet + aquatic flag from a diet folder name.
local function dietFromFolder(folder: string): (string, boolean)
	if folder == SpeciesRoster.DietFolders.Aquatic then
		return "Carnivore", true
	elseif folder == SpeciesRoster.DietFolders.Herbivore then
		return "Herbivore", false
	elseif folder == SpeciesRoster.DietFolders.Omnivore then
		return "Omnivore", false
	else
		return "Carnivore", false
	end
end
SpeciesRoster.dietFromFolder = dietFromFolder

-- A SpeciesConfig.stats()-shaped block (same field set the curated species use).
local function statBlock(maxHealth, walkSpeed, sprintSpeed, stamina, hungerDrain, thirstDrain, damage, staminaRegen, maxOxygen, flightDrain)
	return {
		MaxHealth = maxHealth,
		WalkSpeed = walkSpeed,
		SprintSpeed = sprintSpeed,
		MaxStamina = stamina,
		HungerDrain = hungerDrain,
		ThirstDrain = thirstDrain,
		Damage = damage,
		StaminaRegen = staminaRegen,
		MaxOxygen = maxOxygen,
		FlightStaminaDrain = flightDrain,
	}
end

-- Adult-tier defaults per diet/movement tier; other stages scale from these.
-- Returns: maxHealth, walk, sprint, stamina, hungerDrain, thirstDrain, damage,
--          staminaRegen, maxOxygen, flightDrain
local function adultDefaults(diet, isAquatic, isFlyer)
	if isFlyer then
		return 120, 14, 26, 150, 1.1, 1.0, 22, 14, 65, 6
	elseif isAquatic then
		return 230, 14, 24, 160, 1.4, 1.0, 50, 10, 120, 0
	elseif diet == "Herbivore" then
		return 170, 13, 21, 120, 1.0, 1.0, 22, 9, 60, 0
	elseif diet == "Omnivore" then
		return 125, 16, 26, 125, 1.0, 1.0, 20, 12, 60, 0
	else -- Carnivore (land)
		return 200, 14, 24, 130, 1.5, 1.0, 48, 10, 60, 0
	end
end

local function roundUpPositive(value: number): number
	local r = math.floor(value + 0.5)
	if r < 1 then
		r = 1
	end
	return r
end

local function makeBaseStats(diet, isAquatic, isFlyer)
	local h, w, sp, st, hd, td, dmg, sr, ox, fd = adultDefaults(diet, isAquatic, isFlyer)
	local baseStats = {}
	for _, stage in ipairs(SpeciesRoster.GrowthStages) do
		local m = STAGE_SCALE[stage]
		-- Walk/Sprint scale gently so SprintSpeed >= WalkSpeed always holds and
		-- WalkSpeed stays > 0 at Hatchling.
		local walk = roundUpPositive(w * (0.7 + 0.3 * m))
		local sprint = roundUpPositive(sp * (0.7 + 0.3 * m))
		if sprint < walk then
			sprint = walk
		end
		baseStats[stage] = statBlock(
			roundUpPositive(h * m),
			walk,
			sprint,
			roundUpPositive(st * m),
			hd,
			td,
			roundUpPositive(dmg * m),
			roundUpPositive(sr),
			roundUpPositive(ox),
			isFlyer and roundUpPositive(fd * m) or 0
		)
	end
	return baseStats
end

local function creatureCategory(diet, isAquatic, isFlyer)
	if isFlyer then
		return "Flyer"
	elseif isAquatic then
		return "Aquatic"
	elseif diet == "Herbivore" then
		return "Herbivore"
	elseif diet == "Omnivore" then
		return "Omnivore"
	else
		return "Carnivore"
	end
end

local function roleFor(diet, isAquatic, isFlyer)
	if isFlyer then
		return "aerial carnivore / staged roster flyer"
	elseif isAquatic then
		return "aquatic carnivore / staged roster swimmer"
	elseif diet == "Herbivore" then
		return "land herbivore / staged roster grazer"
	elseif diet == "Omnivore" then
		return "land omnivore / staged roster forager"
	else
		return "land carnivore / staged roster predator"
	end
end

local function dnaCostFor(diet, isAquatic, isFlyer)
	if isFlyer then
		return 1500
	elseif isAquatic then
		return 1800
	elseif diet == "Herbivore" then
		return 400
	elseif diet == "Omnivore" then
		return 600
	else
		return 900
	end
end

local function spawnBiomesFor(diet, isAquatic, isFlyer)
	if isFlyer then
		return { Primary = "CoastalCliffs", Secondary = "MountainNestingCliffs", Nursery = "NurseryGrove" }
	elseif isAquatic then
		return { Primary = "SwampDelta", Secondary = "CoastalCliffs", Nursery = "NurseryGrove" }
	elseif diet == "Herbivore" then
		return { Primary = "FernPlains", Secondary = "JungleBasin", Nursery = "NurseryGrove" }
	elseif diet == "Omnivore" then
		return { Primary = "JungleBasin", Secondary = "FernPlains", Nursery = "NurseryGrove" }
	else
		return { Primary = "RedstoneCanyon", Secondary = "JungleBasin", Nursery = "NurseryGrove" }
	end
end

-- Salvaged shared animation ids (same set the curated species reuse).
local SHARED_ANIMS = {
	Idle = "rbxassetid://2914393495",
	Walk = "rbxassetid://2914138808",
	Run = "rbxassetid://2911668948",
	Attack = "rbxassetid://2914742341",
	Eat = "rbxassetid://2914158644",
	Drink = "rbxassetid://2914173919",
	Call = "",
}

local function modelPathsFor(speciesId)
	-- Marker path the visual layer resolves via StagedMeshLibrary:ResolveAny(speciesId).
	-- "staged://<speciesId>/<Stage>" signals "resolve from the live staged roster".
	local paths = {}
	for _, stage in ipairs(SpeciesRoster.GrowthStages) do
		paths[stage] = string.format("staged://%s/%s", speciesId, stage)
	end
	return paths
end

-- Build a single SpeciesConfig-compatible entry from { name, folder }.
local function buildEntry(name, folder)
	local diet, isAquatic = dietFromFolder(folder)
	local id = toSpeciesId(name)
	local isFlyer = FLYERS[id] == true
	local movement = {
		Ground = not isAquatic,
		Swim = isAquatic == true,
		Flight = isFlyer == true,
	}
	if isFlyer then
		movement.Ground = true -- flyers retain a ground fallback
	end

	local biomes = spawnBiomesFor(diet, isAquatic, isFlyer)

	return {
		SpeciesId = id,
		DisplayName = name,
		Diet = diet,
		CreatureCategory = creatureCategory(diet, isAquatic, isFlyer),
		EcosystemProfile = {
			Category = creatureCategory(diet, isAquatic, isFlyer),
			Herding = (diet == "Herbivore"),
			Apex = false,
			CanFly = isFlyer or nil,
			Aquatic = isAquatic or nil,
			PreferredBiome = biomes.Primary,
		},
		SpawnBiomes = biomes,
		MovementModes = movement,
		Role = roleFor(diet, isAquatic, isFlyer),
		UnlockCostDNA = dnaCostFor(diet, isAquatic, isFlyer),
		AllowedGrowthStages = SpeciesRoster.GrowthStages,
		BaseStats = makeBaseStats(diet, isAquatic, isFlyer),
		Abilities = {
			PrimaryAttack = (diet == "Herbivore") and "Headbutt" or "Bite",
			SecondaryAbility = isFlyer and "SwoopGrab" or (isAquatic and "TailSweep" or "Lunge"),
			CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" },
		},
		ModelPaths = modelPathsFor(id),
		AnimationIds = {
			Idle = SHARED_ANIMS.Idle,
			Walk = SHARED_ANIMS.Walk,
			Run = SHARED_ANIMS.Run,
			Attack = SHARED_ANIMS.Attack,
			Eat = SHARED_ANIMS.Eat,
			Drink = SHARED_ANIMS.Drink,
			Call = SHARED_ANIMS.Call,
		},
		Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
		StagedFolder = folder,
		StagedName = name,
		GeneratedFromRoster = true,
	}
end
SpeciesRoster.buildEntry = buildEntry

local generated = nil
local function ensureBuilt()
	if generated then
		return generated
	end
	local out = {}
	for _, rec in ipairs(SpeciesRoster.StagedSpecies) do
		local id = toSpeciesId(rec.name)
		if id ~= "" and out[id] == nil then
			out[id] = buildEntry(rec.name, rec.folder)
		end
	end
	generated = out
	return out
end

-- Map speciesId -> SpeciesConfig-compatible entry for ALL staged species (static).
function SpeciesRoster:AllSpecies()
	local built = ensureBuilt()
	local copy = {}
	for id, entry in pairs(built) do
		copy[id] = entry
	end
	return copy
end

-- One generated entry by speciesId (normalized match), or nil.
function SpeciesRoster:Get(speciesId)
	local built = ensureBuilt()
	if built[speciesId] then
		return built[speciesId]
	end
	local target = normalize(speciesId)
	for id, entry in pairs(built) do
		if id == target then
			return entry
		end
	end
	return nil
end

-- Sorted list of generated speciesIds.
function SpeciesRoster:ListIds()
	local built = ensureBuilt()
	local ids = {}
	for id in pairs(built) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

-- Count of distinct generated (de-duplicated) staged species.
function SpeciesRoster:Count()
	local built = ensureBuilt()
	local n = 0
	for _ in pairs(built) do
		n += 1
	end
	return n
end

-- Optional runtime reconciliation against the LIVE Workspace.dinosaur folders.
-- Returns speciesId -> entry built from the authoritative live model names.
-- Headless-safe: returns the static AllSpecies() when Workspace.dinosaur is absent.
function SpeciesRoster:BuildFromWorkspace()
	local ok, result = pcall(function()
		local Workspace = game:GetService("Workspace")
		local dino = Workspace:FindFirstChild("dinosaur")
		if not dino then
			return nil
		end
		local out = {}
		for _, folderName in pairs(SpeciesRoster.DietFolders) do
			local folder = dino:FindFirstChild(folderName)
			if folder then
				for _, model in ipairs(folder:GetChildren()) do
					local id = toSpeciesId(model.Name)
					if id ~= "" and out[id] == nil then
						out[id] = buildEntry(model.Name, folderName)
					end
				end
			end
		end
		return out
	end)
	if ok and result and next(result) ~= nil then
		return result
	end
	return self:AllSpecies()
end

return SpeciesRoster
