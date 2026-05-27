local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)

local UserStoryTestRegistry = require(script.Parent.UserStoryTestRegistry)
local StoryAssertions = require(script.Parent.StoryAssertions)

local suite = { name = "G016FinalGate", category = "G016FinalGate", tests = {} }
local REQUIRED_RELEASE_ASSETS = AssetManifest.MinimumUniqueAssets or 500

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

table.insert(suite.tests, { name = "G016 gate files are present and isolated", run = function()
    local testsFolder = ServerScriptService:FindFirstChild("Tests")
    local g016Folder = testsFolder and testsFolder:FindFirstChild("G016")
    Assert.truthy(childNamed(g016Folder, "G016FinalGate"), "missing G016FinalGate.server.lua")
    Assert.truthy(childNamed(g016Folder, "G016FinalGateSuite"), "missing G016FinalGateSuite.lua")
    Assert.truthy(childNamed(g016Folder, "UserStoryTestRegistry"), "missing UserStoryTestRegistry.lua")
    Assert.truthy(childNamed(g016Folder, "StoryAssertions"), "missing StoryAssertions.lua")
end })

table.insert(suite.tests, { name = "UserStoryTestRegistry enumerates US01-US15", run = function()
    StoryAssertions.assertRegistryEnumeratesAllStories(UserStoryTestRegistry)
end })

table.insert(suite.tests, { name = "every user story has fresh live PASS proof", run = function()
    for _, story in ipairs(UserStoryTestRegistry.all()) do
        StoryAssertions.assertStoryHasLivePass(story)
    end
end })

table.insert(suite.tests, { name = "fresh all-category TestRunner proof is attached", run = function()
    StoryAssertions.requireProofTrue("FreshAllCategoryTestRunnerPassed", "all-category TestRunner run with every required category non-empty and zero failures")
    Assert.equals(StoryAssertions.proofAttribute("FreshAllCategoryTestRunnerMilestone"), "G016FinalGate", "fresh TestRunner milestone")
    Assert.truthy((StoryAssertions.proofAttribute("FreshAllCategoryTestRunnerTotal") or 0) > 0, "fresh TestRunner total must be positive")
    Assert.equals(StoryAssertions.proofAttribute("FreshAllCategoryTestRunnerFailed"), 0, "fresh TestRunner failures")
    Assert.equals(StoryAssertions.proofAttribute("FreshAllCategoryClientSuitesMissing"), 0, "client category must not be empty")
end })

table.insert(suite.tests, { name = "mobile controller and live E2E proof are attached", run = function()
    StoryAssertions.requireProofTrue("MobileControllerProofPassed", "touch/mobile/controller play proof for EatDrink, Attack, Sprint, Call, and RestHide")
    StoryAssertions.requireProofTrue("LiveE2EProofPassed", "live hatch-to-play loop proving visible dinosaur, food/water, combat, death/respawn, and button feedback")
    Assert.truthy(type(StoryAssertions.proofAttribute("LiveE2EProofRunId")) == "string", "live E2E proof must include a run id")
end })

table.insert(suite.tests, { name = "RBXL save reopen persistence proof is attached", run = function()
    StoryAssertions.requireProofTrue("RBXLPersistencePassed", ".rbxl save, close/reopen, and re-audit proof")
    Assert.truthy(type(StoryAssertions.proofAttribute("RBXLPersistenceReopenAuditTimestamp")) == "string", "RBXL persistence proof must include reopen audit timestamp")
end })

table.insert(suite.tests, { name = "release asset count reaches 500 live imported visible assets", run = function()
    local result = AssetImportAuditService:ValidateReleaseCounts(REQUIRED_RELEASE_ASSETS)
    Assert.truthy(result.passed,
        "release asset count is not shippable; " .. formatCounts(result.counts) ..
        "; failures=" .. table.concat(result.failures, "; "))
end })

return TestRunner.registerSuite(suite)
