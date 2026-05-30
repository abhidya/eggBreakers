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
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary") or Instance.new("Folder")
    local createdLibrary = library.Parent == nil
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local fixture = makeImportedVisual(library, "Task23ImportedAuditFixture", AssetManifest.Entries[1])

    local runtimeScript = Instance.new("Script")
    runtimeScript.Name = "UnsafeImportedRuntime"
    runtimeScript.Parent = fixture

    local ok, result = pcall(callback, fixture, library)

    local quarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    if quarantine then
        for _, child in ipairs(quarantine:GetChildren()) do
            if child:GetAttribute("ImportedScriptQuarantined") == true or child.Name == "UnsafeImportedRuntime" then
                child:Destroy()
            end
        end
        if #quarantine:GetChildren() == 0 then
            quarantine:Destroy()
        end
    end
    local qualityQuarantine = ReplicatedStorage:FindFirstChild("QuarantinedImportedAssets")
    if qualityQuarantine then
        for _, child in ipairs(qualityQuarantine:GetChildren()) do
            if child:GetAttribute("TestImportedAuditFixture") == true or child:GetAttribute("AssetQualityQuarantined") == true then
                child:Destroy()
            end
        end
        if #qualityQuarantine:GetChildren() == 0 then
            qualityQuarantine:Destroy()
        end
    end
    for _, child in ipairs(library:GetChildren()) do
        if child:GetAttribute("TestImportedAuditFixture") == true then
            child:Destroy()
        end
    end
    if fixture.Parent then fixture:Destroy() end
    if createdLibrary and library.Parent then library:Destroy() end

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
        local meshFixture = makeImportedVisual(library, "Task23MeshFinalAsset", AssetManifest.Entries[2])
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
        Assert.equals(result.counts.meshExcludedAssets, 1, "MeshPart assets are forbidden from release-ready final assets")
        Assert.truthy(result.counts.lowQualityExcludedAssets >= 2, "glowing balls and rectangle-ball trees are low-quality exclusions")
        Assert.equals(result.counts.releaseReadyVisibleAssets, 1, "only the baseline fixture remains release-ready")
        Assert.truthy(result.counts.qualityAssetsQuarantined >= 3, "mesh and LQ generated visuals are quarantined")
    end)
end })

table.insert(suite.tests, { name = "required playable mesh visuals fail even with policy note", run = function()
    withImportedFixture(function(_, library)
        local meshFixture = makeImportedVisual(library, "Task23RequiredMeshPlayable", AssetManifest.Entries[2], {
            RequiredPlayableVisual = true,
            RequiredPlayableVisualPolicyNote = "Mesh must be replaced by generated Parts before release.",
        })
        local meshPart = Instance.new("MeshPart")
        meshPart.Name = "ForbiddenPlayableMesh"
        meshPart.Parent = meshFixture

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.falsy(result.passed, "required playable meshes are still forbidden final assets")
        Assert.truthy(result.counts.meshExcludedAssets >= 1, "mesh exclusion counted")
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
