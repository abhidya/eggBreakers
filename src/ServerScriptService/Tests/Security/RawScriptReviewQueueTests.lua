local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "RawScriptReviewQueueTests.server", category = "Security", tests = {} }

local function withIsolatedImportedRoots(callback)
    local realLibrary = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if realLibrary then
        realLibrary.Name = "_RealImportedAssetLibrary_RawScriptReview"
    end

    local map = Workspace:FindFirstChild("Map")
    local createdMap = false
    if not map then
        map = Instance.new("Folder")
        map.Name = "Map"
        map.Parent = Workspace
        createdMap = true
    end
    local realMapAssets = map and map:FindFirstChild("ImportedAssets")
    if realMapAssets then
        realMapAssets.Name = "_RealImportedAssets_RawScriptReview"
    end
    local isolatedMapAssets = Instance.new("Folder")
    isolatedMapAssets.Name = "ImportedAssets"
    isolatedMapAssets.Parent = map

    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local ok, result = pcall(callback, library)

    library:Destroy()
    isolatedMapAssets:Destroy()

    local quarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    if quarantine then quarantine:Destroy() end

    if realLibrary then
        realLibrary.Name = "ImportedAssetLibrary"
    end
    if realMapAssets then
        realMapAssets.Name = "ImportedAssets"
    end
    if createdMap then
        map:Destroy()
    end

    if not ok then error(result, 2) end
    return result
end

local function makeVisibleRawQueueRoot(library)
    local entry = AssetManifest.Entries[1]
    local root = Instance.new("Model")
    root.Name = "G032RawScriptedFishReviewQueueFixture"
    root:SetAttribute("SourceAssetId", entry.SourceAssetId)
    root:SetAttribute("AssetManifestId", entry.AssetId)
    root:SetAttribute("CreatorStoreOnly", true)
    root:SetAttribute("ImportedVisibleAsset", true)
    root:SetAttribute("RawImportedScriptPreserved", true)
    root:SetAttribute("ScriptReviewStatus", "raw_preserved_pending_adaptation")
    root:SetAttribute("ScriptAuditScope", "G032")
    root.Parent = library

    local visible = Instance.new("Part")
    visible.Name = "VisibleImportedMesh"
    visible.Size = Vector3.new(4, 4, 4)
    visible.Transparency = 0
    visible.Parent = root

    return root
end

local function stampReviewedAdaptedSandboxedModule(moduleScript)
    moduleScript:SetAttribute("ImportedScriptAudited", true)
    moduleScript:SetAttribute("ImportedScriptAdapted", true)
    moduleScript:SetAttribute("ScriptAdaptedTo", "eggBreakers imported asset utility")
    moduleScript:SetAttribute("ImportedScriptStamped", true)
    moduleScript:SetAttribute("ImportedScriptOwner", "SecurityAuditService")
    moduleScript:SetAttribute("ScriptAuditPurpose", "adapted imported utility only")
    moduleScript:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
    moduleScript:SetAttribute("ScriptAuditDecision", "keep")
    moduleScript:SetAttribute("ScriptAuditScope", "G032")
    moduleScript:SetAttribute("Sandboxed", true)
end

table.insert(suite.tests, { name = "raw scripted imports stay queued for review instead of quarantined", run = function()
    withIsolatedImportedRoots(function(library)
        local root = makeVisibleRawQueueRoot(library)

        local rawScript = Instance.new("Script")
        rawScript.Name = "VendorRandomWalkSource"
        rawScript.Disabled = true
        rawScript.Parent = root

        local result = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(result.counts.scriptsQuarantined, 0, "raw queued script is preserved for review")
        Assert.equals(rawScript.Parent, root, "raw queued script remains attached to its imported source")
        Assert.equals(rawScript.Disabled, true, "raw queued executable source is disabled until adapted")
        Assert.equals(rawScript:GetAttribute("ImportedScriptPreservedForReview"), true,
            "raw queued script receives preserved-for-review stamp")
        Assert.equals(result.counts.releaseReadyVisibleAssets, 0,
            "raw queued scripted source is not release-ready until adapted/stamped")

        local scan = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(scan.passed, table.concat(scan.failures, "; "))
        Assert.equals(#scan.preservedForReview, 1, "raw queued script is visible to review scan")
        Assert.equals(#scan.quarantineRecommended, 0, "raw queued script avoids false-positive quarantine")
    end)
end })

table.insert(suite.tests, { name = "raw ModuleScript does not pass raw queue without review adaptation and sandbox", run = function()
    withIsolatedImportedRoots(function(library)
        local root = makeVisibleRawQueueRoot(library)

        local rawModule = Instance.new("ModuleScript")
        rawModule.Name = "VendorRawUtilitySource"
        rawModule.Parent = root

        local scan = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(scan.passed, "raw queued ModuleScript must fail until reviewed, adapted, and sandboxed")
        Assert.equals(#scan.quarantineRecommended, 1, "raw queued ModuleScript is recommended for quarantine")
        Assert.equals(#scan.preservedForReview, 0, "raw queued ModuleScript is not preserved by queue stamp alone")
    end)
end })

table.insert(suite.tests, { name = "reviewed adapted sandboxed ModuleScript passes imported script scan", run = function()
    withIsolatedImportedRoots(function(library)
        local root = makeVisibleRawQueueRoot(library)
        root:SetAttribute("RawImportedScriptPreserved", nil)
        root:SetAttribute("ScriptReviewStatus", nil)

        local moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = "AdaptedImportedUtility"
        stampReviewedAdaptedSandboxedModule(moduleScript)
        moduleScript.Parent = root

        local scan = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(scan.passed, table.concat(scan.failures, "; "))
        Assert.equals(#scan.preserved, 1, "reviewed adapted sandboxed ModuleScript is preserved")
        Assert.equals(#scan.quarantineRecommended, 0, "reviewed adapted sandboxed ModuleScript avoids quarantine")
    end)
end })

table.insert(suite.tests, { name = "raw review queued runtime scripts fail until disabled", run = function()
    withIsolatedImportedRoots(function(library)
        local root = makeVisibleRawQueueRoot(library)

        local rawScript = Instance.new("Script")
        rawScript.Name = "EnabledVendorRandomWalkSource"
        rawScript.Disabled = false
        rawScript.Parent = root

        local scan = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(scan.passed, "enabled raw queued script must fail before mutate repair disables it")
        Assert.equals(#scan.quarantineRecommended, 1, "enabled raw queued script is flagged")

        local repair = AssetImportAuditService:AuditAndRepair({ mutate = true })
        Assert.truthy(repair.passed, table.concat(repair.failures, "; "))
        Assert.equals(rawScript.Disabled, true, "mutate repair disables raw queued runtime script")
    end)
end })

table.insert(suite.tests, { name = "unstamped imported LocalScripts still require quarantine outside review queue", run = function()
    withIsolatedImportedRoots(function(library)
        local root = makeVisibleRawQueueRoot(library)
        root:SetAttribute("RawImportedScriptPreserved", nil)
        root:SetAttribute("ScriptReviewStatus", nil)

        local localScript = Instance.new("LocalScript")
        localScript.Name = "UnreviewedVendorClientScript"
        localScript.Parent = root

        local scan = SecurityAuditService:ScanImportedScripts()
        Assert.falsy(scan.passed, "unstamped LocalScript must not pass outside review queue")
        Assert.equals(#scan.quarantineRecommended, 1, "unstamped LocalScript is recommended for quarantine")
        Assert.equals(#scan.preservedForReview, 0, "no raw queue exemption without review-queue stamp")
    end)
end })

return TestRunner.registerSuite(suite)
