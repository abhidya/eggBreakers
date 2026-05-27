local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local Registry = require(script.Parent.G018UserStoryTestRegistry)

local suite = { name = "G018FinalGate", category = "G018FinalGate", tests = {} }
local REQUIRED_RELEASE_ASSETS = AssetManifest.MinimumUniqueAssets or 500

local function proofFolder()
    return ReplicatedStorage:FindFirstChild("G018FinalGateProof")
end

local function proofAttribute(name)
    local folder = proofFolder()
    return folder and folder:GetAttribute(name)
end

local function requireProofTrue(attributeName, expectedDescription)
    Assert.equals(proofAttribute(attributeName), true,
        "missing G018FinalGateProof." .. attributeName .. " proof; expected " .. expectedDescription ..
        " from fresh Studio/live evidence, not docs-only assumptions")
end

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

table.insert(suite.tests, { name = "G018 gate files are present and isolated", run = function()
    local testsFolder = ServerScriptService:FindFirstChild("Tests")
    local g018Folder = testsFolder and testsFolder:FindFirstChild("G018")
    Assert.truthy(childNamed(g018Folder, "G018FinalGate"), "missing G018FinalGate.server.lua")
    Assert.truthy(childNamed(g018Folder, "G018FinalGateSuite"), "missing G018FinalGateSuite.lua")
    Assert.truthy(childNamed(g018Folder, "G018UserStoryTestRegistry"), "missing G018UserStoryTestRegistry.lua")
    Assert.truthy(childNamed(g018Folder, "G018EcosystemProfileTests"), "missing G018EcosystemProfileTests.lua")
end })

table.insert(suite.tests, { name = "G018 registry enumerates ecosystem expansion stories", run = function()
    local stories = Registry.all()
    Assert.equals(#stories, 11, "G018 registry must enumerate 11 ecosystem stories")
    local seen = {}
    for index, story in ipairs(stories) do
        Assert.equals(story.id, string.format("G018-US%02d", index), "G018 story order/id contract")
        Assert.falsy(seen[story.id], "duplicate story id " .. tostring(story.id))
        seen[story.id] = true
        Assert.truthy(type(story.title) == "string" and #story.title > 0, story.id .. " title required")
        Assert.truthy(type(story.required) == "table" and #story.required > 0, story.id .. " required categories missing")
        Assert.truthy(type(story.liveProof) == "string" and #story.liveProof > 0, story.id .. " live proof attr missing")
    end
end })

table.insert(suite.tests, { name = "shared G018 profile plumbing exists", run = function()
    for _, species in pairs(SpeciesConfig) do
        Assert.notNil(species.CreatureCategory, "CreatureCategory required")
        Assert.notNil(species.EcosystemProfile, "EcosystemProfile required")
        Assert.notNil(species.MovementModes, "MovementModes required")
        for _, stats in pairs(species.BaseStats) do
            Assert.truthy((stats.MaxOxygen or 0) > 0, "MaxOxygen required")
            Assert.truthy((stats.StaminaRegen or 0) > 0, "StaminaRegen required")
            Assert.notNil(stats.FlightStaminaDrain, "FlightStaminaDrain required")
        end
    end
    local payload = RemoteContracts.StatUpdate.Payload
    Assert.truthy(table.find(payload, "oxygen") ~= nil, "StatUpdate oxygen required")
    Assert.truthy(table.find(payload, "creatureCategory") ~= nil, "StatUpdate creatureCategory required")
    Assert.truthy(table.find(payload, "ecosystemProfile") ~= nil, "StatUpdate ecosystemProfile required")
end })

table.insert(suite.tests, { name = "fresh live proof matrix is attached", run = function()
    for _, story in ipairs(Registry.all()) do
        requireProofTrue(story.liveProof, story.id .. " " .. story.title)
        Assert.equals(proofAttribute(story.id .. "Status"), "PASS", story.id .. " status must be PASS only after live proof")
        Assert.truthy(type(proofAttribute(story.id .. "Evidence")) == "string", story.id .. " evidence required")
    end
end })

table.insert(suite.tests, { name = "fresh all-category TestRunner and mobile/client proof are attached", run = function()
    requireProofTrue("FreshAllCategoryTestRunnerPassed", "all-category TestRunner run with zero failures")
    Assert.equals(proofAttribute("FreshAllCategoryTestRunnerMilestone"), "G018FinalGate", "fresh TestRunner milestone")
    Assert.equals(proofAttribute("FreshAllCategoryTestRunnerFailed"), 0, "fresh TestRunner failures")
    requireProofTrue("MobileClientProofPassed", "touch/mobile/controller proof for G018 HUD oxygen/profile guidance")
    requireProofTrue("LiveE2EProofPassed", "live ecosystem E2E proof for prey/fish/water/grazing/apex/herding")
    requireProofTrue("RBXLPersistencePassed", ".rbxl save/reopen persistence after G018 changes")
end })

table.insert(suite.tests, { name = "publish blocker asset id 9922699889 remains absent from release place", run = function()
    requireProofTrue("PublishBlocker9922699889ScanPassed", "fresh text plus rbxl strings scan showing blocked id absent")
    Assert.truthy(type(proofAttribute("PublishBlocker9922699889ScanCommand")) == "string", "scan command required")
end })

table.insert(suite.tests, { name = "release asset count still enforces 500 live imported visible assets", run = function()
    local result = AssetImportAuditService:ValidateReleaseCounts(REQUIRED_RELEASE_ASSETS)
    Assert.truthy(result.passed,
        "release asset count is not shippable; " .. formatCounts(result.counts) ..
        "; failures=" .. table.concat(result.failures, "; "))
end })

return TestRunner.registerSuite(suite)
