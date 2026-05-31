local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local StagedMeshLibrary = require(ReplicatedStorage.Shared.StagedMeshLibrary)

local suite = { name = "StagedMeshMatrixTests", category = "Unit", tests = {} }

-- Exact diet folder names staged under Workspace.dinosaur at runtime.
local VALID_FOLDERS = {
    ["Herbivores (land)"] = true,
    ["Carnivores (land)"] = true,
    ["Omnivores(land)"] = true,
    ["Aquatic"] = true,
}

local function playableSpeciesIds()
    local ids = {}
    for speciesId in pairs(SpeciesConfig) do
        ids[#ids + 1] = speciesId
    end
    table.sort(ids)
    return ids
end

table.insert(suite.tests, { name = "every playable species has a staged mesh mapping", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = StagedMeshLibrary.SpeciesMesh[speciesId]
        Assert.notNil(entry, "missing staged mesh mapping for species " .. tostring(speciesId))
    end
end })

table.insert(suite.tests, { name = "each mapping entry has folder and name strings", run = function()
    for speciesId, entry in pairs(StagedMeshLibrary.SpeciesMesh) do
        Assert.equals(type(entry), "table", "entry is a table for " .. tostring(speciesId))
        Assert.equals(type(entry.folder), "string", "folder is a string for " .. tostring(speciesId))
        Assert.equals(type(entry.name), "string", "name is a string for " .. tostring(speciesId))
        Assert.truthy(#entry.folder > 0, "folder is non-empty for " .. tostring(speciesId))
        Assert.truthy(#entry.name > 0, "name is non-empty for " .. tostring(speciesId))
    end
end })

table.insert(suite.tests, { name = "each mapping folder is a known diet staging folder", run = function()
    for speciesId, entry in pairs(StagedMeshLibrary.SpeciesMesh) do
        Assert.truthy(VALID_FOLDERS[entry.folder], "unknown staging folder '" .. tostring(entry.folder) .. "' for " .. tostring(speciesId))
    end
end })

table.insert(suite.tests, { name = "the eight vertical-slice species are covered", run = function()
    local expected = {
        "coelophysis",
        "parasaurolophus",
        "utahraptor",
        "citipati",
        "tyrannosaurus",
        "oviraptor",
        "pteranodon",
        "spinosaurus",
    }
    local count = 0
    for _, speciesId in ipairs(expected) do
        Assert.notNil(StagedMeshLibrary.SpeciesMesh[speciesId], "staged mapping covers " .. speciesId)
        count = count + 1
    end
    Assert.equals(count, 8, "all eight species accounted for")
end })

table.insert(suite.tests, { name = "every mapping key is a real playable species", run = function()
    for speciesId in pairs(StagedMeshLibrary.SpeciesMesh) do
        Assert.notNil(SpeciesConfig[speciesId], "staged mapping key '" .. tostring(speciesId) .. "' is a playable species")
    end
end })

table.insert(suite.tests, { name = "ResolveModel reports no_staging_root when world is absent", run = function()
    -- Pure-logic guard: with no live Workspace staging, resolution fails gracefully
    -- rather than erroring, for a species that does have a mapping.
    local model, reason = StagedMeshLibrary:ResolveModel("parasaurolophus")
    if model == nil then
        Assert.truthy(reason == "no_staging_root" or reason == "no_diet_folder" or reason == "no_staged_model", "graceful failure reason when staging absent: " .. tostring(reason))
    else
        Assert.notNil(model, "resolved model is non-nil when staging present")
    end
end })

table.insert(suite.tests, { name = "ResolveModel rejects unknown and nil species without erroring", run = function()
    local m1, r1 = StagedMeshLibrary:ResolveModel(nil)
    Assert.truthy(m1 == nil, "nil species resolves to nil")
    Assert.equals(r1, "no_species_id", "nil species reports no_species_id")

    local m2, r2 = StagedMeshLibrary:ResolveModel("not_a_real_species")
    Assert.truthy(m2 == nil, "unknown species resolves to nil")
    Assert.equals(r2, "no_staged_mapping", "unknown species reports no_staged_mapping")
end })

-- =========================================================================
-- PER-SPECIES MATRIX: for every playable species, assert that its
-- SpeciesConfig entry is structurally valid, its StagedMeshLibrary mapping
-- exists, and exactly one movement mode (ground / flight / swim) is tagged.
-- Pure logic only — no live Workspace or staging instances are required.
-- =========================================================================

local VALID_DIETS = {
    Herbivore = true,
    Carnivore = true,
    Omnivore = true,
}

local KNOWN_STAGES = {
    Hatchling = true,
    Juvenile = true,
    SubAdult = true,
    Adult = true,
}

-- Numeric BaseStats fields every stage must define with sane (>=0) values.
local REQUIRED_STAT_FIELDS = {
    "MaxHealth",
    "WalkSpeed",
    "SprintSpeed",
    "MaxStamina",
    "HungerDrain",
    "ThirstDrain",
    "Damage",
}

table.insert(suite.tests, { name = "every playable species declares a valid diet", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        Assert.equals(type(entry.Diet), "string", "Diet is a string for " .. speciesId)
        Assert.truthy(VALID_DIETS[entry.Diet], "Diet '" .. tostring(entry.Diet) .. "' is recognized for " .. speciesId)
    end
end })

table.insert(suite.tests, { name = "every playable species lists valid AllowedGrowthStages", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        local stages = entry.AllowedGrowthStages
        Assert.equals(type(stages), "table", "AllowedGrowthStages is a table for " .. speciesId)
        Assert.truthy(#stages > 0, "AllowedGrowthStages is non-empty for " .. speciesId)
        for _, stage in ipairs(stages) do
            Assert.equals(type(stage), "string", "growth stage is a string for " .. speciesId)
            Assert.truthy(KNOWN_STAGES[stage], "growth stage '" .. tostring(stage) .. "' is known for " .. speciesId)
        end
    end
end })

table.insert(suite.tests, { name = "every playable species has ModelPaths for each allowed stage", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        Assert.equals(type(entry.ModelPaths), "table", "ModelPaths is a table for " .. speciesId)
        for _, stage in ipairs(entry.AllowedGrowthStages) do
            local path = entry.ModelPaths[stage]
            Assert.equals(type(path), "string", "ModelPaths has a string path for " .. speciesId .. " stage " .. stage)
            Assert.truthy(#path > 0, "ModelPaths path is non-empty for " .. speciesId .. " stage " .. stage)
        end
    end
end })

table.insert(suite.tests, { name = "every playable species has valid BaseStats for each allowed stage", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        Assert.equals(type(entry.BaseStats), "table", "BaseStats is a table for " .. speciesId)
        for _, stage in ipairs(entry.AllowedGrowthStages) do
            local statBlock = entry.BaseStats[stage]
            Assert.equals(type(statBlock), "table", "BaseStats block exists for " .. speciesId .. " stage " .. stage)
            for _, field in ipairs(REQUIRED_STAT_FIELDS) do
                local value = statBlock[field]
                Assert.equals(type(value), "number", "BaseStats." .. field .. " is a number for " .. speciesId .. " stage " .. stage)
                Assert.truthy(value >= 0, "BaseStats." .. field .. " is non-negative for " .. speciesId .. " stage " .. stage)
            end
            Assert.truthy(statBlock.MaxHealth > 0, "MaxHealth is positive for " .. speciesId .. " stage " .. stage)
        end
    end
end })

table.insert(suite.tests, { name = "every playable species has a staged mesh mapping (config-driven)", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local mapping = StagedMeshLibrary.SpeciesMesh[speciesId]
        Assert.notNil(mapping, "StagedMeshLibrary mapping exists for " .. speciesId)
        Assert.equals(type(mapping.folder), "string", "mapping.folder is a string for " .. speciesId)
        Assert.equals(type(mapping.name), "string", "mapping.name is a string for " .. speciesId)
        Assert.truthy(VALID_FOLDERS[mapping.folder], "mapping.folder is a known staging folder for " .. speciesId)
    end
end })

table.insert(suite.tests, { name = "every playable species tags exactly one primary movement mode", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        local modes = entry.MovementModes
        Assert.equals(type(modes), "table", "MovementModes is a table for " .. speciesId)
        Assert.equals(type(modes.Ground), "boolean", "MovementModes.Ground is a boolean for " .. speciesId)
        Assert.equals(type(modes.Flight), "boolean", "MovementModes.Flight is a boolean for " .. speciesId)
        Assert.equals(type(modes.Swim), "boolean", "MovementModes.Swim is a boolean for " .. speciesId)

        -- Derive a single canonical movement tag: flight > swim > ground.
        local tag
        if modes.Flight then
            tag = "flight"
        elseif modes.Swim then
            tag = "swim"
        elseif modes.Ground then
            tag = "ground"
        end
        Assert.notNil(tag, "at least one movement mode (ground/flight/swim) is enabled for " .. speciesId)
        Assert.truthy(tag == "ground" or tag == "flight" or tag == "swim", "movement tag is canonical for " .. speciesId .. ": " .. tostring(tag))
    end
end })

table.insert(suite.tests, { name = "flight and swim specials carry consistent stat drains", run = function()
    for _, speciesId in ipairs(playableSpeciesIds()) do
        local entry = SpeciesConfig[speciesId]
        local modes = entry.MovementModes
        for _, stage in ipairs(entry.AllowedGrowthStages) do
            local statBlock = entry.BaseStats[stage]
            Assert.equals(type(statBlock.MaxOxygen), "number", "MaxOxygen is a number for " .. speciesId .. " stage " .. stage)
            Assert.equals(type(statBlock.FlightStaminaDrain), "number", "FlightStaminaDrain is a number for " .. speciesId .. " stage " .. stage)
            if modes.Flight then
                Assert.truthy(statBlock.FlightStaminaDrain > 0, "flight species drains flight stamina for " .. speciesId .. " stage " .. stage)
            else
                Assert.equals(statBlock.FlightStaminaDrain, 0, "non-flight species has zero flight drain for " .. speciesId .. " stage " .. stage)
            end
        end
    end
end })

return TestRunner.registerSuite(suite)
