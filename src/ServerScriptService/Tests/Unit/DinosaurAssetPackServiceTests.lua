local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local ImportedScriptPolicy = require(ReplicatedStorage.Shared.ImportedScriptPolicy)
local DinosaurAssetPackService = require(ServerScriptService.Services.DinosaurAssetPackService)

local suite = { name = "DinosaurAssetPackServiceTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "asset pack stamping preserves scripts for review and records mesh count", run = function()
    local root = Instance.new("Folder")
    root.Name = "DinosaurAssetPackServiceFixture"
    local mesh = Instance.new("MeshPart")
    mesh.Name = "Allosaurus"
    mesh.Parent = root
    local scriptInstance = Instance.new("Script")
    scriptInstance.Name = "RawImportedBrain"
    scriptInstance.Disabled = false
    scriptInstance.Parent = root
    local module = Instance.new("ModuleScript")
    module.Name = "RawImportedConfig"
    module.Parent = root

    DinosaurAssetPackService:StampPackContents(root, {
        AssetId = 8289268262,
        RootName = root.Name,
        AssetManifestId = "G033_TestPack",
        ImportedVisibleAsset = true,
        DinosaurRosterPack = true,
        UseAsDinoVisualHappyPath = true,
        PlacementRole = "DinosaurRosterMeshPack",
        ScriptReviewSourceUse = "unit_test_dinosaur_pack",
    })

    Assert.equals(root:GetAttribute("SourceAssetId"), "8289268262", "source asset stamped")
    Assert.equals(root:GetAttribute("DinosaurRosterPack"), true, "pack root marked as roster pack")
    Assert.equals(root:GetAttribute("UseAsDinoVisualHappyPath"), true, "happy-path marker stamped")
    Assert.equals(root:GetAttribute("MeshPartCount"), 1, "mesh count recorded")
    Assert.equals(root:GetAttribute("SourceScriptCount"), 2, "script count recorded")
    Assert.equals(scriptInstance.Disabled, true, "executable imported script disabled for review")
    Assert.equals(ImportedScriptPolicy.IsRawScriptReviewQueue(scriptInstance), true, "script is preserved for review")
    Assert.equals(ImportedScriptPolicy.IsRawScriptReviewQueue(module), true, "module is preserved for review")

    root:Destroy()
end })

return TestRunner.registerSuite(suite)
