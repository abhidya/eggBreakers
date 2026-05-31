local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local StagedMeshLibrary = require(ReplicatedStorage.Shared.StagedMeshLibrary)

local suite = { name = "StoryboardBeatValidation.server", category = "Placement", tests = {} }

local function getOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local function countVisibleParts(root, predicate)
    local count = 0
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 and (not predicate or predicate(descendant)) then
            count = count + 1
        end
    end
    return count
end

local function countVisibleMeshParts(root)
    return countVisibleParts(root, function(part)
        return part:IsA("MeshPart")
    end)
end

local function countVisibleHelperParts(root)
    return countVisibleParts(root, function(part)
        local name = string.lower(part.Name)
        return name == "rootpart"
            or name == "humanoidrootpart"
            or string.find(name, "helper", 1, true) ~= nil
            or string.find(name, "hitbox", 1, true) ~= nil
            or string.find(name, "collider", 1, true) ~= nil
            or string.find(name, "collision", 1, true) ~= nil
            or string.find(name, "bounds", 1, true) ~= nil
            or string.find(name, "bounding", 1, true) ~= nil
    end)
end

local function makeStagedDinosaur(folderName, modelName, sourceAssetId)
    local source = Instance.new("Model")
    source.Name = modelName
    source:SetAttribute("SourceAssetId", sourceAssetId)
    source:SetAttribute("ImportedVisibleAsset", true)
    source:SetAttribute("CreatorStoreOnly", true)

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(42, 42, 42)
    root.Transparency = 0
    root.Parent = source

    local body = Instance.new("MeshPart")
    body.Name = "VisibleBodyMesh"
    body.Size = Vector3.new(6, 4, 12)
    body.Transparency = 0
    body.Parent = source

    local controller = Instance.new("AnimationController")
    controller.Parent = source
    source.PrimaryPart = root

    local rootFolder = getOrCreateFolder(workspace, StagedMeshLibrary.StagingFolderName)
    local dietFolder = getOrCreateFolder(rootFolder, folderName)
    source.Parent = dietFolder
    return source, rootFolder
end

local function makeSpawnMarker(name, kind)
    local marker = Instance.new("Part")
    marker.Name = name
    marker.Position = Vector3.new(0, 20, 0)
    marker:SetAttribute("NPCKind", kind)
    marker.Parent = workspace
    return marker
end

table.insert(suite.tests, { name = "Beat 0 hatched baby uses staged mesh and hides helper boxes", run = function()
    local oldStagingFolderName = StagedMeshLibrary.StagingFolderName
    local oldGallimimusEntry = StagedMeshLibrary.SpeciesMesh.gallimimus
    StagedMeshLibrary.StagingFolderName = "StoryboardBeatValidation_PlayerMeshes_" .. tostring(math.floor(os.clock() * 1000000))
    StagedMeshLibrary.SpeciesMesh.gallimimus = {
        folder = "Herbivores (land)",
        name = "GallimimusStoryboardProbe",
    }

    local stagingRoot
    local character
    local ok, err = pcall(function()
        stagingRoot = select(2, makeStagedDinosaur("Herbivores (land)", "GallimimusStoryboardProbe", "storyboard-player-mesh"))

        character = Instance.new("Model")
        character.Name = "StoryboardBeat0Character"
        local humanoidRoot = Instance.new("Part")
        humanoidRoot.Name = "HumanoidRootPart"
        humanoidRoot.Size = Vector3.new(2, 2, 1)
        humanoidRoot.CFrame = CFrame.new(0, 8, 0)
        humanoidRoot.Parent = character
        character.PrimaryPart = humanoidRoot
        character.Parent = workspace

        local player = { Character = character }
        local applied, reason = CharacterVisualService:ApplyForState(player, {
            Hatched = true,
            SpeciesId = "gallimimus",
            GrowthStage = "Hatchling",
        })

        Assert.equals(applied, true, "hatched Beat 0 visual applies")
        Assert.equals(reason, "staged_dinosaur_mesh", "staged baby dinosaur mesh wins before fallback placeholders")
        local visualFolder = character:FindFirstChild(CharacterVisualService.VisualFolderName)
        Assert.notNil(visualFolder, "character visual folder exists")
        local dinosaurVisual = visualFolder:FindFirstChild(CharacterVisualService.DinosaurVisualName)
        Assert.notNil(dinosaurVisual, "dinosaur visual exists")
        Assert.equals(dinosaurVisual:GetAttribute("VisualKind"), "ImportedDinosaur", "baby visual is classified as imported/staged")
        Assert.equals(dinosaurVisual:GetAttribute("ImportedVisual"), true, "baby visual carries imported marker")
        Assert.truthy(countVisibleMeshParts(dinosaurVisual) >= 1, "baby dinosaur has a visible MeshPart body")
        Assert.equals(countVisibleHelperParts(dinosaurVisual), 0, "RootPart/helper boxes stay invisible")
    end)

    if character then character:Destroy() end
    if stagingRoot then stagingRoot:Destroy() end
    StagedMeshLibrary.SpeciesMesh.gallimimus = oldGallimimusEntry
    StagedMeshLibrary.StagingFolderName = oldStagingFolderName
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "Beat 0 egg/nest visual is imported when source is present", run = function()
    local library = getOrCreateFolder(ReplicatedStorage, "ImportedAssetLibrary")
    local oldImported = library:FindFirstChild("Imported_Egg_Nest")
    if oldImported then oldImported.Parent = nil end

    local importedNest
    local character
    local ok, err = pcall(function()
        importedNest = Instance.new("Model")
        importedNest.Name = "Imported_Egg_Nest"
        importedNest:SetAttribute("SourceAssetId", "8895193")
        importedNest:SetAttribute("ImportedVisibleAsset", true)
        importedNest:SetAttribute("CreatorStoreOnly", true)
        local egg = Instance.new("MeshPart")
        egg.Name = "Egg"
        egg.Size = Vector3.new(3, 4, 3)
        egg.Transparency = 0
        egg.Parent = importedNest
        importedNest.PrimaryPart = egg
        importedNest.Parent = library

        character = Instance.new("Model")
        character.Name = "StoryboardBeat0EggCharacter"
        local humanoidRoot = Instance.new("Part")
        humanoidRoot.Name = "HumanoidRootPart"
        humanoidRoot.CFrame = CFrame.new(0, 8, 0)
        humanoidRoot.Parent = character
        character.PrimaryPart = humanoidRoot
        character.Parent = workspace

        local source = CharacterVisualService:ResolveImportedEggModel()
        Assert.equals(source, importedNest:FindFirstChild("Egg"), "egg/nest source resolves when imported marker exists")

        local applied, reason = CharacterVisualService:ApplyForState({ Character = character }, {
            Hatched = false,
            SpeciesId = "gallimimus",
            GrowthStage = "Hatchling",
        })
        Assert.equals(applied, true, "unhatched Beat 0 egg visual applies")
        Assert.equals(reason, "imported_egg", "imported egg/nest source is used instead of a primitive egg placeholder")

        local visual = character:FindFirstChild(CharacterVisualService.VisualFolderName)
            and character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.EggVisualName)
        Assert.notNil(visual, "egg visual exists")
        Assert.equals(visual:GetAttribute("VisualKind"), "ImportedEgg", "egg visual carries imported classification")
        Assert.equals(visual:GetAttribute("ImportedVisual"), true, "egg visual carries imported marker")
        Assert.truthy(type(visual:GetAttribute("SourcePath")) == "string", "egg visual records imported source path")
        Assert.truthy(countVisibleMeshParts(visual) >= 1, "egg/nest imported visual exposes MeshPart geometry")
    end)

    if character then character:Destroy() end
    if importedNest then importedNest:Destroy() end
    if oldImported then oldImported.Parent = library end
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "Beats 1-2 starter food and carcasses are readable classified visuals", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureFoodSourcePlacements(folders)

    local readableHerbivore = 0
    local readableCarnivore = 0
    for _, zoneName in ipairs({ "NurseryGrove", "FernPlains" }) do
        local zoneFolder = folders.FoodSources:FindFirstChild(zoneName)
        Assert.notNil(zoneFolder, zoneName .. " food folder exists")
        for _, food in ipairs(zoneFolder:GetChildren()) do
            if food:IsA("BasePart") and food:GetAttribute("StarterFood") == true then
                local diet = food:GetAttribute("Diet")
                Assert.equals(food:GetAttribute("GameplayQuery"), true, food.Name .. " is the interaction query")
                Assert.equals(food.Transparency, 1, food.Name .. " query part is hidden, not a visible placeholder block")
                Assert.truthy(diet == "Herbivore" or diet == "Carnivore", food.Name .. " has diet classification")

                local affordanceCount = 0
                local importedCount = 0
                local fallbackCount = 0
                local classificationCount = 0
                for _, descendant in ipairs(food:GetDescendants()) do
                    if descendant:IsA("BasePart") and descendant.Transparency < 1 then
                        affordanceCount = affordanceCount + 1
                        Assert.equals(descendant.CanQuery, false, descendant.Name .. " is visual-only")
                        if descendant:GetAttribute("ImportedVisibleAsset") == true then
                            importedCount = importedCount + 1
                            Assert.equals(descendant:GetAttribute("CreatorStoreOnly"), true, descendant.Name .. " imported affordance is Creator Store sourced")
                            Assert.truthy(type(descendant:GetAttribute("SourceAssetId")) == "string", descendant.Name .. " imported affordance records SourceAssetId")
                        elseif descendant:GetAttribute("VisibleGameplayAffordance") == true then
                            fallbackCount = fallbackCount + 1
                            Assert.equals(descendant:GetAttribute("ProceduralGameplayVisual"), true, descendant.Name .. " fallback is explicitly procedural")
                            Assert.equals(descendant:GetAttribute("ReleaseVisibleGeneratedPartAllowed"), true, descendant.Name .. " fallback has release approval metadata")
                            Assert.truthy(type(descendant:GetAttribute("ReleaseVisibleGeneratedPartReason")) == "string", descendant.Name .. " fallback explains why it is allowed")
                        end
                        local visualName = string.lower(descendant.Name)
                        if diet == "Herbivore" and (string.find(visualName, "foliage", 1, true) or string.find(visualName, "frond", 1, true)) then
                            classificationCount = classificationCount + 1
                        elseif diet == "Carnivore" and (string.find(visualName, "carcass", 1, true) or string.find(visualName, "bone", 1, true) or string.find(visualName, "rib", 1, true)) then
                            classificationCount = classificationCount + 1
                        end
                    end
                end

                Assert.truthy(affordanceCount >= 3, food.Name .. " has multiple readable visual affordance parts")
                Assert.truthy(importedCount + fallbackCount == affordanceCount, food.Name .. " every visible affordance is imported or approved fallback")
                Assert.truthy(classificationCount >= 2, food.Name .. " visual names classify as fern/frond or carcass/bone")
                if diet == "Herbivore" then
                    readableHerbivore = readableHerbivore + 1
                    Assert.equals(food:GetAttribute("EdibleVegetation"), true, food.Name .. " is marked edible vegetation")
                    Assert.truthy(type(food:GetAttribute("VegetationType")) == "string", food.Name .. " has vegetation type")
                else
                    readableCarnivore = readableCarnivore + 1
                    Assert.equals(food:GetAttribute("PotentialCarnivoreFood"), true, food.Name .. " is marked as carnivore food")
                    Assert.truthy(type(food:GetAttribute("MeatType")) == "string", food.Name .. " has meat/carcass type")
                end
            end
        end
    end

    Assert.truthy(readableHerbivore >= 8, "Beat 1 has dense readable herbivore starter food")
    Assert.truthy(readableCarnivore >= 4, "Beat 2 has readable carnivore carcass food")
end })

table.insert(suite.tests, { name = "Beats 1-2 prey and predator NPCs use MeshParts when staged sources exist", run = function()
    local oldRecords = NPCService.NPCs
    local oldStagingFolderName = StagedMeshLibrary.StagingFolderName
    local oldGallimimusEntry = StagedMeshLibrary.SpeciesMesh.gallimimus
    local oldCarnotaurusEntry = StagedMeshLibrary.SpeciesMesh.carnotaurus
    NPCService.NPCs = {}
    StagedMeshLibrary.StagingFolderName = "StoryboardBeatValidation_NPCMeshes_" .. tostring(math.floor(os.clock() * 1000000))
    StagedMeshLibrary.SpeciesMesh.gallimimus = {
        folder = "Herbivores (land)",
        name = "GallimimusPreyStoryboardProbe",
    }
    StagedMeshLibrary.SpeciesMesh.carnotaurus = {
        folder = "Carnivores (land)",
        name = "CarnotaurusPredatorStoryboardProbe",
    }

    local stagingRoot
    local preyMarker
    local predatorMarker
    local preyRecord
    local predatorRecord
    local ok, err = pcall(function()
        local _, firstRoot = makeStagedDinosaur("Herbivores (land)", "GallimimusPreyStoryboardProbe", "storyboard-prey-mesh")
        stagingRoot = firstRoot
        makeStagedDinosaur("Carnivores (land)", "CarnotaurusPredatorStoryboardProbe", "storyboard-predator-mesh")
        preyMarker = makeSpawnMarker("StoryboardPreySpawn", "Prey")
        predatorMarker = makeSpawnMarker("StoryboardPredatorSpawn", "Predator")

        local preyOk
        preyOk, preyRecord = NPCSpawnService:CreateNPCRecord(preyMarker, "Prey", 9201)
        Assert.equals(preyOk, true, "prey NPC spawns from staged source")
        local predatorOk
        predatorOk, predatorRecord = NPCSpawnService:CreateNPCRecord(predatorMarker, "Predator", 9202)
        Assert.equals(predatorOk, true, "predator NPC spawns from staged source")

        for _, record in ipairs({ preyRecord, predatorRecord }) do
            local npc = record.Instance
            local kind = npc:GetAttribute("NPCKind")
            Assert.truthy(kind == "Prey" or kind == "Predator", "storyboard NPC kind is prey/predator")
            Assert.equals(npc:GetAttribute("ImportedVisibleAsset"), true, kind .. " NPC carries imported/staged marker")
            Assert.equals(npc:GetAttribute("CreatorStoreOnly"), true, kind .. " NPC carries Creator Store marker")
            Assert.truthy(type(npc:GetAttribute("SourceAssetId")) == "string", kind .. " NPC preserves staged SourceAssetId")
            Assert.truthy(NPCSpawnService:CountMeshParts(npc) >= 1, kind .. " NPC uses MeshPart body when staged source exists")
            Assert.equals(countVisibleHelperParts(npc), 0, kind .. " NPC helper/root boxes stay invisible")
        end
    end)

    if preyRecord and preyRecord.Instance then preyRecord.Instance:Destroy() end
    if predatorRecord and predatorRecord.Instance then predatorRecord.Instance:Destroy() end
    if preyMarker then preyMarker:Destroy() end
    if predatorMarker then predatorMarker:Destroy() end
    if stagingRoot then stagingRoot:Destroy() end
    StagedMeshLibrary.SpeciesMesh.gallimimus = oldGallimimusEntry
    StagedMeshLibrary.SpeciesMesh.carnotaurus = oldCarnotaurusEntry
    StagedMeshLibrary.StagingFolderName = oldStagingFolderName
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

TestRunner.registerSuite(suite)
return suite
