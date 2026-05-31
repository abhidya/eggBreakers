local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "AssetImportAuditStateTests", category = "Security", tests = {} }

local function makeImportedVisual(parent, name, manifestEntry, attributes)
    local fixture = Instance.new("Model")
    fixture.Name = name
    fixture:SetAttribute("AssetManifestId", manifestEntry.AssetId)
    fixture:SetAttribute("SourceAssetId", manifestEntry.SourceAssetId)
    fixture:SetAttribute("CreatorStoreOnly", true)
    fixture:SetAttribute("ImportedVisibleAsset", true)
    fixture:SetAttribute("TestImportedAuditFixture", true)
    for key, value in pairs(attributes or {}) do
        fixture:SetAttribute(key, value)
    end
    fixture.Parent = parent

    local visiblePart = Instance.new("Part")
    visiblePart.Name = "VisibleImportedPart"
    visiblePart.Transparency = 0
    visiblePart.Parent = fixture
    return fixture
end

local function withImportedFixture(callback)
    local realLibrary = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    local tempLibraryName = "_RealImportedAssetLibrary"
    if realLibrary then
        realLibrary.Name = tempLibraryName
    end

    local map = Workspace:FindFirstChild("Map")
    local realMapAssets = map and map:FindFirstChild("ImportedAssets")
    local tempMapAssetsName = "_RealImportedAssets"
    if realMapAssets then
        realMapAssets.Name = tempMapAssetsName
    end

    -- Create fresh clean test library
    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    -- Create fresh clean test placed assets folder if map exists
    local testMapAssets = nil
    if map then
        testMapAssets = Instance.new("Folder")
        testMapAssets.Name = "ImportedAssets"
        testMapAssets.Parent = map
    end

    local fixture = makeImportedVisual(library, "Task23ImportedAuditFixture", AssetManifest.Entries[1])

    local runtimeScript = Instance.new("Script")
    runtimeScript.Name = "UnsafeImportedRuntime"
    runtimeScript.Parent = fixture

    local ok, result = pcall(callback, fixture, library)

    -- Cleanup test fixtures
    library:Destroy()
    if testMapAssets then
        testMapAssets:Destroy()
    end

    local quarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    if quarantine then
        quarantine:Destroy()
    end
    local qualityQuarantine = ReplicatedStorage:FindFirstChild("QuarantinedImportedAssets")
    if qualityQuarantine then
        qualityQuarantine:Destroy()
    end

    -- Restore real folders
    if realLibrary then
        realLibrary.Name = "ImportedAssetLibrary"
    end
    if realMapAssets then
        realMapAssets.Name = "ImportedAssets"
    end

    if not ok then error(result, 2) end
    return result
end

table.insert(suite.tests, { name = "audit separates cataloged imported tagged placed release counts", run = function()
    withImportedFixture(function()
        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(result.counts.catalogedSourceAssetIds >= 500, "catalog count is manifest-only")
        Assert.truthy(result.counts.actuallyImportedAssets < result.counts.catalogedSourceAssetIds, "imported count stays separate from cataloged")
        Assert.truthy(result.counts.taggedImportedAssets >= 1, "fixture tagged with manifest metadata")
        Assert.truthy(result.counts.placedVisibleAssets >= 1, "visible fixture counted as placed/visible")
        Assert.truthy(result.counts.releaseReadyVisibleAssets >= 1, "quarantined fixture can be release-ready")
        Assert.equals(result.counts.scriptsQuarantined, 1, "unsafe runtime script quarantined")
    end)
end })



table.insert(suite.tests, { name = "quality exclusions are separated and withheld from release counts", run = function()
    withImportedFixture(function(_, library)
        makeImportedVisual(library, "Task23ImportedDuplicate", AssetManifest.Entries[1])
        makeImportedVisual(library, "Task23ImportedLowQualityFoodBall", AssetManifest.Entries[2], {
            AssetQualityExclusionKind = "low-quality",
        })
        makeImportedVisual(library, "Task23ImportedMeshExcludedTree", AssetManifest.Entries[3], {
            AssetQualityExclusionKind = "mesh",
        })

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.equals(result.counts.actuallyImportedAssets, 3, "duplicate SourceAssetIds do not inflate imported count")
        Assert.equals(result.counts.releaseReadyVisibleAssets, 1, "quality-excluded assets do not count as release-ready")
        Assert.equals(result.counts.qualityExcludedAssets, 2, "all quality exclusions counted separately")
        Assert.equals(result.counts.lowQualityExcludedAssets, 1, "low-quality/simple generated exclusion separated")
        Assert.equals(result.counts.meshExcludedAssets, 1, "mesh exclusion separated from LQ")
    end)
end })


table.insert(suite.tests, { name = "mesh and generated low quality visuals are excluded and quarantined", run = function()
    withImportedFixture(function(_, library)
        local meshFixture = makeImportedVisual(library, "Task23MeshFinalAsset", AssetManifest.Entries[2], {
            AssetQualityExclusionKind = "mesh",
        })
        local meshPart = Instance.new("MeshPart")
        meshPart.Name = "CreatorStoreMeshPayload"
        meshPart.Parent = meshFixture

        local glowingBall = makeImportedVisual(library, "Task23GlowingFoodCandidate", AssetManifest.Entries[3])
        local ball = Instance.new("Part")
        ball.Name = "GlowingBallFood"
        ball.Shape = Enum.PartType.Ball
        ball.Material = Enum.Material.Neon
        ball.Parent = glowingBall

        local rectangleBallTree = makeImportedVisual(library, "Task23RectangleBallTree", AssetManifest.Entries[4])
        local trunk = Instance.new("Part")
        trunk.Name = "RectangleTrunk"
        trunk.Shape = Enum.PartType.Block
        trunk.Parent = rectangleBallTree
        local canopy = Instance.new("Part")
        canopy.Name = "BallCanopy"
        canopy.Shape = Enum.PartType.Ball
        canopy.Parent = rectangleBallTree

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.equals(result.counts.meshExcludedAssets, 1, "explicitly excluded MeshPart assets are forbidden")
        Assert.truthy(result.counts.lowQualityExcludedAssets >= 2, "glowing balls and rectangle-ball trees are low-quality exclusions")
        Assert.equals(result.counts.releaseReadyVisibleAssets, 1, "only the baseline fixture remains release-ready")
        Assert.truthy(result.counts.qualityAssetsQuarantined >= 3, "mesh and LQ generated visuals are quarantined")
    end)
end })

table.insert(suite.tests, { name = "required playable mesh visuals pass and are not quarantined", run = function()
    withImportedFixture(function(_, library)
        local meshFixture = makeImportedVisual(library, "Task23RequiredMeshPlayable", AssetManifest.Entries[2], {
            RequiredPlayableVisual = true,
        })
        local meshPart = Instance.new("MeshPart")
        meshPart.Name = "AllowedPlayableMesh"
        meshPart.Parent = meshFixture

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(result.passed, "required playable meshes are allowed by default")
        Assert.equals(result.counts.meshExcludedAssets, 0, "mesh exclusion not counted for untagged MeshPart import")
        -- Required playable mesh should not be quarantined
        Assert.truthy(meshFixture.Parent ~= nil and not meshFixture:GetAttribute("AssetQualityQuarantined"),
            "required playable mesh fixture must not be quarantined")
    end)
end })

table.insert(suite.tests, { name = "genuine tagged MeshPart import without exclusion flags is release-ready", run = function()
    withImportedFixture(function(_, library)
        -- A properly-tagged mesh asset: all 4 required attributes set, no exclusion flags
        local genuineMesh = makeImportedVisual(library, "Task23GenuineMeshDinoPack", AssetManifest.Entries[2])
        local meshPart = Instance.new("MeshPart")
        meshPart.Name = "DinoMeshBody"
        meshPart.Parent = genuineMesh

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(result.passed, "genuine tagged mesh import should not fail audit")
        Assert.equals(result.counts.meshExcludedAssets, 0, "unexcluded genuine mesh is not mesh-excluded")
        -- Both the baseline fixture and the genuine mesh should be release-ready
        Assert.truthy(result.counts.releaseReadyVisibleAssets >= 2,
            "genuine tagged MeshPart import counts toward release gate alongside baseline fixture")
        Assert.truthy(genuineMesh.Parent ~= nil and not genuineMesh:GetAttribute("AssetQualityQuarantined"),
            "genuine mesh import must not be quarantined")
    end)
end })

table.insert(suite.tests, { name = "ui icon names containing baseball do not trigger glowing ball quarantine", run = function()
    withImportedFixture(function(_, library)
        local iconPack = makeImportedVisual(library, "Task27MonochromeUIIconPack", AssetManifest.Entries[2])
        local baseballIcon = Instance.new("Part")
        baseballIcon.Name = "Baseball_Bat"
        baseballIcon.Material = Enum.Material.Neon
        baseballIcon.Shape = Enum.PartType.Block
        baseballIcon.Parent = iconPack

        local actualGlowingBall = makeImportedVisual(library, "Task27ActualGlowingBall", AssetManifest.Entries[3])
        local ball = Instance.new("Part")
        ball.Name = "Glowing_Ball"
        ball.Material = Enum.Material.Neon
        ball.Shape = Enum.PartType.Block
        ball.Parent = actualGlowingBall

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.equals(result.counts.lowQualityExcludedAssets, 1, "only the real glowing ball token is low-quality")
        Assert.truthy(iconPack.Parent ~= nil and not iconPack:GetAttribute("AssetQualityQuarantined"),
            "UI icon pack with Baseball_Bat remains release-eligible")
        Assert.truthy(result.counts.releaseReadyVisibleAssets >= 2,
            "baseline fixture and UI icon pack remain release-ready")
    end)
end })

table.insert(suite.tests, { name = "required playable quality exclusions need explicit policy note", run = function()
    withImportedFixture(function(fixture)
        fixture:SetAttribute("RequiredPlayableVisual", true)
        fixture:SetAttribute("AssetQualityExclusionKind", "low-quality")

        local blocked = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.falsy(blocked.passed, "required playable visual exclusion without note is blocked")

        fixture:SetAttribute("RequiredPlayableVisualPolicyNote", "Temporary quarantine: replacement playable visual required before release.")
        local noted = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(noted.passed, "explicit policy note allows audit reporting without accidental deletion")
        Assert.equals(noted.counts.releaseReadyVisibleAssets, 0, "noted quality exclusion still cannot count as release-ready")
    end)
end })


table.insert(suite.tests, { name = "union foliage quality scan does not assume Part.Shape", run = function()
    withImportedFixture(function(_, library)
        local treeFixture = makeImportedVisual(library, "Task23ImportedUnionFoliageTree", AssetManifest.Entries[2])
        local unionFoliage = Instance.new("UnionOperation")
        unionFoliage.Name = "Leaves"
        unionFoliage.Material = Enum.Material.Grass
        unionFoliage.Transparency = 0
        unionFoliage.Parent = treeFixture

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(result.passed, "UnionOperation foliage should not crash quality audit or fail release audit")
        Assert.falsy(AssetAuditService:IsVisibleGeneratedPart(unionFoliage), "workspace generated-part check also ignores UnionOperation.Shape safely")
        Assert.equals(result.counts.lowQualityExcludedAssets, 0, "ordinary union foliage is not a glowing ball or rectangle-ball tree")
        Assert.equals(result.counts.meshExcludedAssets, 0, "UnionOperation foliage is not a MeshPart exclusion")
        Assert.truthy(result.counts.releaseReadyVisibleAssets >= 2, "baseline and union foliage fixtures remain release-ready")
    end)
end })

table.insert(suite.tests, { name = "release gate fails before imported live count reaches catalog target", run = function()
    withImportedFixture(function()
        AssetImportAuditService:AuditAndRepair({ mutate = true })
        local result = AssetAuditService:ValidateReleaseImportReadiness(500)
        Assert.falsy(result.passed, "one live fixture cannot satisfy 500 release-ready imports")
        Assert.truthy(result.counts.actuallyImportedAssets < 500, "actually imported live count below target")
        local securityResult = SecurityAuditService:ValidateImportedAssetReleaseGate(500)
        Assert.falsy(securityResult.passed, "security release gate also fails below 500")
    end)
end })

return TestRunner.registerSuite(suite)
