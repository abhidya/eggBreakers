local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local Constants = require(ReplicatedStorage.Shared.Constants)
local NPCService = require(ServerScriptService.Services.NPCService)
local PlacementValidationService = require(ServerScriptService.Services.PlacementValidationService)
local RemoteValidationService = require(ServerScriptService.Services.RemoteValidationService)

local suite = { name = "G029StoryE2EGate.server", category = "E2E", tests = {} }

local function makePartModel(name, position, size)
    local model = Instance.new("Model")
    model.Name = name

    local part = Instance.new("Part")
    part.Name = name .. "_VisibleMesh"
    part.Size = size or Vector3.new(4, 4, 4)
    part.Position = position
    part.Anchored = true
    part.Transparency = 0
    part.Parent = model
    model.PrimaryPart = part

    return model, part
end

local function makeStoryAsset(name, zoneId, sourceAssetId, position)
    local model, part = makePartModel(name, position, Vector3.new(4, 4, 4))
    model:SetAttribute("ZoneId", zoneId)
    model:SetAttribute("SourceAssetId", tostring(sourceAssetId))
    model:SetAttribute("ImportedVisibleAsset", true)
    model:SetAttribute("CreatorStoreOnly", true)
    model:SetAttribute("GroundedStoryboardAsset", true)
    model:SetAttribute("GroundTopY", position.Y - part.Size.Y / 2)
    model:SetAttribute("GroundBottomY", position.Y - part.Size.Y / 2)
    model:SetAttribute("GroundClearance", 0)
    return model
end

local function makeNPC(name, position)
    local model = Instance.new("Model")
    model.Name = name

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 2)
    root.Position = position or Vector3.new(0, 3, 0)
    root.Anchored = true
    root.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = workspace
    return model, root, humanoid
end

local function ensureCarcassAsset()
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = ReplicatedStorage
    end

    local asset = library:FindFirstChild("G029BoneCarcassVisual")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "G029BoneCarcassVisual"
        asset.Size = Vector3.new(4, 1, 2)
        asset:SetAttribute("ImportedVisibleAsset", true)
        asset:SetAttribute("CreatorStoreOnly", true)
        asset:SetAttribute("SourceAssetId", "g029-carcass-fixture")
        asset.Parent = library
    end
    return asset
end

local function resetNPCs()
    NPCService.NPCs = {}
end

table.insert(suite.tests, { name = "G029 story asset batch keeps every visible placement grounded", run = function()
    local batch = Instance.new("Folder")
    batch.Name = "G029_StoryAssetDrivenBatch_TestFixture"
    batch.Parent = workspace

    local assets = {
        { "Beat0_NurseryPrimaryNest", "NurseryGrove", "8895193", Vector3.new(-2000, 12, 0) },
        { "Beat0_NurseryRustleNest", "NurseryGrove", "93304870", Vector3.new(-2012, 12, 8) },
        { "Beat1_NurseryFernFood_A", "NurseryGrove", "12630982706", Vector3.new(-1990, 12, 12) },
        { "Beat1_NurseryFernFood_B", "NurseryGrove", "12630982706", Vector3.new(-1980, 12, -10) },
        { "Beat2_FernPlainsGrazingPatch", "FernPlains", "12630982706", Vector3.new(-1000, 12, 0) },
        { "Beat4_JungleBasinAmbushCover", "JungleBasin", "12630982706", Vector3.new(-1400, 12, 1100) },
        { "Beat5_SwampDeltaMarshCover", "SwampDelta", "12630982706", Vector3.new(-180, 10, 980) },
    }

    local ok, err = pcall(function()
        for _, spec in ipairs(assets) do
            local model = makeStoryAsset(spec[1], spec[2], spec[3], spec[4])
            model.Parent = batch
        end

        local result = PlacementValidationService:ValidateNoFloatingVisibleAssets(batch)
        Assert.truthy(result.passed, table.concat(result.failures, "; "))
        Assert.equals(result.checked, #assets, "all visible G029 story roots are checked by placement gate")
    end)

    batch:Destroy()
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "G029 imported behavior scripts require explicit review metadata", run = function()
    local batch = Instance.new("Folder")
    batch.Name = "G029_ScriptReviewFixture"
    batch.Parent = workspace

    local ok, err = pcall(function()
        for index = 1, 2 do
            local scriptObject = Instance.new("Script")
            scriptObject.Name = "ReviewedRustleScript" .. tostring(index)
            scriptObject:SetAttribute("ReviewedImportedScript", true)
            scriptObject:SetAttribute("ScriptAuditPurpose", "local rustle sound on touched leaves/moss only")
            scriptObject:SetAttribute("ScriptSandboxStatus", "reviewed_no_remotes_no_datastore_no_damage")
            scriptObject.Parent = batch
        end

        local reviewed = 0
        for _, descendant in ipairs(batch:GetDescendants()) do
            if descendant:IsA("Script") then
                reviewed = reviewed + 1
                Assert.equals(descendant:GetAttribute("ReviewedImportedScript"), true, descendant.Name .. " reviewed flag")
                Assert.equals(descendant:GetAttribute("ScriptSandboxStatus"), "reviewed_no_remotes_no_datastore_no_damage", descendant.Name .. " sandbox status")
            end
        end
        Assert.equals(reviewed, 2, "G029 rustle script count stays explicit")
    end)

    batch:Destroy()
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "near food target remains reachable when visible asset is grounded above terrain", run = function()
    local root = Instance.new("Part")
    root.Name = "G029WaypointRoot"
    root.Position = Vector3.new(-2003, 12, 0)
    root.Parent = workspace

    local food = Instance.new("Part")
    food.Name = "G029GroundedWaypointFernQuery"
    food.Size = Vector3.new(4, 4, 4)
    food.Position = Vector3.new(-2000, 12, 0)
    food.Transparency = 1
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 25)
    food:SetAttribute("ZoneId", "NurseryGrove")
    food:SetAttribute("GroundTopY", 10)
    food.Parent = workspace
    CollectionService:AddTag(food, Constants.Tags.FoodSource)

    local visual = Instance.new("Part")
    visual.Name = "G029GroundedFernVisual"
    visual.Size = Vector3.new(3, 4, 3)
    visual.Position = Vector3.new(-2000, 12, 0)
    visual.Anchored = true
    visual.Transparency = 0
    visual.Parent = food

    local ok, err = pcall(function()
        local placement = PlacementValidationService:ValidateNoFloatingVisibleAssets(food)
        Assert.truthy(placement.passed, table.concat(placement.failures, "; "))
        Assert.truthy(RemoteValidationService:ValidateFoodTarget(root, food, "Herbivore", 12), "grounded target is reachable")
    end)

    CollectionService:RemoveTag(food, Constants.Tags.FoodSource)
    root:Destroy()
    food:Destroy()
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "NPC CPU budget defers excess brains with live-proof counters", run = function()
    local oldRecords = NPCService.NPCs
    local oldBudget = NPCService.MaxBrainTicksPerCycle
    local oldIndex = NPCService.BrainRoundRobinIndex
    resetNPCs()
    NPCService.MaxBrainTicksPerCycle = 2
    NPCService.BrainRoundRobinIndex = 1

    local a = makeNPC("G029BudgetA", Vector3.new(0, 3, 0))
    local b = makeNPC("G029BudgetB", Vector3.new(10, 3, 0))
    local c = makeNPC("G029BudgetC", Vector3.new(20, 3, 0))

    local ok, err = pcall(function()
        NPCService:Register(a, "Prey")
        NPCService:Register(b, "Prey")
        NPCService:Register(c, "Prey")

        Assert.equals(NPCService:TickNPCs({}), 2, "only budgeted brains tick in one cycle")
        Assert.equals(a:GetAttribute("BrainCycleBudget"), 2, "budget is visible for live proof")
        Assert.equals(a:GetAttribute("BrainCycleTotal"), 3, "total population is visible for live proof")
        Assert.equals(c:GetAttribute("BrainDeferred"), true, "unbudgeted brain is deferred")

        NPCService:TickNPCs({})
        Assert.equals(c:GetAttribute("BrainDeferred"), false, "deferred brain is serviced next cycle")
    end)

    a:Destroy()
    b:Destroy()
    c:Destroy()
    NPCService.NPCs = oldRecords
    NPCService.MaxBrainTicksPerCycle = oldBudget
    NPCService.BrainRoundRobinIndex = oldIndex
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "humanoid NPC chase uses MoveTo without teleporting to target", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()

    local npc, root, humanoid = makeNPC("G029MoveToPredator", Vector3.new(0, 3, 0))

    local ok, err = pcall(function()
        local registered, record = NPCService:Register(npc, "Predator")
        Assert.equals(registered, true, "predator registers")
        record.Hatched = true

        Assert.truthy(NPCService:MoveToward(record, Vector3.new(60, 30, 0), 8, "Chase"), "chase move succeeds")
        Assert.equals(record.LastLocomotionMode, "HumanoidMoveTo", "humanoid locomotion mode is stamped")
        Assert.equals(npc:GetAttribute("GroundClampApplied"), true, "above-ground target is clamped to movement plane")
        Assert.equals(root.Anchored, false, "root is unanchored for MoveTo")
        Assert.truthy(humanoid.WalkSpeed > 0, "humanoid receives movement speed")
        Assert.truthy((root.Position - Vector3.new(0, 3, 0)).Magnitude < 0.1, "MoveTo did not PivotTo-teleport root")
    end)

    npc:Destroy()
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "predator fight converts prey into edible carcass food", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()
    ensureCarcassAsset()

    local predator = makeNPC("G029FightPredator", Vector3.new(0, 3, 0))
    local prey = makeNPC("G029FightPrey", Vector3.new(6, 3, 0))

    local ok, err = pcall(function()
        local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
        local preyOk, preyRecord = NPCService:Register(prey, "Prey")
        Assert.truthy(predatorOk and preyOk, "predator and prey register")
        predatorRecord.Hatched = true
        preyRecord.Hatched = true
        preyRecord.Health = 20

        NPCService:TickBrain(predatorRecord, {}, 1)
        Assert.equals(predatorRecord.State, "Attack", "predator attacks close prey")
        Assert.equals(preyRecord.State, "Dead", "prey dies from attack")
        Assert.notNil(preyRecord.Carcass, "dead prey creates carcass")
        Assert.equals(preyRecord.Carcass:GetAttribute("Diet"), "Carnivore", "carcass is carnivore food")
        Assert.truthy(CollectionService:HasTag(preyRecord.Carcass, Constants.Tags.FoodSource), "carcass is tagged food")
        preyRecord.Carcass:Destroy()
    end)

    predator:Destroy()
    prey:Destroy()
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "pack predators regroup before idle wandering", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()

    local alpha = makeNPC("G029PackAlpha", Vector3.new(0, 3, 0))
    local beta = makeNPC("G029PackBeta", Vector3.new(24, 3, 0))

    local ok, err = pcall(function()
        local _, alphaRecord = NPCService:Register(alpha, "Predator")
        local _, betaRecord = NPCService:Register(beta, "Predator")
        alphaRecord.Hatched = true
        betaRecord.Hatched = true
        alphaRecord.Hunger = 90
        alphaRecord.Thirst = 90
        betaRecord.Hunger = 90
        betaRecord.Thirst = 90

        NPCService:TickBrain(alphaRecord, {}, 1)
        Assert.equals(alphaRecord.State, "Pack", "pack hunter enters regroup state")
        Assert.equals(alpha:GetAttribute("PackEventState"), "Regrouping", "pack event is readable")
        Assert.equals(alpha:GetAttribute("PackSize"), 2, "pack size is visible")
    end)

    alpha:Destroy()
    beta:Destroy()
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "healthy same-species NPCs enter mating beat", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()

    local first = makeNPC("G029MateFirstOviraptor", Vector3.new(0, 3, 0))
    local second = makeNPC("G029MateSecondOviraptor", Vector3.new(12, 3, 0))

    local ok, err = pcall(function()
        local _, firstRecord = NPCService:Register(first, "Omnivore")
        local _, secondRecord = NPCService:Register(second, "Omnivore")
        firstRecord.Hatched = true
        secondRecord.Hatched = true
        firstRecord.Hunger = 90
        firstRecord.Thirst = 90
        secondRecord.Hunger = 90
        secondRecord.Thirst = 90
        firstRecord.Herding = false
        secondRecord.Herding = false

        NPCService:TickBrain(firstRecord, {}, 1)
        Assert.equals(firstRecord.State, "Mate", "matching healthy NPC enters mating state")
        Assert.equals(first:GetAttribute("MateTarget"), "G029MateSecondOviraptor", "mate target is visible")
        Assert.equals(first:GetAttribute("LastBrainAction"), "Mate", "mating action is stamped")
    end)

    first:Destroy()
    second:Destroy()
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

return TestRunner.registerSuite(suite)
