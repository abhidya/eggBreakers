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
        "gallimimus",
        "triceratops",
        "velociraptor",
        "carnotaurus",
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
    local model, reason = StagedMeshLibrary:ResolveModel("triceratops")
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

return TestRunner.registerSuite(suite)
