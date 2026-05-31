local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local StatReplicationService = require(ServerScriptService.Services.StatReplicationService)
local FishService = require(ServerScriptService.Services.FishService)
local WaterService = require(ServerScriptService.Services.WaterService)
local NestService = require(ServerScriptService.Services.NestService)
local RateLimitService = require(ServerScriptService.Services.RateLimitService)
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

local function makeNPCModel(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(3, 3, 3)
    root.CFrame = CFrame.new(position)
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model
end

table.insert(suite.tests, { name = "Beat 0 hatched baby uses staged mesh and hides helper boxes", run = function()
    local oldStagingFolderName = StagedMeshLibrary.StagingFolderName
    local oldParasaurolophusEntry = StagedMeshLibrary.SpeciesMesh.parasaurolophus
    StagedMeshLibrary.StagingFolderName = "StoryboardBeatValidation_PlayerMeshes_" .. tostring(math.floor(os.clock() * 1000000))
    StagedMeshLibrary.SpeciesMesh.parasaurolophus = {
        folder = "Herbivores (land)",
        name = "ParasaurolophusStoryboardProbe",
    }

    local stagingRoot
    local character
    local ok, err = pcall(function()
        stagingRoot = select(2, makeStagedDinosaur("Herbivores (land)", "ParasaurolophusStoryboardProbe", "storyboard-player-mesh"))

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
            SpeciesId = "parasaurolophus",
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
    StagedMeshLibrary.SpeciesMesh.parasaurolophus = oldParasaurolophusEntry
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
            SpeciesId = "parasaurolophus",
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
    local oldParasaurolophusEntry = StagedMeshLibrary.SpeciesMesh.parasaurolophus
    local oldUtahraptorEntry = StagedMeshLibrary.SpeciesMesh.utahraptor
    NPCService.NPCs = {}
    StagedMeshLibrary.StagingFolderName = "StoryboardBeatValidation_NPCMeshes_" .. tostring(math.floor(os.clock() * 1000000))
    StagedMeshLibrary.SpeciesMesh.parasaurolophus = {
        folder = "Herbivores (land)",
        name = "ParasaurolophusPreyStoryboardProbe",
    }
    StagedMeshLibrary.SpeciesMesh.utahraptor = {
        folder = "Carnivores (land)",
        name = "UtahraptorPredatorStoryboardProbe",
    }

    local stagingRoot
    local preyMarker
    local predatorMarker
    local preyRecord
    local predatorRecord
    local ok, err = pcall(function()
        local _, firstRoot = makeStagedDinosaur("Herbivores (land)", "ParasaurolophusPreyStoryboardProbe", "storyboard-prey-mesh")
        stagingRoot = firstRoot
        makeStagedDinosaur("Carnivores (land)", "UtahraptorPredatorStoryboardProbe", "storyboard-predator-mesh")
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
    StagedMeshLibrary.SpeciesMesh.parasaurolophus = oldParasaurolophusEntry
    StagedMeshLibrary.SpeciesMesh.utahraptor = oldUtahraptorEntry
    StagedMeshLibrary.StagingFolderName = oldStagingFolderName
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "Beat 3 growth advances stage and exposes larger visual scale", run = function()
    local player = MockPlayer.new(93003, "StoryboardBeat3Growth")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true

    local hatchlingScale = CharacterVisualService:GrowthVisualScaleForState(state)
    local ok, grown = SurvivalService:AddGrowth(player, 75)

    Assert.equals(ok, true, "growth can be awarded from survival actions")
    Assert.equals(grown.GrowthStage, "Adult", "growth reaches adult story stage")
    Assert.equals(grown.JustMaturedTo, "Adult", "stage-up event is observable")
    Assert.equals(grown.AlphaEligible, true, "adult growth unlocks alpha eligibility")
    Assert.truthy(CharacterVisualService:GrowthVisualScaleForState(grown) > hatchlingScale, "grown dinosaur has larger visual scale")

    local payload = StatReplicationService:BuildPayload(grown)
    Assert.equals(payload.growthStage, "Adult", "growth stage replicates to UI payload")
    SurvivalService.States[player] = nil
end })

table.insert(suite.tests, { name = "Beat 4 jungle ambush source marks predator and call-capable species", run = function()
    local junglePredator = nil
    for _, spec in ipairs(MapLayoutService.NPCSpawnPlacements) do
        if spec.zone == "JungleBasin" and spec.kind == "Predator" and spec.dangerous == true then
            junglePredator = spec
            break
        end
    end

    Assert.notNil(junglePredator, "JungleBasin has a dangerous predator ambush marker")
    local speciesId = MapLayoutService.NPCKindSpeciesIds[junglePredator.kind]
    local species = SpeciesConfig[speciesId]
    Assert.notNil(species, "jungle predator resolves to a configured species")
    Assert.truthy(type(species.Abilities.CallSet) == "table" and #species.Abilities.CallSet > 0,
        "jungle predator species has call/roar affordances for directional threat feedback")
end })

table.insert(suite.tests, { name = "Beat 5 fish schools stay inside valid swim water habitats", run = function()
    local temp = Instance.new("Folder")
    temp.Name = "StoryboardBeat5WaterProbe"
    temp.Parent = workspace

    local validWater = Instance.new("Part")
    validWater.Name = "StoryboardBeat5SwimWater"
    validWater.Size = Vector3.new(40, 8, 30)
    validWater.Position = Vector3.new(0, 20, 0)
    validWater:SetAttribute("WaterSource", true)
    validWater:SetAttribute("SwimZone", true)
    validWater:SetAttribute("FishSpawnAllowed", true)
    validWater.Parent = temp
    CollectionService:AddTag(validWater, WaterService.WaterTag)

    local shallowWater = Instance.new("Part")
    shallowWater.Name = "StoryboardBeat5ShallowDrinkOnly"
    shallowWater.Size = Vector3.new(40, 3, 30)
    shallowWater.Position = Vector3.new(90, 20, 0)
    shallowWater:SetAttribute("WaterSource", true)
    shallowWater.Parent = temp
    CollectionService:AddTag(shallowWater, WaterService.WaterTag)

    local fish
    local ok, err = pcall(function()
        fish = FishService:CreateFishSource(validWater, "StoryboardBeat5FishSchool", Vector3.new(12, 2, -10))
        Assert.notNil(fish, "fish school is created for valid swim habitat")
        Assert.equals(fish:GetAttribute("FishSchool"), true, "fish source is marked as a school")
        Assert.equals(fish:GetAttribute("WaterSourceName"), validWater.Name, "fish records its water source")
        Assert.equals(WaterService:ContainsPoint(validWater, fish.Position), true, "fish school stays inside water bounds")
        Assert.truthy(FishService:ApplyBeat5ImportedRandomWalk(fish, validWater, { stepStuds = 80 }),
            "Beat 5 adapted vendor random-walk layer moves fish safely")
        Assert.equals(WaterService:ContainsPoint(validWater, fish.Position), true,
            "Beat 5 adapted random-walk output remains clamped to water bounds")
        Assert.equals(fish:GetAttribute("ImportedScriptAdapted"), true,
            "Beat 5 fish movement carries reviewed adapted-script ownership")
        Assert.equals(fish:GetAttribute("ScriptAdaptedTo"), "FishService.ApplyBeat5ImportedRandomWalk",
            "Beat 5 fish movement records source-side adaptation target")
        Assert.truthy(CollectionService:HasTag(fish, FishService.ImportedScriptAdaptedTag),
            "Beat 5 fish movement carries adapted ownership tag")

        local invalidFish, reason = FishService:CreateFishSource(shallowWater, "StoryboardBeat5InvalidFishSchool")
        Assert.equals(invalidFish, nil, "fish school is rejected for drink-only shallow water")
        Assert.equals(reason, "fish_not_allowed", "invalid shallow water explains why fish cannot spawn")
    end)

    if fish then fish:Destroy() end
    CollectionService:RemoveTag(validWater, WaterService.WaterTag)
    CollectionService:RemoveTag(shallowWater, WaterService.WaterTag)
    temp:Destroy()
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "Beat 6 apex event warns nearby non-apex creatures", run = function()
    local oldRecords = NPCService.NPCs
    NPCService.NPCs = {}

    local apexModel
    local preyModel
    local ok, err = pcall(function()
        apexModel = makeNPCModel("StoryboardBeat6Apex", Vector3.new(0, 20, 0))
        preyModel = makeNPCModel("StoryboardBeat6Prey", Vector3.new(25, 20, 0))

        local apexOk, apexRecord = NPCService:Register(apexModel, "Apex")
        local preyOk, preyRecord = NPCService:Register(preyModel, "Prey")
        Assert.equals(apexOk, true, "apex NPC registers")
        Assert.equals(preyOk, true, "prey NPC registers")
        Assert.equals(apexRecord.Apex, true, "apex record carries apex flag")

        local eventOk = NPCService:StampApexEvent(apexRecord, 100)
        Assert.equals(eventOk, true, "apex event can broadcast")
        Assert.equals(apexModel:GetAttribute("ApexEventActive"), true, "apex source exposes active warning")
        Assert.equals(apexModel:GetAttribute("ApexEventAffected"), 1, "apex warning affects nearby prey")
        Assert.equals(preyModel:GetAttribute("ApexThreatState"), "Warned", "nearby prey receives readable threat state")
        Assert.equals(preyRecord.LastApexThreat, apexModel, "prey records apex threat source")
    end)

    if apexModel then apexModel:Destroy() end
    if preyModel then preyModel:Destroy() end
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "Beat 7 city discovery triggers are invisible Old Eden story volumes", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    local triggerFolder = MapLayoutService:EnsureCityDiscoveryTriggers(folders)
    local triggers = 0

    for _, trigger in ipairs(triggerFolder:GetChildren()) do
        if trigger:GetAttribute("CityDiscoveryTrigger") == true then
            triggers = triggers + 1
            Assert.equals(trigger.Transparency, 1, trigger.Name .. " is invisible gameplay volume")
            Assert.equals(trigger.CanCollide, false, trigger.Name .. " does not block traversal")
            Assert.equals(trigger:GetAttribute("ZoneId"), "ApocalypticCity", trigger.Name .. " points to Old Eden city")
        end
    end

    Assert.truthy(triggers >= 3, "city approach/core discovery volumes exist")
end })

table.insert(suite.tests, { name = "Beat 8 nesting herd markers resolve to herd-capable prey spawns", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureNPCSpawnMarkers(folders)
    local herdMarkersByZone = {}
    local herdMarkerCount = 0

    for _, spec in ipairs(MapLayoutService.NPCSpawnPlacements) do
        if spec.nestingHerd == true then
            herdMarkerCount = herdMarkerCount + 1
            Assert.equals(spec.kind, "Prey", spec.name .. " nesting herd marker is prey")
            local speciesId = MapLayoutService.NPCKindSpeciesIds[spec.kind]
            local species = SpeciesConfig[speciesId]
            Assert.notNil(species, spec.name .. " resolves to a configured species")
            Assert.equals(species.EcosystemProfile.Herding, true, spec.name .. " resolves to a herd-capable species")
            local marker = folders.NPCSpawns:FindFirstChild(spec.name)
            Assert.notNil(marker, spec.name .. " nesting herd marker is authored")
            Assert.equals(marker:GetAttribute("NestingHerd"), true, spec.name .. " is stamped as a nesting herd marker")
            Assert.equals(marker:GetAttribute("SpeciesRelevantSpawn"), true, spec.name .. " remains relevant even outside preferred biome")
            Assert.equals(marker:GetAttribute("SpeciesId"), speciesId, spec.name .. " spawn marker records herd-capable species")

            local zoneMarkers = herdMarkersByZone[spec.zone]
            if not zoneMarkers then
                zoneMarkers = {}
                herdMarkersByZone[spec.zone] = zoneMarkers
            end
            table.insert(zoneMarkers, spec)
        end
    end

    local groupedZones = 0
    for zoneName, zoneMarkers in pairs(herdMarkersByZone) do
        if #zoneMarkers >= 2 then
            groupedZones = groupedZones + 1
            for i = 1, #zoneMarkers do
                for j = i + 1, #zoneMarkers do
                    Assert.truthy((zoneMarkers[i].position - zoneMarkers[j].position).Magnitude <= NPCService.HerdRadius * 2,
                        zoneName .. " nesting herd markers stay near enough to read as one authored group")
                end
            end
        end
    end

    Assert.truthy(herdMarkerCount >= 4, "Beat 8 has authored nesting herd prey markers")
    Assert.truthy(groupedZones >= 1, "Beat 8 has at least one multi-marker nesting herd group")
end })

table.insert(suite.tests, { name = "Beat 8 adult nest action lays egg and records home state", run = function()
    local player = MockPlayer.new(93008, "StoryboardBeat8Adult")
    RateLimitService:ClearPlayer(player)
    NestService.Nests[player] = nil

    local character = Instance.new("Model")
    character.Name = "StoryboardBeat8Character"
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(0, 10, 0)
    root.Parent = character
    character.PrimaryPart = root
    character.Parent = workspace
    player.Character = character

    local nest = Instance.new("Part")
    nest.Name = "StoryboardBeat8NestZone"
    nest.Position = Vector3.new(4, 10, 0)
    nest.Parent = workspace
    CollectionService:AddTag(nest, "NestZone")

    local ok, err = pcall(function()
        local state = SurvivalService:CreateState(player, "parasaurolophus")
        state.Hatched = true
        state.GrowthStage = "Adult"

        local nestOk, record = NestService:RequestNestAction(player, "LayEgg", nest)
        Assert.equals(nestOk, true, "adult can lay an egg at a nest")
        Assert.equals(record.Eggs, 1, "nest records laid egg")
        Assert.equals(state.NestRespawn, nest, "nest becomes home/respawn state")
        Assert.equals(state.NestEggCount, 1, "state exposes egg count for UI")
        Assert.equals(state.HatchlingBuff, "NestRested", "nest records hatchling payoff")
    end)

    CollectionService:RemoveTag(nest, "NestZone")
    nest:Destroy()
    character:Destroy()
    NestService.Nests[player] = nil
    SurvivalService.States[player] = nil
    RateLimitService:ClearPlayer(player)
    if not ok then error(err) end
end })

TestRunner.registerSuite(suite)
return suite
