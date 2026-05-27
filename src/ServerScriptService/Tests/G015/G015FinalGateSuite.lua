local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetAuditService = require(ServerScriptService.Services.AssetAuditService)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)

local suite = { name = "G015FinalGate", category = "G015FinalGate", tests = {} }

local REQUIRED_RELEASE_ASSETS = AssetManifest.MinimumUniqueAssets or 500

local function proofFolder()
    return ReplicatedStorage:FindFirstChild("G015FinalGateProof")
end

local function proofAttribute(name)
    local folder = proofFolder()
    return folder and folder:GetAttribute(name)
end

local function failMissingProof(attributeName, expectedDescription)
    Assert.truthy(false,
        "missing G015FinalGateProof." .. attributeName .. " proof; expected " .. expectedDescription ..
        " from a fresh, externally observed release run, not a catalog/source assumption")
end

local function requireProofTrue(attributeName, expectedDescription)
    if proofAttribute(attributeName) ~= true then
        failMissingProof(attributeName, expectedDescription)
    end
end

local function formatCounts(counts)
    return "cataloged=" .. tostring(counts.catalogedSourceAssetIds) ..
        ", actuallyImported=" .. tostring(counts.actuallyImportedAssets) ..
        ", audited=" .. tostring(counts.auditedImportedAssets) ..
        ", tagged=" .. tostring(counts.taggedImportedAssets) ..
        ", placedVisible=" .. tostring(counts.placedVisibleAssets) ..
        ", releaseReadyVisible=" .. tostring(counts.releaseReadyVisibleAssets)
end

local function childNamed(parent, name)
    return parent and parent:FindFirstChild(name) ~= nil
end

table.insert(suite.tests, { name = "G015 gate files are present and isolated", run = function()
    local testsFolder = ServerScriptService:FindFirstChild("Tests")
    local g015Folder = testsFolder and testsFolder:FindFirstChild("G015")
    Assert.truthy(childNamed(g015Folder, "G015FinalGate"), "missing G015FinalGate.server.lua")
    Assert.truthy(childNamed(g015Folder, "G015FinalGateSuite"), "missing G015FinalGateSuite.lua")
end })

table.insert(suite.tests, { name = "release asset count reaches 500 live imported visible assets", run = function()
    local result = AssetImportAuditService:ValidateReleaseCounts(REQUIRED_RELEASE_ASSETS)
    Assert.truthy(result.passed,
        "release asset count is not shippable; " .. formatCounts(result.counts) ..
        "; failures=" .. table.concat(result.failures, "; "))
end })

table.insert(suite.tests, { name = "fresh all-category TestRunner proof is attached", run = function()
    requireProofTrue("FreshAllCategoryTestRunnerPassed", "all-category TestRunner run with zero failures")
    Assert.equals(proofAttribute("FreshAllCategoryTestRunnerMilestone"), "G015FinalGate", "fresh TestRunner milestone")
    Assert.truthy((proofAttribute("FreshAllCategoryTestRunnerTotal") or 0) > 0, "fresh TestRunner total must be positive")
    Assert.equals(proofAttribute("FreshAllCategoryTestRunnerFailed"), 0, "fresh TestRunner failures")
end })

table.insert(suite.tests, { name = "mobile device or touch-controller proof is attached", run = function()
    requireProofTrue("MobileProofPassed", "touch/mobile-controller Studio or device smoke proof")
    Assert.truthy(type(proofAttribute("MobileProofDevice")) == "string", "mobile proof must name the tested device or emulator profile")
end })

table.insert(suite.tests, { name = "RBXL save reopen persistence proof is attached", run = function()
    requireProofTrue("RBXLPersistencePassed", ".rbxl save, close/reopen, and re-audit proof")
    Assert.truthy(type(proofAttribute("RBXLPersistenceReopenAuditTimestamp")) == "string", "RBXL persistence proof must include reopen audit timestamp")
end })

table.insert(suite.tests, { name = "release placeholder sweep is clean and proven", run = function()
    local scan = AssetAuditService:ScanWorkspace()
    Assert.truthy(scan.passed,
        "workspace placeholder scan failed: " .. table.concat(scan.failures, "; "))
    requireProofTrue("PlaceholderSweepPassed", "release sweep showing no generic visible Parts, TODO/blockout/temp placeholders, or debug fallbacks")
end })

table.insert(suite.tests, { name = "user story matrix is fully passing", run = function()
    Assert.equals(proofAttribute("UserStoryMatrixStatus"), "PASS",
        "G015 user story matrix must be explicitly updated to PASS only after every story row is PASS")
    Assert.truthy((proofAttribute("UserStoryMatrixPassingRows") or 0) >= 15, "expected at least 15 passing user-story rows")
    Assert.equals(proofAttribute("UserStoryMatrixFailingRows"), 0, "user-story matrix failing rows")
    Assert.equals(proofAttribute("UserStoryMatrixBlockedRows"), 0, "user-story matrix blocked rows")
end })

return TestRunner.registerSuite(suite)
