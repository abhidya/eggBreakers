local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local PlacementValidationService = require(ServerScriptService.Services.PlacementValidationService)

local suite = { name = "NaturalPlacementValidation.server", category = "Placement", tests = {} }

table.insert(suite.tests, { name = "reference plan satisfies natural biome acceptance", run = function()
    local result = PlacementValidationService:ValidatePlan(PlacementValidationService:GetReferencePlan())
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.truthy(result.total >= 16, "reference plan covers required biome categories")
end })

table.insert(suite.tests, { name = "route corridors remain clear", run = function()
    local blockedPlan = {
        { id = "BlockedFernTree", biome = "FernPlains", category = "Tree", position = Vector3.new(-1575, 11, 0), rotationY = 0 },
    }
    local result = PlacementValidationService:ValidatePlan(blockedPlan)
    Assert.falsy(result.passed, "route-center tree must fail placement validation")
end })

table.insert(suite.tests, { name = "biome categories reject cross-biome props and nursery fossils", run = function()
    local invalidPlan = {
        { id = "SwampTreeInCity", biome = "ApocalypticCity", category = "SwampTree", position = Vector3.new(735, 11, -262), rotationY = 0 },
        { id = "NurseryFossil", biome = "NurseryGrove", category = "Fossil", position = Vector3.new(-2235, 11, -215), rotationY = 0 },
    }
    local result = PlacementValidationService:ValidatePlan(invalidPlan)
    Assert.falsy(result.passed, "cross-biome props and nursery fossils must fail")
end })

table.insert(suite.tests, { name = "square grid clusters are rejected", run = function()
    local gridPlan = {
        { id = "GridBushA", biome = "FernPlains", category = "Bush", position = Vector3.new(-1430, 11, -240), rotationY = 0 },
        { id = "GridBushB", biome = "FernPlains", category = "Bush", position = Vector3.new(-1390, 11, -200), rotationY = 0 },
        { id = "GridBushC", biome = "FernPlains", category = "Bush", position = Vector3.new(-1350, 11, -160), rotationY = 0 },
    }
    local result = PlacementValidationService:ValidatePlan(gridPlan)
    Assert.falsy(result.passed, "repeated equal deltas must be treated as grid placement")
end })


table.insert(suite.tests, { name = "final acceptance requires 500 unique source assets", run = function()
    local records = {}
    for index = 1, PlacementValidationService.MinimumUniqueSourceAssetIds do
        table.insert(records, { id = "ImportedAsset" .. tostring(index), SourceAssetId = 900000 + index })
    end
    local result = PlacementValidationService:ValidateUniqueSourceAssets(records)
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.equals(result.uniqueSourceAssetIds, 500, "unique SourceAssetId count")

    records[500].SourceAssetId = records[1].SourceAssetId
    local duplicateResult = PlacementValidationService:ValidateUniqueSourceAssets(records)
    Assert.falsy(duplicateResult.passed, "cloned duplicate SourceAssetId must fail final acceptance")
end })


table.insert(suite.tests, { name = "full-map underlay covers zones routes and reference placements", run = function()
    local result = PlacementValidationService:ValidateGeometryCoverage(PlacementValidationService:GetReferencePlan())
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
    Assert.equals(result.underlayName, "FullMapSafeTerrainUnderlay", "single safe terrain underlay name")
end })

TestRunner.registerSuite(suite)
return suite
