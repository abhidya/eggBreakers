local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "AssetImportAuditStateTests", category = "Security", tests = {} }

local function withImportedFixture(callback)
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary") or Instance.new("Folder")
    local createdLibrary = library.Parent == nil
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local fixture = Instance.new("Model")
    fixture.Name = "Task23ImportedAuditFixture"
    fixture:SetAttribute("AssetManifestId", AssetManifest.Entries[1].AssetId)
    fixture:SetAttribute("TestImportedAuditFixture", true)
    fixture.Parent = library

    local visiblePart = Instance.new("Part")
    visiblePart.Name = "VisibleImportedPart"
    visiblePart.Transparency = 0
    visiblePart.Parent = fixture

    local runtimeScript = Instance.new("Script")
    runtimeScript.Name = "UnsafeImportedRuntime"
    runtimeScript.Parent = fixture

    local ok, result = pcall(callback, fixture)

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
