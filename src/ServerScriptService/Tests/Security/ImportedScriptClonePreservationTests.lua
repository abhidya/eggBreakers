local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)

local suite = { name = "ImportedScriptClonePreservationTests.server", category = "Security", tests = {} }

local function cleanupTestFixtures()
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:GetAttribute("TestFixture") == true then
            child:Destroy()
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:GetAttribute("TestFixture") == true then
            child:Destroy()
        end
    end
end

local function withIsolatedImportedLibrary(callback)
    local realLibrary = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if realLibrary then
        realLibrary.Name = "_RealImportedAssetLibrary_ImportedScriptClonePreservation"
    end

    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage

    local quarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    if quarantine then
        quarantine.Name = "_RealImportedScriptQuarantine_ImportedScriptClonePreservation"
    end

    local ok, result = pcall(callback, library)

    cleanupTestFixtures()

    library:Destroy()

    local createdQuarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    if createdQuarantine then
        createdQuarantine:Destroy()
    end
    if quarantine then
        quarantine.Name = "ImportedScriptQuarantine"
    end
    if realLibrary then
        realLibrary.Name = "ImportedAssetLibrary"
    end

    if not ok then
        error(result, 2)
    end
    return result
end

local function makeVisibleSourceModel(name)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("TestFixture", true)
    model:SetAttribute("ImportedVisibleAsset", true)
    model:SetAttribute("CreatorStoreOnly", true)
    model:SetAttribute("RawImportedScriptPreserved", true)
    model:SetAttribute("ScriptReviewStatus", "raw_preserved_pending_adaptation")

    local body = Instance.new("Part")
    body.Name = "VisibleImportedBody"
    body.Size = Vector3.new(4, 3, 6)
    body.Transparency = 0
    body.Parent = model
    model.PrimaryPart = body

    return model
end

local function makeFixturePart(name, position)
    local part = Instance.new("Part")
    part.Name = name
    part.Position = position or Vector3.new(0, 3, 0)
    part:SetAttribute("TestFixture", true)
    return part
end

local function addRawRuntimeScript(parent, name)
    local runtimeScript = Instance.new("Script")
    runtimeScript.Name = name
    runtimeScript.Disabled = false
    runtimeScript.Parent = parent
    return runtimeScript
end

local function addRawModuleScript(parent, name)
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = name
    moduleScript.Parent = parent
    return moduleScript
end

local function findInQuarantine(scriptName)
    local quarantine = ReplicatedStorage:FindFirstChild("ImportedScriptQuarantine")
    return quarantine and quarantine:FindFirstChild(scriptName, true) or nil
end

local function assertRuntimeScriptPreservedOrQuarantined(clone, scriptName)
    local scriptClone = clone and clone:FindFirstChild(scriptName, true)
    local quarantined = findInQuarantine(scriptName)
    Assert.truthy(scriptClone ~= nil or quarantined ~= nil, scriptName .. " should be preserved for review or quarantined")

    local reviewedScript = scriptClone or quarantined
    if reviewedScript:IsA("Script") or reviewedScript:IsA("LocalScript") then
        Assert.truthy(
            reviewedScript.Disabled == true
                or reviewedScript:GetAttribute("ImportedScriptPreservedForReview") == true
                or reviewedScript:GetAttribute("ImportedScriptQuarantined") == true,
            scriptName .. " should be disabled, review-queued, or quarantine-stamped"
        )
    end
end

table.insert(suite.tests, { name = "MapLayoutService preserves raw scripts on imported food visual clones", run = function()
    withIsolatedImportedLibrary(function(library)
        local source = makeVisibleSourceModel("ImportedFernFoodVisual")
        source:SetAttribute("FoodKind", "StarterPlant")
        source:SetAttribute("Diet", "Herbivore")
        addRawRuntimeScript(source, "VendorFoodAnimationSource")
        source.Parent = library

        local queryPart = makeFixturePart("StarterPlantFoodQuery", Vector3.new(0, 3, 0))
        queryPart:SetAttribute("FoodKind", "StarterPlant")
        queryPart:SetAttribute("Diet", "Herbivore")
        queryPart.Parent = Workspace

        local clone = MapLayoutService:AttachImportedFoodVisual(queryPart, { kind = "StarterPlant", diet = "Herbivore" })

        Assert.notNil(clone, "food visual clone attaches")
        assertRuntimeScriptPreservedOrQuarantined(clone, "VendorFoodAnimationSource")

    end)
end })

table.insert(suite.tests, { name = "MapLayoutService quarantines raw modules from imported food visual clones", run = function()
    withIsolatedImportedLibrary(function(library)
        local source = makeVisibleSourceModel("ImportedFernFoodVisualWithModule")
        source:SetAttribute("FoodKind", "StarterPlant")
        source:SetAttribute("Diet", "Herbivore")
        addRawModuleScript(source, "VendorFoodUtilitySource")
        source.Parent = library

        local queryPart = makeFixturePart("StarterPlantFoodQueryWithModule", Vector3.new(0, 3, 0))
        queryPart:SetAttribute("FoodKind", "StarterPlant")
        queryPart:SetAttribute("Diet", "Herbivore")
        queryPart.Parent = Workspace

        local clone = MapLayoutService:AttachImportedFoodVisual(queryPart, { kind = "StarterPlant", diet = "Herbivore" })
        local quarantined = findInQuarantine("VendorFoodUtilitySource")

        Assert.notNil(clone, "food visual clone attaches")
        Assert.equals(clone:FindFirstChild("VendorFoodUtilitySource", true), nil, "raw module is removed from runtime clone")
        Assert.notNil(quarantined, "raw module source is preserved in ImportedScriptQuarantine")
        Assert.equals(quarantined:GetAttribute("ImportedScriptQuarantined"), true, "raw module receives quarantine stamp")
        Assert.equals(quarantined:GetAttribute("ScriptReviewStatus"), "module_preserved_pending_adaptation", "raw module remains queued for adaptation")
    end)
end })

table.insert(suite.tests, { name = "MapLayoutService preserves raw scripts on imported dressing clones", run = function()
    withIsolatedImportedLibrary(function(library)
        local source = makeVisibleSourceModel("ImportedFernDressing")
        addRawRuntimeScript(source, "VendorDressingSwaySource")
        source.Parent = library

        local anchor = makeFixturePart("FernDressingAnchor", Vector3.new(0, 3, 0))
        anchor.Parent = Workspace

        local clone = MapLayoutService:AttachImportedDressingVisual(anchor, {
            name = "FernDressing",
            zone = "FernPlains",
            kind = "Tree",
            size = Vector3.new(10, 12, 10),
            canopySize = Vector3.new(10, 12, 10),
        }, "ImportedBiomeDressing")

        Assert.notNil(clone, "dressing visual clone attaches")
        assertRuntimeScriptPreservedOrQuarantined(clone, "VendorDressingSwaySource")

    end)
end })

table.insert(suite.tests, { name = "NPCSpawnService preserves raw scripts on prepared NPC clones", run = function()
    local ok, err = pcall(function()
        local source = makeVisibleSourceModel("ImportedParasaurolophusPrey")
        addRawRuntimeScript(source, "VendorNpcBehaviorSource")
        source.Parent = Workspace

        local spawn = makeFixturePart("NPCSpawnAnchor", Vector3.new(0, 12, 0))
        spawn.Parent = Workspace

        local clone = NPCSpawnService:PrepareNPCModel(source, "Prey", 3201, spawn)
        if clone then clone:SetAttribute("TestFixture", true) end

        Assert.notNil(clone, "prepared NPC clone exists")
        assertRuntimeScriptPreservedOrQuarantined(clone, "VendorNpcBehaviorSource")
    end)
    cleanupTestFixtures()
    if not ok then error(err, 2) end
end })

table.insert(suite.tests, { name = "CharacterVisualService preserves raw scripts on prepared egg visual clones", run = function()
    local ok, err = pcall(function()
        local source = makeVisibleSourceModel("ImportedEggVisualSource")
        addRawRuntimeScript(source, "VendorEggIdleSource")
        source.Parent = Workspace

        local clone = CharacterVisualService:_prepareVisualClone(source, CharacterVisualService.EggVisualName)
        if clone then clone:SetAttribute("TestFixture", true) end

        Assert.notNil(clone, "prepared egg clone exists")
        assertRuntimeScriptPreservedOrQuarantined(clone, "VendorEggIdleSource")
    end)
    cleanupTestFixtures()
    if not ok then error(err, 2) end
end })

table.insert(suite.tests, { name = "CharacterVisualService preserves raw scripts on prepared dinosaur visual clones", run = function()
    local ok, err = pcall(function()
        local source = makeVisibleSourceModel("ImportedDinosaurVisualSource")
        addRawRuntimeScript(source, "VendorDinosaurIdleSource")
        source.Parent = Workspace

        local clone = CharacterVisualService:_prepareDinosaurClone(source, { SpeciesId = "parasaurolophus", Growth = 0 })
        if clone then clone:SetAttribute("TestFixture", true) end

        Assert.notNil(clone, "prepared dinosaur clone exists")
        assertRuntimeScriptPreservedOrQuarantined(clone, "VendorDinosaurIdleSource")
    end)
    cleanupTestFixtures()
    if not ok then error(err, 2) end
end })

table.insert(suite.tests, { name = "NPCService preserves raw scripts on carcass clones", run = function()
    withIsolatedImportedLibrary(function(library)
        local source = makeVisibleSourceModel("ImportedBoneCarcassVisual")
        addRawRuntimeScript(source, "VendorCarcassAmbienceSource")
        source.Parent = library

        local npc = Instance.new("Model")
        npc.Name = "PreyForCarcassScriptReview"
        npc:SetAttribute("TestFixture", true)
        local root = Instance.new("Part")
        root.Name = "Root"
        root.Position = Vector3.new(0, 3, 0)
        root.Parent = npc
        npc.PrimaryPart = root
        npc.Parent = Workspace

        local carcass = NPCService:CreateCarcassFoodSource(npc, 35)
        if carcass then carcass:SetAttribute("TestFixture", true) end

        Assert.notNil(carcass, "carcass clone exists")
        assertRuntimeScriptPreservedOrQuarantined(carcass, "VendorCarcassAmbienceSource")
    end)
end })

return TestRunner.registerSuite(suite)
