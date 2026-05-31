local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local PlacementValidationService = require(ServerScriptService.Services.PlacementValidationService)
local SecurityAuditService = require(ServerScriptService.Services.SecurityAuditService)

local suite = { name = "StoryboardImportedScriptGateTests", category = "Placement", tests = {} }

local function stampReviewedAdaptedScript(scriptObject)
    scriptObject:SetAttribute("ImportedScriptAudited", true)
    scriptObject:SetAttribute("ImportedScriptAdapted", true)
    scriptObject:SetAttribute("ImportedScriptStamped", true)
    scriptObject:SetAttribute("ImportedScriptOwner", "StoryboardAssetGate")
    scriptObject:SetAttribute("ScriptAuditPurpose", "adapted ambient storyboard beat only")
    scriptObject:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
end

local function makeStoryboardAsset(name)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("SourceAssetId", "storyboard-script-gate-fixture")
    model:SetAttribute("AssetManifestId", "StoryboardScriptGateFixture")
    model:SetAttribute("CreatorStoreOnly", true)
    model:SetAttribute("ImportedVisibleAsset", true)
    model:SetAttribute("GroundedStoryboardAsset", true)
    model:SetAttribute("ZoneId", "NurseryGrove")
    model:SetAttribute("PlacementRole", "reviewed imported script policy fixture")
    model:SetAttribute("GroundTopY", 10)
    model:SetAttribute("GroundBottomY", 10)
    model:SetAttribute("GroundClearance", 0)

    local visiblePart = Instance.new("Part")
    visiblePart.Name = "VisibleStoryboardMesh"
    visiblePart.Size = Vector3.new(4, 4, 4)
    visiblePart.Position = Vector3.new(-2000, 12, 0)
    visiblePart.Anchored = true
    visiblePart.Transparency = 0
    visiblePart.Parent = model

    return model
end

local function withIsolatedImportedAssets(callback)
    local map = Workspace:FindFirstChild("Map")
    local createdMap = false
    if not map then
        map = Instance.new("Folder")
        map.Name = "Map"
        map.Parent = Workspace
        createdMap = true
    end

    local realMapAssets = map:FindFirstChild("ImportedAssets")
    if realMapAssets then
        realMapAssets.Name = "_RealImportedAssets_StoryboardScriptGate"
    end

    local realLibrary = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if realLibrary then
        realLibrary.Name = "_RealImportedAssetLibrary_StoryboardScriptGate"
    end

    local importedAssets = Instance.new("Folder")
    importedAssets.Name = "ImportedAssets"
    importedAssets.Parent = map

    local ok, result = pcall(callback, importedAssets)

    importedAssets:Destroy()
    if realMapAssets then
        realMapAssets.Name = "ImportedAssets"
    end
    if realLibrary then
        realLibrary.Name = "ImportedAssetLibrary"
    end
    if createdMap then
        map:Destroy()
    end

    if not ok then error(result, 2) end
    return result
end

table.insert(suite.tests, { name = "storyboard imported assets pass grounded placement gate", run = function()
    local batch = Instance.new("Folder")
    batch.Name = "StoryboardScriptGatePlacementFixture"

    local ok, err = pcall(function()
        local model = makeStoryboardAsset("Beat0ReviewedRustleNest")
        model.Parent = batch

        local result = PlacementValidationService:ValidateNoFloatingVisibleAssets(batch)
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(result.checked, 1, "visible storyboard asset checked by placement gate")
    end)

    batch:Destroy()
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "storyboard reviewed adapted scripts pass imported script scan", run = function()
    withIsolatedImportedAssets(function(importedAssets)
        local model = makeStoryboardAsset("Beat0ReviewedRustleNest")
        model.Parent = importedAssets

        local scriptObject = Instance.new("Script")
        scriptObject.Name = "ReviewedRustleScript"
        stampReviewedAdaptedScript(scriptObject)
        scriptObject.Parent = model

        local result = SecurityAuditService:ScanImportedScripts()
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(#result.preserved, 1, "reviewed adapted storyboard script is preserved")
        Assert.equals(#result.quarantineRecommended, 0, "reviewed adapted storyboard script avoids quarantine")
    end)
end })

return TestRunner.registerSuite(suite)
