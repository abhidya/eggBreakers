local stages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }
local Constants = require(script.Parent.Constants)

local function stats(maxHealth, walkSpeed, sprintSpeed, stamina, hungerDrain, thirstDrain, damage, extras)
    local result = {
        MaxHealth = maxHealth,
        WalkSpeed = walkSpeed,
        SprintSpeed = sprintSpeed,
        MaxStamina = stamina,
        HungerDrain = hungerDrain,
        ThirstDrain = thirstDrain,
        Damage = damage,
        StaminaRegen = 10,
        MaxOxygen = 60,
        FlightStaminaDrain = 0,
    }
    for key, value in pairs(extras or {}) do
        result[key] = value
    end
    return result
end

local SpeciesConfig = {
    tyrannosaurus = {
        SpeciesId = "tyrannosaurus",
        DisplayName = "Tyrannosaurus",
        Diet = "Carnivore",
        CreatureCategory = "Apex",
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "apex carnivore / territory event predator",
        UnlockCostDNA = 3000,
        FossilRequirement = "Apex",
        AllowedGrowthStages = stages,
        EcosystemProfile = { Category = "Apex", Apex = true, Herding = false, ThreatRadius = 140, PreferredZones = { "RedstoneCanyon", "ApocalypticCity", "MountainNestingCliffs" } },
        BaseStats = {
            Hatchling = stats(80, 9, 15, 70, 1.4, 0.9, 12),
            Juvenile = stats(135, 11, 18, 90, 1.7, 1.0, 26),
            SubAdult = stats(220, 13, 21, 110, 2.0, 1.1, 48),
            Adult = stats(340, 14, 23, 130, 2.4, 1.2, 80),
        },
        Abilities = { PrimaryAttack = "CrushingBite", SecondaryAbility = "ApexRoar", CallSet = { "Threat", "Warning", "Territory", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Tyrannosaurus_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Tyrannosaurus_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Tyrannosaurus_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Tyrannosaurus_Model_Set/Adult" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallThreat = "", CallWarning = "", CallTerritory = "", BabyDistress = "" },
    },
    oviraptor = {
        SpeciesId = "oviraptor",
        DisplayName = "Oviraptor",
        Diet = "Omnivore",
        CreatureCategory = "Omnivore",
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "omnivore opportunist / nest-edge scavenger",
        UnlockCostDNA = 900,
        AllowedGrowthStages = stages,
        EcosystemProfile = { Category = "Omnivore", Apex = false, Herding = true, HerdRadius = 65, PreferredZones = { "FernPlains", "JungleBasin", "SwampDelta" } },
        BaseStats = {
            Hatchling = stats(42, 12, 20, 85, 0.8, 0.8, 5),
            Juvenile = stats(62, 15, 24, 100, 0.9, 0.9, 9),
            SubAdult = stats(90, 17, 27, 115, 1.0, 1.0, 15),
            Adult = stats(125, 18, 29, 130, 1.1, 1.1, 22),
        },
        Abilities = { PrimaryAttack = "Peck", SecondaryAbility = "ScavengeDash", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/Adult" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },

    -- =========================================================================
    -- NEW: PTERANODON — flight-capable species (BR-11 / MovementModes.Flight)
    -- =========================================================================
    pteranodon = {
        SpeciesId = "pteranodon",
        DisplayName = "Pteranodon",
        Diet = "Carnivore",
        CreatureCategory = "Flyer",
        EcosystemProfile = { CanFly = true, Soaring = true, CoastalPredator = true, PreferredBiome = "CoastalCliffs" },
        SpawnBiomes = { Primary = "CoastalCliffs", Secondary = "MountainNestingCliffs", Nursery = "NurseryGrove" },
        -- Flight=true enables FlightService unlock for this species.
        MovementModes = { Ground = true, Swim = false, Flight = true },
        Role = "aerial carnivore / coastal fisher and soarer",
        UnlockCostDNA = 1500,
        AllowedGrowthStages = stages,
        BaseStats = {
            -- FlightStaminaDrain > 0 so sustained flight costs stamina.
            Hatchling = stats(40,  8, 14, 90,  0.9, 0.7, 5,  { StaminaRegen = 12, MaxOxygen = 50, FlightStaminaDrain = 3 }),
            Juvenile  = stats(60, 10, 18, 110, 1.0, 0.8, 9,  { StaminaRegen = 13, MaxOxygen = 55, FlightStaminaDrain = 4 }),
            SubAdult  = stats(85, 12, 22, 130, 1.1, 0.9, 15, { StaminaRegen = 14, MaxOxygen = 60, FlightStaminaDrain = 5 }),
            Adult     = stats(115,14, 26, 150, 1.2, 1.0, 22, { StaminaRegen = 15, MaxOxygen = 65, FlightStaminaDrain = 6 }),
        },
        Abilities = { PrimaryAttack = "DiveBite", SecondaryAbility = "SwoopGrab", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        -- Placeholder model paths — swap for imported asset set when available.
        ModelPaths = {
            Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Pteranodon_Model_Set/Hatchling",
            Juvenile  = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Pteranodon_Model_Set/Juvenile",
            SubAdult  = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Pteranodon_Model_Set/SubAdult",
            Adult     = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Pteranodon_Model_Set/Adult",
        },
        -- Reusing salvaged animation IDs; Glide/Flap slots left empty until pterosaur rig is validated.
        AnimationIds = {
            Idle   = "rbxassetid://2914393495",
            Walk   = "rbxassetid://2914138808",
            Run    = "rbxassetid://2911668948",
            Attack = "rbxassetid://2914742341",
            Eat    = "rbxassetid://2914158644",
            Drink  = "rbxassetid://2914173919",
            Call   = "",
            Glide  = "",  -- pterosaur-specific; populate once rig validated
            Flap   = "",  -- pterosaur-specific; populate once rig validated
        },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },

    -- =========================================================================
    -- NEW: SPINOSAURUS — semi-aquatic species (WS-F / MovementModes.Swim)
    -- =========================================================================
    spinosaurus = {
        SpeciesId = "spinosaurus",
        DisplayName = "Spinosaurus",
        Diet = "Carnivore",
        CreatureCategory = "SemiAquatic",
        EcosystemProfile = { SemiAquatic = true, RiverPredator = true, ApexEventEligible = true, PreferredBiome = "SwampDelta" },
        SpawnBiomes = { Primary = "SwampDelta", Secondary = "JungleBasin", Nursery = "NurseryGrove" },
        -- Swim=true enables SwimService and OxygenService drowning loop for this species.
        MovementModes = { Ground = true, Swim = true, Flight = false },
        Role = "semi-aquatic apex carnivore / river fisher",
        UnlockCostDNA = 2500,
        FossilRequirement = "SemiApex",
        AllowedGrowthStages = stages,
        BaseStats = {
            -- Higher MaxOxygen reflects natural breath-hold capability.
            Hatchling = stats(75,  10, 16, 80,  1.3, 0.9, 11, { StaminaRegen = 9,  MaxOxygen = 80,  FlightStaminaDrain = 0 }),
            Juvenile  = stats(120, 12, 19, 100, 1.5, 1.0, 22, { StaminaRegen = 9,  MaxOxygen = 90,  FlightStaminaDrain = 0 }),
            SubAdult  = stats(200, 13, 21, 120, 1.8, 1.1, 38, { StaminaRegen = 10, MaxOxygen = 100, FlightStaminaDrain = 0 }),
            Adult     = stats(310, 14, 23, 140, 2.1, 1.2, 60, { StaminaRegen = 10, MaxOxygen = 110, FlightStaminaDrain = 0 }),
        },
        Abilities = { PrimaryAttack = "FishSnap", SecondaryAbility = "TailSweep", CallSet = { "Threat", "Warning", "Territory", "BabyDistress" } },
        -- Placeholder model paths — swap for imported asset set when available.
        ModelPaths = {
            Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/Hatchling",
            Juvenile  = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/Juvenile",
            SubAdult  = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/SubAdult",
            Adult     = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/Adult",
        },
        -- Reusing salvaged animation IDs; Swim slot left empty until aquatic rig is validated.
        AnimationIds = {
            Idle   = "rbxassetid://2914393495",
            Walk   = "rbxassetid://2914138808",
            Run    = "rbxassetid://2911668948",
            Attack = "rbxassetid://2914742341",
            Eat    = "rbxassetid://2914158644",
            Drink  = "rbxassetid://2914173919",
            Call   = "",
            Swim   = "",  -- aquatic-specific; populate once semi-aquatic rig validated
        },
        Sounds = { CallThreat = "", CallWarning = "", CallTerritory = "", BabyDistress = "" },
    },
}

-- ---------------------------------------------------------------------------
-- FULL ROSTER INJECTION
-- Make the full staged roster playable by injecting any species not already
-- defined above (48 distinct staged species + curated 8 => ~52 playable).
-- Additive: the curated 8 entries are NEVER overwritten.
-- Entries come from SpeciesRoster (SpeciesConfig-compatible shape, headless-safe).
-- Guarded with pcall so headless test loads still succeed if SpeciesRoster is
-- absent (the curated 8 remain available).
-- ---------------------------------------------------------------------------
do
    local ok, roster = pcall(function()
        return require(script.Parent.SpeciesRoster)
    end)
    if ok and roster and type(roster.AllSpecies) == "function" then
        local all = roster:AllSpecies()
        for id, entry in pairs(all) do
            if SpeciesConfig[id] == nil and not Constants.RetiredPrototypeSpecies[id] then
                SpeciesConfig[id] = entry
            end
        end
    end
end

for speciesId in pairs(Constants.RetiredPrototypeSpecies) do
    SpeciesConfig[speciesId] = nil
end

local starterVisualFallbacks = {
    citipati = "oviraptor",
    coelophysis = "oviraptor",
}

for speciesId, fallbackId in pairs(starterVisualFallbacks) do
    local species = SpeciesConfig[speciesId]
    local fallback = SpeciesConfig[fallbackId]
    if species and fallback and fallback.ModelPaths then
        species.VisualFallbackSpeciesId = fallbackId
        species.VisualFallbackReason = "release_safe_imported_starter_proxy"
        species.ModelPaths = species.ModelPaths or fallback.ModelPaths
    end
end

return SpeciesConfig
