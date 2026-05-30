local stages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }

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
    gallimimus = {
        SpeciesId = "gallimimus",
        DisplayName = "Gallimimus",
        Diet = "Herbivore",
        CreatureCategory = "SmallPrey",
        EcosystemProfile = { CanGraze = true, Herding = true, SmallPrey = true, PreferredBiome = "FernPlains" },
        SpawnBiomes = { Primary = "FernPlains", Secondary = "NurseryGrove", Nursery = "NurseryGrove" },
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "small fast herbivore / ornithomimid scout",
        UnlockCostDNA = 0,
        AllowedGrowthStages = stages,
        BaseStats = {
            Hatchling = stats(45, 12, 20, 80, 0.7, 0.8, 4, { StaminaRegen = 11, MaxOxygen = 55, FlightStaminaDrain = 0 }),
            Juvenile = stats(65, 15, 24, 95, 0.8, 0.9, 7, { StaminaRegen = 12, MaxOxygen = 60, FlightStaminaDrain = 0 }),
            SubAdult = stats(85, 17, 27, 110, 0.9, 1.0, 10, { StaminaRegen = 13, MaxOxygen = 65, FlightStaminaDrain = 0 }),
            Adult = stats(110, 18, 29, 125, 1.0, 1.1, 13, { StaminaRegen = 14, MaxOxygen = 70, FlightStaminaDrain = 0 }),
        },
        Abilities = { PrimaryAttack = "Nibble", SecondaryAbility = "QuickDash", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Adult" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },
    triceratops = {
        SpeciesId = "triceratops",
        DisplayName = "Triceratops",
        Diet = "Herbivore",
        CreatureCategory = "DefensiveHerbivore",
        EcosystemProfile = { CanGraze = true, Herding = true, PreferredBiome = "FernPlains" },
        SpawnBiomes = { Primary = "FernPlains", Secondary = "JungleBasin", Nursery = "NurseryGrove" },
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "medium defensive ceratopsian herbivore",
        UnlockCostDNA = 0,
        AllowedGrowthStages = stages,
        BaseStats = {
            Hatchling = stats(60, 10, 16, 75, 0.8, 0.8, 5, { StaminaRegen = 8, MaxOxygen = 50, FlightStaminaDrain = 0 }),
            Juvenile = stats(95, 12, 18, 90, 0.9, 0.9, 10, { StaminaRegen = 8, MaxOxygen = 55, FlightStaminaDrain = 0 }),
            SubAdult = stats(140, 13, 20, 105, 1.0, 1.0, 16, { StaminaRegen = 9, MaxOxygen = 60, FlightStaminaDrain = 0 }),
            Adult = stats(190, 14, 21, 120, 1.1, 1.1, 24, { StaminaRegen = 9, MaxOxygen = 65, FlightStaminaDrain = 0 }),
        },
        Abilities = { PrimaryAttack = "Headbutt", SecondaryAbility = "DefensiveShove", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/Adult" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },
    velociraptor = {
        SpeciesId = "velociraptor",
        DisplayName = "Velociraptor",
        Diet = "Carnivore",
        CreatureCategory = "PackPredator",
        EcosystemProfile = { PackHunter = true, OmnivoreCompatiblePrey = true, PreferredBiome = "JungleBasin" },
        SpawnBiomes = { Primary = "JungleBasin", Secondary = "FernPlains", Nursery = "NurseryGrove" },
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "small pack carnivore / raptor ambusher",
        UnlockCostDNA = 0,
        AllowedGrowthStages = stages,
        BaseStats = {
            Hatchling = stats(50, 12, 21, 85, 1.0, 0.8, 7, { StaminaRegen = 10, MaxOxygen = 45, FlightStaminaDrain = 0 }),
            Juvenile = stats(75, 15, 25, 100, 1.1, 0.9, 13, { StaminaRegen = 11, MaxOxygen = 50, FlightStaminaDrain = 0 }),
            SubAdult = stats(100, 17, 28, 115, 1.2, 1.0, 20, { StaminaRegen = 12, MaxOxygen = 55, FlightStaminaDrain = 0 }),
            Adult = stats(130, 18, 30, 130, 1.3, 1.1, 28, { StaminaRegen = 12, MaxOxygen = 60, FlightStaminaDrain = 0 }),
        },
        Abilities = { PrimaryAttack = "Claw", SecondaryAbility = "Lunge", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Adult" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },
    carnotaurus = {
        SpeciesId = "carnotaurus",
        DisplayName = "Carnotaurus",
        Diet = "Carnivore",
        CreatureCategory = "ApexCandidate",
        EcosystemProfile = { ApexEventEligible = true, PreferredBiome = "RedstoneCanyon" },
        MovementModes = { Ground = true, Swim = false, Flight = false },
        Role = "medium solo carnivore / chase predator",
        UnlockCostDNA = 0,
        AllowedGrowthStages = stages,
        BaseStats = {
            Hatchling = stats(65, 10, 17, 80, 1.2, 0.8, 9, { StaminaRegen = 8, MaxOxygen = 45, FlightStaminaDrain = 0 }),
            Juvenile = stats(100, 13, 21, 95, 1.4, 0.9, 18, { StaminaRegen = 9, MaxOxygen = 50, FlightStaminaDrain = 0 }),
            SubAdult = stats(145, 15, 24, 110, 1.6, 1.0, 30, { StaminaRegen = 9, MaxOxygen = 55, FlightStaminaDrain = 0 }),
            Adult = stats(200, 16, 26, 125, 1.8, 1.1, 44, { StaminaRegen = 10, MaxOxygen = 60, FlightStaminaDrain = 0 }),
        },
        Abilities = { PrimaryAttack = "Bite", SecondaryAbility = "HeavyBite", CallSet = { "Friendly", "Warning", "Threat", "BabyDistress" } },
        ModelPaths = { Hatchling = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Hatchling", Juvenile = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Juvenile", SubAdult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/SubAdult", Adult = "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Adult" },
        VisualOrientationCorrection = { PitchDegrees = 180, ForceUpright = true, Reason = "Imported Carnotaurus asset may load inverted; force upright after attachment" },
        SpawnBiomes = { Primary = "RedstoneCanyon", Secondary = "ApocalypticCity", Nursery = "NurseryGrove" },
        -- SALVAGED animation IDs from imported dino pack; per-rig validation required before shipping.
        AnimationIds = { Idle = "rbxassetid://2914393495", Walk = "rbxassetid://2914138808", Run = "rbxassetid://2911668948", Attack = "rbxassetid://2914742341", Eat = "rbxassetid://2914158644", Drink = "rbxassetid://2914173919", Call = "" },
        Sounds = { CallFriendly = "", CallWarning = "", CallThreat = "", BabyDistress = "" },
    },
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

return SpeciesConfig
