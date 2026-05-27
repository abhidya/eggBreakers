local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)

local UserStoryTestRegistry = require(script.Parent.UserStoryTestRegistry)
local StoryAssertions = require(script.Parent.StoryAssertions)

local suite = { name = "G018FinalGate", category = "G018FinalGate", tests = {} }
local REQUIRED_RELEASE_ASSETS = AssetManifest.MinimumUniqueAssets or 500
local BLOCKED_ASSET_ID = "9922699889"

local function childNamed(parent, name)
    return parent and parent:FindFirstChild(name) ~= nil
end

local function formatCounts(counts)
    return "cataloged=" .. tostring(counts.catalogedSourceAssetIds) ..
        ", actuallyImported=" .. tostring(counts.actuallyImportedAssets) ..
        ", audited=" .. tostring(counts.auditedImportedAssets) ..
        ", tagged=" .. tostring(counts.taggedImportedAssets) ..
        ", placedVisible=" .. tostring(counts.placedVisibleAssets) ..
        ", releaseReadyVisible=" .. tostring(counts.releaseReadyVisibleAssets)
end

local function manifestContainsSourceAssetId(sourceAssetId)
    for _, entry in ipairs(AssetManifest.SourceAssets or {}) do
        if tostring(entry.SourceAssetId) == sourceAssetId then
            return true
        end
    end
    return false
end

table.insert(suite.tests, { name = "G018 gate files are present and isolated", run = function()
    local testsFolder = ServerScriptService:FindFirstChild("Tests")
    local g018Folder = testsFolder and testsFolder:FindFirstChild("G018")
    Assert.truthy(childNamed(g018Folder, "G018FinalGate"), "missing G018FinalGate.server.lua")
    Assert.truthy(childNamed(g018Folder, "G018FinalGateSuite"), "missing G018FinalGateSuite.lua")
    Assert.truthy(childNamed(g018Folder, "UserStoryTestRegistry"), "missing UserStoryTestRegistry.lua")
    Assert.truthy(childNamed(g018Folder, "StoryAssertions"), "missing StoryAssertions.lua")
end })

table.insert(suite.tests, { name = "UserStoryTestRegistry enumerates US27-US36", run = function()
    StoryAssertions.assertRegistryEnumeratesAllStories(UserStoryTestRegistry)
end })

table.insert(suite.tests, { name = "G016 release honesty stays enforced", run = function()
    Assert.truthy(REQUIRED_RELEASE_ASSETS >= 500, "G018 must not lower the 500 unique Creator Store asset gate")
    Assert.falsy(manifestContainsSourceAssetId(BLOCKED_ASSET_ID), "blocked asset " .. BLOCKED_ASSET_ID .. " must not be reintroduced in AssetManifest.SourceAssets")
    StoryAssertions.requireProofTrue("G016ReleaseHonestyPreserved", "G016 final honesty gates remain failing until live proof, RBXL persistence, and 500 assets pass")
end })

table.insert(suite.tests, { name = "every G018 user story has fresh live PASS proof", run = function()
    for _, story in ipairs(UserStoryTestRegistry.all()) do
        StoryAssertions.assertStoryHasLivePass(story)
    end
end })

table.insert(suite.tests, { name = "fresh live play E2E matrix is attached", run = function()
    StoryAssertions.requireProofTrue("LivePlayE2EMatrixPassed", "US27-US36 live play proof matrix with non-empty evidence per row")
    Assert.equals(StoryAssertions.proofAttribute("LivePlayE2EMatrixMilestone"), "G018FinalGate", "live play matrix milestone")
    Assert.truthy(type(StoryAssertions.proofAttribute("LivePlayE2ERunId")) == "string", "live play E2E proof must include a run id")
    StoryAssertions.requireProofTrue("FreshAllCategoryTestRunnerPassed", "fresh all-category TestRunner with zero failures after G018 changes")
    Assert.equals(StoryAssertions.proofAttribute("FreshAllCategoryTestRunnerFailed"), 0, "fresh TestRunner failures")
end })

table.insert(suite.tests, { name = "publish blocker scan for asset 9922699889 is attached", run = function()
    StoryAssertions.requireProofTrue("PublishBlockerScanPassed", "fresh explicit scan for blocked asset id " .. BLOCKED_ASSET_ID)
    Assert.equals(StoryAssertions.proofAttribute("PublishBlockerScannedAssetId"), BLOCKED_ASSET_ID, "publish blocker scanned id")
    Assert.equals(StoryAssertions.proofAttribute("PublishBlockerAssetFound"), false, "blocked asset must not be found in live place or source scan")
    Assert.truthy(type(StoryAssertions.proofAttribute("PublishBlockerScanCommand")) == "string", "publish blocker proof must include command or harness name")
end })

table.insert(suite.tests, { name = "release asset count still reaches 500 live imported visible assets", run = function()
    local result = AssetImportAuditService:ValidateReleaseCounts(REQUIRED_RELEASE_ASSETS)
    Assert.truthy(result.passed,
        "release asset count is not shippable; " .. formatCounts(result.counts) ..
        "; failures=" .. table.concat(result.failures, "; "))
end })

return TestRunner.registerSuite(suite)
