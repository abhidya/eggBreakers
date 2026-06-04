local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local WaterService = require(ServerScriptService.Services.WaterService)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)
local SwampDeltaStoryboard = require(ReplicatedStorage.Shared.SwampDeltaStoryboard)

local suite = { name = "SwampDeltaStoryboardValidation.server", category = "Placement", tests = {} }

local function ensureBuilt()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureTerrainContinuity(folders)
    MapLayoutService:EnsureSwampDeltaStoryboard(folders)
    return folders
end

table.insert(suite.tests, { name = "Beat 5 creates cache-backed non-import proxy markers", run = function()
    local folders = ensureBuilt()
    local storyboards = folders.Map:FindFirstChild("Storyboards")
    Assert.notNil(storyboards, "storyboards folder exists")
    local root = storyboards:FindFirstChild("SwampDeltaOxygenFish")
    Assert.notNil(root, "swamp storyboard root exists")
    Assert.equals(root:GetAttribute("StoryBeatId"), SwampDeltaStoryboard.BeatId, "story beat id recorded")
    Assert.equals(root:GetAttribute("SearchPolicy"), "custom_asset_search_mcp_only", "custom asset-search policy recorded")
    Assert.equals(root:GetAttribute("ValidationState"), "cache_only_pending_studio_asset_inspection", "cache-only validation state is honest")
    Assert.equals(root:GetAttribute("RequiredVerdict"), "player_angle_signed_off", "player-angle review remains required")

    local safeFolder = root:FindFirstChild("OxygenSafeNodes")
    Assert.notNil(safeFolder, "oxygen safe nodes folder exists")
    local safeCount = 0
    for _, pad in ipairs(safeFolder:GetChildren()) do
        if pad:IsA("BasePart") then
            safeCount = safeCount + 1
            Assert.equals(pad:GetAttribute("StoryboardSourceAssetId"), SwampDeltaStoryboard.Assets.LilyPad.sourceAssetId, "lily source id drives safe node")
            Assert.equals(pad:GetAttribute("AssetBackedStoryboardProxy"), true, "safe node is asset-backed proxy")
            Assert.equals(pad:GetAttribute("NeedsStudioAssetInspection"), true, "safe node still needs Studio inspection")
            Assert.equals(pad:GetAttribute("NeedsPlayerAngleScreenshot"), true, "safe node still needs player screenshot")
            Assert.falsy(pad:GetAttribute("ImportedVisibleAsset") == true, "safe node does not claim imported asset status")
            Assert.truthy((pad:GetAttribute("OxygenReliefPerSecond") or 0) > 0, "safe node has oxygen relief metadata")
        end
    end
    Assert.equals(safeCount, 3, "three readable lily oxygen nodes are built")

    local apex = root:FindFirstChild(SwampDeltaStoryboard.ApexWarning.name)
    Assert.notNil(apex, "Spinosaurus warning silhouette exists")
    Assert.equals(apex:GetAttribute("StoryboardSourceAssetId"), SwampDeltaStoryboard.Assets.SpinosaurusSilhouette.sourceAssetId, "Spinosaurus source id recorded")
    Assert.equals(apex:GetAttribute("StoryboardScriptRisk"), "NoScripts", "chosen Spinosaurus silhouette is script-free in cache")
    Assert.falsy(apex:GetAttribute("ImportedVisibleAsset") == true, "apex proxy does not claim imported asset status")
end })

table.insert(suite.tests, { name = "Beat 5 fish sources stay inside the swamp fish run", run = function()
    local folders = ensureBuilt()
    local water = folders.WaterSources:FindFirstChild("SwampRiverFishRun")
    Assert.notNil(water, "swamp fish water exists")
    Assert.equals(water:GetAttribute("FishHabitat"), true, "water is marked as fish habitat")
    Assert.truthy(CollectionService:HasTag(water, "FishHabitat"), "water has FishHabitat tag")

    local fishRoot = Workspace:FindFirstChild("FishSources")
    Assert.notNil(fishRoot, "fish source folder exists")
    local fishCount = 0
    for _, fishSpec in ipairs(SwampDeltaStoryboard.FishSources) do
        local fish = fishRoot:FindFirstChild(fishSpec.name)
        Assert.notNil(fish, fishSpec.name .. " fish source exists")
        Assert.equals(fish:GetAttribute("StoryboardSourceAssetId"), SwampDeltaStoryboard.Assets.Fish.sourceAssetId, "fish source id drives cache fish")
        Assert.equals(fish:GetAttribute("Diet"), "Carnivore", "fish feeds carnivores")
        Assert.truthy(CollectionService:HasTag(fish, "FoodSource"), "fish remains a FoodSource")
        Assert.truthy(CollectionService:HasTag(fish, "FishSource"), "fish has FishSource tag")
        Assert.truthy(WaterService:ContainsPoint(water, fish.Position, 0.01), fish.Name .. " is clamped inside water")
        Assert.equals(fish:GetAttribute("NeedsPlayerAngleScreenshot"), true, "fish needs player screenshot")
        fishCount = fishCount + 1
    end
    Assert.equals(fishCount, 3, "three fish sources support the swamp food objective")
end })

table.insert(suite.tests, { name = "Beat 5 keeps false positives deferred and passes visible proxy audit", run = function()
    local folders = ensureBuilt()
    local root = folders.Map.Storyboards:FindFirstChild("SwampDeltaOxygenFish")
    local deferred = root and root:FindFirstChild("RejectedOrDeferredCandidates")
    Assert.notNil(deferred, "deferred candidate folder exists")
    Assert.notNil(deferred:FindFirstChild("Asset_458900702"), "Venusaur false positive is kept deferred")
    Assert.notNil(deferred:FindFirstChild("Asset_75850368020021"), "Monet painting false positive is kept deferred")
    Assert.notNil(deferred:FindFirstChild("Asset_2989814926"), "scripted Spinosaurus NPC remains deferred")

    local audit = AssetAuditService:ScanWorkspace()
    Assert.truthy(audit.passed, table.concat(audit.failures, "; "))
end })

return TestRunner.registerSuite(suite)
