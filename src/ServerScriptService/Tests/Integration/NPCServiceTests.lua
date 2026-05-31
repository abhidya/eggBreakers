local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local NPCSpawnService = require(game:GetService("ServerScriptService").Services.NPCSpawnService)

local suite = { name = "NPCServiceTests.server", category = "Integration", tests = {} }

local function makeNPC(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(2, 2, 2)
    root.Position = position or Vector3.new(0, 3, 0)
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model
end

local function makeStagedRootRig(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(10, 10, 10)
    root.Transparency = 1
    root.Position = position or Vector3.new(0, 3, 0)
    root.Parent = model
    local body = Instance.new("MeshPart")
    body.Name = "BodyMesh"
    body.Size = Vector3.new(4, 2, 8)
    body.Position = root.Position
    body.Parent = model
    local animationController = Instance.new("AnimationController")
    animationController.Name = "AnimationController"
    animationController.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model, root, body
end

local function makeHumanoidNPC(name, position)
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

local function makeTaggedPart(name, tagName, position)
    local part = Instance.new("Part")
    part.Name = name
    part.Position = position or Vector3.new(4, 3, 0)
    part.Parent = workspace
    CollectionService:AddTag(part, tagName)
    return part
end

local function ensureCarcassAsset()
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = ReplicatedStorage
    end
    local asset = library:FindFirstChild("NPCServiceTestBoneCarcass")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "NPCServiceTestBoneCarcass"
        asset.Size = Vector3.new(4, 1, 2)
        asset.Parent = library
    end
    return asset
end

local function resetNPCs()
    NPCService.NPCs = {}
end

table.insert(suite.tests, { name = "parentless NPC records are pruned from active registry", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()

    local live = makeNPC("LivePruneProbeNPC", Vector3.new(0, 3, 0))
    local stale = makeNPC("StalePruneProbeNPC", Vector3.new(8, 3, 0))
    local _, liveRecord = NPCService:Register(live, "Prey")
    NPCService:Register(stale, "Prey")
    stale:Destroy()

    local pruned = NPCSpawnService:PruneStaleNPCRecords()
    Assert.equals(pruned, 1, "one parentless NPC record pruned")
    Assert.equals(#NPCService.NPCs, 1, "only live NPC record remains")
    Assert.equals(NPCService.NPCs[1], liveRecord, "live record is preserved")

    live:Destroy()
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "TickNPCs prunes stale records before brain tick", run = function()
    local oldRecords = NPCService.NPCs
    resetNPCs()

    local live = makeNPC("LiveTickPruneNPC", Vector3.new(0, 3, 0))
    local stale = makeNPC("StaleTickPruneNPC", Vector3.new(8, 3, 0))
    local _, liveRecord = NPCService:Register(live, "Prey")
    NPCService:Register(stale, "Prey")
    liveRecord.Hatched = true
    stale:Destroy()

    local active = NPCService:TickNPCs({})
    Assert.equals(#NPCService.NPCs, 1, "stale destroyed NPC is removed during TickNPCs")
    Assert.equals(NPCService.NPCs[1], liveRecord, "live record remains after TickNPCs prune")
    Assert.truthy(active >= 0, "tick returns active count after pruning")

    live:Destroy()
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "NPC hatches at nest then seeks needs and eats/drinks", run = function()
    resetNPCs()
    local npc = makeNPC("NeedsPreyNPC", Vector3.new(0, 3, 0))
    local food = makeTaggedPart("NeedsFern", "FoodSource", Vector3.new(4, 3, 0))
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 30)
    local water = makeTaggedPart("NeedsWater", "WaterSource", Vector3.new(5, 3, 0))
    local ok, record = NPCService:Register(npc, "Prey")

    Assert.truthy(ok, "prey registers")
    Assert.equals(record.State, "HatchAtNest", "starts as nest egg/hatch state")
    Assert.truthy(NPCService:TickBrain(record, {}, 1), "first tick hatches")
    Assert.equals(record.Hatched, true, "record hatched")
    Assert.equals(npc:GetAttribute("Hatched"), true, "instance hatched attribute")

    record.Thirst = 20
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Drink", "thirsty NPC drinks nearby water")
    Assert.truthy(record.Thirst > 20, "drink restores thirst")

    record.Hunger = 20
    record.Thirst = 90
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "hungry NPC eats nearby matching food")
    Assert.equals(food:GetAttribute("Depleted"), true, "NPC depletes food source")

    npc:Destroy(); food:Destroy(); water:Destroy()
end })


table.insert(suite.tests, { name = "hungry herbivore seeks food with target and facing orientation", run = function()
    resetNPCs()
    local npc = makeNPC("GrazingPreyNPC", Vector3.new(0, 3, 0))
    local food = makeTaggedPart("DistantGrazingFern", "FoodSource", Vector3.new(30, 3, 0))
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 30)
    local ok, record = NPCService:Register(npc, "Prey")
    record.Hatched = true
    record.Hunger = 20
    record.Thirst = 90

    Assert.truthy(ok, "prey registers")
    NPCService:TickBrain(record, {}, 1)

    Assert.equals(record.State, "SeekFood", "hungry herbivore seeks matching plant food")
    Assert.equals(record.FoodTarget, food, "record tracks concrete food target")
    Assert.equals(npc:GetAttribute("FoodTarget"), "DistantGrazingFern", "food target name is visible on NPC")
    Assert.equals(npc:GetAttribute("FoodTargetDiet"), "Herbivore", "food target diet is visible on NPC")
    Assert.equals(npc:GetAttribute("LastBrainAction"), "SeekFood", "seek-food action is visible on NPC")
    Assert.equals(npc:GetAttribute("BrainTargetName"), "DistantGrazingFern", "brain target names the food source")
    Assert.equals(npc:GetAttribute("BrainActionTarget"), "30.0,3.0,0.0", "brain target position recorded")
    local directionToFood = (food.Position - NPCService:GetRecordPosition(record)).Unit
    Assert.truthy(npc:GetPivot().LookVector:Dot(directionToFood) > 0.95, "NPC faces the food target while grazing")

    npc:Destroy(); food:Destroy()
end })


table.insert(suite.tests, { name = "movement step is bounded and stamped", run = function()
    resetNPCs()
    local npc = makeNPC("BoundedStepNPC", Vector3.new(0, 3, 0))
    local _, record = NPCService:Register(npc, "Prey")
    record.Hatched = true

    local target = Vector3.new(50, 3, 0)
    Assert.truthy(NPCService:MoveToward(record, target, NPCService.MoveStep, "SeekFood"), "move toward succeeds")
    local moved = NPCService:GetRecordPosition(record)
    Assert.truthy(math.abs(moved.X - NPCService.MoveStep) < 0.01, "move step is capped to configured step")
    Assert.equals(npc:GetAttribute("BrainMoveCount"), 1, "move count stamped")
    Assert.equals(npc:GetAttribute("LastBrainAction"), "SeekFood", "last brain action stamped")
    Assert.equals(npc:GetAttribute("BrainActionTarget"), "50.0,3.0,0.0", "target position stamped")
    Assert.equals(npc:GetAttribute("LastMoveTarget"), "50.0,3.0,0.0", "last move target stamped")

    npc:Destroy()
end })

table.insert(suite.tests, { name = "ground movement clamps bad vertical target and exposes surface", run = function()
    resetNPCs()
    local npc = makeNPC("GroundClampNPC", Vector3.new(0, 3, 0))
    local _, record = NPCService:Register(npc, "Prey")
    record.Hatched = true

    local target = Vector3.new(50, 80, 0)
    Assert.truthy(NPCService:MoveToward(record, target, NPCService.MoveStep, "Wander"), "ground move succeeds")
    local moved = NPCService:GetRecordPosition(record)
    Assert.truthy(math.abs(moved.Y - 3) < 0.01, "ground NPC stays on its movement plane")
    Assert.equals(record.MovementSurface, "Ground", "record exposes ground movement surface")
    Assert.equals(npc:GetAttribute("MovementSurface"), "Ground", "instance exposes ground movement surface")
    Assert.equals(npc:GetAttribute("GroundClampApplied"), true, "vertical target clamp is visible")
    Assert.equals(npc:GetAttribute("ResolvedMoveTarget"), "50.0,3.0,0.0", "resolved target is readable")

    npc:Destroy()
end })

table.insert(suite.tests, { name = "humanoid chase uses MoveTo setup without teleporting", run = function()
    resetNPCs()
    local npc, root, humanoid = makeHumanoidNPC("HumanoidChaseNPC", Vector3.new(0, 3, 0))
    local _, record = NPCService:Register(npc, "Predator")
    record.Hatched = true

    Assert.truthy(NPCService:MoveToward(record, Vector3.new(60, 18, 0), 8, "Chase"), "humanoid move succeeds")
    Assert.equals(record.LastLocomotionMode, "HumanoidMoveTo", "record stamps humanoid locomotion")
    Assert.equals(npc:GetAttribute("LocomotionMode"), "HumanoidMoveTo", "instance stamps humanoid locomotion")
    Assert.equals(npc:GetAttribute("MovementSurface"), "Ground", "ground humanoid movement surface")
    Assert.equals(npc:GetAttribute("GroundClampApplied"), true, "humanoid target y was ground-clamped")
    Assert.truthy(root.Anchored == false, "humanoid root is unanchored for physics movement")
    Assert.truthy(humanoid.WalkSpeed >= 20, "chase uses sprint-speed intent")
    Assert.truthy((root.Position - Vector3.new(0, 3, 0)).Magnitude < 0.1, "MoveTo path does not PivotTo-teleport humanoid root")

    npc:Destroy()
end })

table.insert(suite.tests, { name = "stuck movement recovers with lateral nudge and readable state", run = function()
    resetNPCs()
    local npc = makeNPC("StuckRecoveryNPC", Vector3.new(0, 3, 0))
    local _, record = NPCService:Register(npc, "Prey")
    record.Hatched = true
    record.LastMovementPosition = NPCService:GetRecordPosition(record)
    record.StuckTicks = NPCService.StuckRecoveryTicks - 1

    Assert.truthy(NPCService:MoveToward(record, Vector3.new(60, 3, 0), 8, "Wander"), "recovery move succeeds")
    Assert.equals(record.MovementState, "Recovering:Wander", "record exposes recovery state")
    Assert.equals(npc:GetAttribute("MovementState"), "Recovering:Wander", "instance exposes recovery state")
    Assert.equals(npc:GetAttribute("StuckRecoveryActive"), true, "active recovery flag visible")
    Assert.equals(npc:GetAttribute("MovementRecoveryCount"), 1, "recovery count visible")
    Assert.equals(npc:GetAttribute("StuckRecoveryTarget"), "60.0,3.0,6.0", "lateral recovery target stamped")

    npc:Destroy()
end })

table.insert(suite.tests, { name = "staged RootPart rig movement is bounded and mode-stamped", run = function()
    resetNPCs()
    local npc, root, body = makeStagedRootRig("StagedRootStepNPC", Vector3.new(0, 3, 0))
    local _, record = NPCService:Register(npc, "Predator")
    record.Hatched = true

    local target = Vector3.new(50, 3, 0)
    Assert.truthy(NPCService:MoveToward(record, target, 8, "Chase"), "staged rig move succeeds")
    local moved = NPCService:GetRecordPosition(record)
    Assert.truthy(math.abs(moved.X - 8) < 0.01, "staged root rig moves only one bounded step")
    Assert.truthy((moved - target).Magnitude > 30, "staged root rig is not teleported to full target")
    Assert.equals(record.LastLocomotionMode, "KinematicRootStep", "record stamps staged root locomotion mode")
    Assert.equals(npc:GetAttribute("LocomotionMode"), "KinematicRootStep", "instance stamps staged root locomotion mode")
    Assert.equals(root.Transparency, 1, "helper root remains invisible")
    Assert.truthy(body.Transparency < 1, "visible mesh body remains renderable")

    npc:Destroy()
end })


table.insert(suite.tests, { name = "brain movement constants keep predator runner bounded", run = function()
    resetNPCs()
    local predator = makeNPC("BrainStepPredatorNPC", Vector3.new(0, 3, 0))
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(40, 3, 0)
    local character = Instance.new("Model")
    root.Parent = character
    local _, record = NPCService:Register(predator, "Predator")
    record.Hatched = true

    Assert.truthy((NPCService.BrainStepStuds or 0) > 0, "brain step constant is configured")
    Assert.truthy((NPCService.AttackDistance or 0) > 0, "attack distance constant is configured")
    Assert.truthy(NPCService:RunPredatorBrain(record, { { Character = character } }), "predator brain runs without nil step")
    Assert.equals(record.State, "Chase", "distant target triggers chase")
    Assert.truthy((NPCService:GetRecordPosition(record) - Vector3.new(0, 3, 0)).Magnitude <= NPCService.BrainStepStuds + 0.01, "predator brain movement bounded by BrainStepStuds")
    Assert.equals(predator:GetAttribute("LastBrainAction"), "Chase", "predator brain chase stamped")
    Assert.equals(predator:GetAttribute("LastMoveTarget"), "40.0,3.0,0.0", "predator brain target stamped")

    predator:Destroy(); character:Destroy()
end })

table.insert(suite.tests, { name = "predator chases attacks and prey death leaves carcass", run = function()
    resetNPCs()
    ensureCarcassAsset()
    local predator = makeNPC("BrainPredatorNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("BrainPreyNPC", Vector3.new(6, 3, 0))
    local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    predatorRecord.Hatched = true
    preyRecord.Hatched = true
    preyRecord.Health = 20

    Assert.truthy(predatorOk and preyOk, "predator and prey register")
    NPCService:TickBrain(predatorRecord, {}, 1)
    Assert.equals(predatorRecord.State, "Attack", "predator attacks close prey")
    Assert.equals(preyRecord.State, "Dead", "prey dies from attack")
    Assert.notNil(preyRecord.Carcass, "dead prey leaves carcass")
    Assert.truthy(CollectionService:HasTag(preyRecord.Carcass, "FoodSource"), "carcass is food source")
    Assert.truthy(CollectionService:HasTag(preyRecord.Carcass, "CarnivoreFoodCandidate"), "carcass is a carnivore food candidate")
    Assert.equals(preyRecord.Carcass:GetAttribute("PotentialCarnivoreFood"), true, "carcass potential carnivore food")

    predator:Destroy(); prey:Destroy(); preyRecord.Carcass:Destroy()
end })


table.insert(suite.tests, { name = "predator chase attack creates edible carcass loop", run = function()
    resetNPCs()
    ensureCarcassAsset()
    local predator = makeNPC("LoopPredatorNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("LoopPreyNPC", Vector3.new(30, 3, 0))
    local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    predatorRecord.Hatched = true
    preyRecord.Hatched = true
    predatorRecord.Hunger = 90
    preyRecord.Health = 20

    Assert.truthy(predatorOk and preyOk, "predator and prey register")
    NPCService:TickBrain(predatorRecord, {}, 1)
    Assert.equals(predatorRecord.State, "Chase", "predator chases distant prey")
    Assert.equals(predator:GetAttribute("LastBrainAction"), "Chase", "chase action stamped")
    Assert.equals(predator:GetAttribute("BrainTargetName"), "LoopPreyNPC", "chase target names prey")
    Assert.truthy((NPCService:GetRecordPosition(predatorRecord) - Vector3.new(0, 3, 0)).Magnitude <= NPCService.MoveStep + 0.01, "chase movement is bounded")

    prey:PivotTo(CFrame.new(NPCService:GetRecordPosition(predatorRecord) + Vector3.new(5, 0, 0)))
    NPCService:TickBrain(predatorRecord, {}, 1)
    Assert.equals(predatorRecord.State, "Attack", "predator attacks close dinosaur prey")
    Assert.equals(preyRecord.State, "Dead", "prey dies from predator attack")
    Assert.notNil(preyRecord.Carcass, "dead prey creates carcass food")
    Assert.equals(preyRecord.Carcass:GetAttribute("Diet"), "Carnivore", "carcass is carnivore food")
    Assert.equals(preyRecord.Carcass:GetAttribute("PotentialCarnivoreFood"), true, "NPC carcass remains potential carnivore food")
    Assert.truthy(CollectionService:HasTag(preyRecord.Carcass, "CarnivoreFoodCandidate"), "NPC carcass tagged as carnivore candidate")

    predatorRecord.Hunger = 20
    NPCService:TickBrain(predatorRecord, {}, 1)
    Assert.equals(predatorRecord.State, "Eat", "predator eats created carcass")
    Assert.equals(preyRecord.Carcass:GetAttribute("Depleted"), true, "created carcass depleted by predator")
    Assert.truthy(predatorRecord.Hunger > 20, "carcass restores predator hunger")

    predator:Destroy(); prey:Destroy(); preyRecord.Carcass:Destroy()
end })


table.insert(suite.tests, { name = "living prey are potential carnivore food candidates until dead", run = function()
    resetNPCs()
    ensureCarcassAsset()
    local prey = makeNPC("CandidatePreyNPC", Vector3.new(0, 3, 0))
    local predator = makeNPC("CandidatePredatorNPC", Vector3.new(20, 3, 0))
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    local predatorOk = NPCService:Register(predator, "Predator")

    Assert.truthy(preyOk and predatorOk, "prey and predator register")
    Assert.equals(prey:GetAttribute("PotentialCarnivoreFood"), true, "living prey advertises carnivore food potential")
    Assert.equals(prey:GetAttribute("CarnivoreFoodCandidate"), true, "living prey candidate attribute set")
    Assert.truthy(CollectionService:HasTag(prey, "CarnivoreFoodCandidate"), "living prey candidate tag set")
    Assert.falsy(predator:GetAttribute("PotentialCarnivoreFood"), "predator is not prey food")

    NPCService:MarkPreyDead(preyRecord)
    Assert.equals(prey:GetAttribute("CarnivoreFoodCandidate"), false, "dead prey instance no longer advertises living target")
    Assert.falsy(CollectionService:HasTag(prey, "CarnivoreFoodCandidate"), "dead prey instance candidate tag removed")
    Assert.notNil(preyRecord.Carcass, "dead prey creates separate carcass food")
    Assert.equals(preyRecord.Carcass:GetAttribute("PotentialCarnivoreFood"), true, "carcass advertises carnivore food potential")

    prey:Destroy(); predator:Destroy(); preyRecord.Carcass:Destroy()
end })


table.insert(suite.tests, { name = "hungry herbivore eats tree browse food source", run = function()
    resetNPCs()
    local npc = makeNPC("TreeBrowsingPreyNPC", Vector3.new(0, 3, 0))
    local browse = makeTaggedPart("EdibleCanopyBrowse", "FoodSource", Vector3.new(5, 3, 0))
    CollectionService:AddTag(browse, "TreeProp")
    browse:SetAttribute("Diet", "Herbivore")
    browse:SetAttribute("Nutrition", 26)
    browse:SetAttribute("FoodKind", "TreeBrowse")
    browse:SetAttribute("EdibleVegetation", true)
    browse:SetAttribute("TreeBrowse", true)
    browse:SetAttribute("VegetationType", "TreeCanopy")
    browse:SetAttribute("PlantPart", "Leaves")
    browse:SetAttribute("BrowseTier", "Tree")
    browse:SetAttribute("BrowseHeightStuds", 7.5)
    browse:SetAttribute("CompactFoodGroup", "TreeBrowse")
    browse:SetAttribute("RespawnCooldownSeconds", 75)
    local ok, record = NPCService:Register(npc, "Prey")
    record.Hatched = true
    record.Hunger = 20
    record.Thirst = 90

    Assert.truthy(ok, "prey registers")
    Assert.truthy(NPCService:TickBrain(record, {}, 1), "hungry herbivore tick succeeds")
    Assert.equals(record.State, "Eat", "hungry herbivore eats nearby tree browse")
    Assert.equals(browse:GetAttribute("Depleted"), true, "tree browse is depleted by herbivore")
    Assert.equals(npc:GetAttribute("LastBrainAction"), "Eat", "eat action is visible on NPC")
    Assert.truthy(record.Hunger > 20, "tree browse restores hunger")

    npc:Destroy(); browse:Destroy()
end })


table.insert(suite.tests, { name = "prey flees then hides when badly hurt", run = function()
    resetNPCs()
    local predator = makeNPC("HidePredatorNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("HidePreyNPC", Vector3.new(5, 3, 0))
    local _, predatorRecord = NPCService:Register(predator, "Predator")
    local _, preyRecord = NPCService:Register(prey, "Prey")
    predatorRecord.Hatched = true
    preyRecord.Hatched = true

    NPCService:TickBrain(preyRecord, {}, 1)
    Assert.equals(preyRecord.State, "Flee", "healthy prey flees predator")
    preyRecord.Health = 20
    NPCService:TickBrain(preyRecord, {}, 1)
    Assert.equals(preyRecord.State, "Hide", "hurt prey hides from predator")
    Assert.equals(prey:GetAttribute("Hidden"), true, "hide state visible on instance")

    predator:Destroy(); prey:Destroy()
end })

table.insert(suite.tests, { name = "apex NPC stamps territory event and scares nearby herd", run = function()
    resetNPCs()
    local apex = makeNPC("ApexTyrannosaurusNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("ApexScaredPreyNPC", Vector3.new(20, 3, 0))
    local apexOk, apexRecord = NPCService:Register(apex, "Apex")
    local preyOk = NPCService:Register(prey, "Prey")
    apexRecord.Hatched = true

    Assert.truthy(apexOk and preyOk, "apex and prey register")
    NPCService:TickBrain(apexRecord, {}, 1)
    Assert.equals(apexRecord.State, "ApexEvent", "apex territory event state")
    Assert.equals(apex:GetAttribute("ApexCategory"), true, "apex flag on instance")
    Assert.equals(apex:GetAttribute("ApexEventActive"), true, "apex event stamped")
    Assert.equals(apex:GetAttribute("ApexEventState"), "Broadcast", "apex event broadcast state visible")
    Assert.equals(apex:GetAttribute("ApexEventGateReason"), "ready", "apex event gate reason visible")
    Assert.truthy(apex:GetAttribute("ApexEventAffected") >= 1, "nearby NPC affected")
    Assert.equals(apex:GetAttribute("ApexEventSourceX"), 0, "apex source x visible for HUD/live proof")
    Assert.equals(apex:GetAttribute("ApexEventSourceY"), 3, "apex source y visible for HUD/live proof")
    Assert.equals(apex:GetAttribute("ApexEventSourceZ"), 0, "apex source z visible for HUD/live proof")
    Assert.equals(apex:GetAttribute("ApexEventCooldownSeconds"), NPCService.ApexEventCooldownSeconds, "apex cooldown visible")
    Assert.equals(prey:GetAttribute("LastApexThreat"), "ApexTyrannosaurusNPC", "prey sees apex threat")
    Assert.equals(prey:GetAttribute("ApexThreatState"), "Warned", "affected prey has warning state")
    Assert.equals(prey:GetAttribute("ApexThreatSourceX"), 0, "prey sees apex source x")

    apex:Destroy(); prey:Destroy()
end })

table.insert(suite.tests, { name = "apex observable event is cooldown gated between broadcasts", run = function()
    resetNPCs()
    local apex = makeNPC("ApexCooldownNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("ApexCooldownPreyNPC", Vector3.new(30, 3, 0))
    local _, apexRecord = NPCService:Register(apex, "Apex")
    NPCService:Register(prey, "Prey")
    apexRecord.Hatched = true

    Assert.truthy(NPCService:StampApexEvent(apexRecord, 100), "first apex broadcast succeeds")
    Assert.equals(apex:GetAttribute("ApexEventActive"), true, "first event active")
    Assert.equals(apex:GetAttribute("ApexEventSequence"), 1, "first event sequence stamped")
    local ok, reason = NPCService:StampApexEvent(apexRecord, 105)
    Assert.falsy(ok, "second apex broadcast inside cooldown is gated")
    Assert.equals(reason, "cooldown", "cooldown gate reason returned")
    Assert.equals(apex:GetAttribute("ApexEventActive"), false, "cooldown state visible")
    Assert.equals(apex:GetAttribute("ApexEventState"), "Gated", "gated event state visible")
    Assert.equals(apex:GetAttribute("ApexEventGateReason"), "cooldown", "cooldown reason visible")
    Assert.truthy(apex:GetAttribute("ApexEventCooldownRemaining") > 0, "cooldown remaining visible")
    Assert.equals(apex:GetAttribute("ApexEventSequence"), 1, "gated event does not advance sequence")

    Assert.truthy(NPCService:StampApexEvent(apexRecord, 113), "apex rebroadcasts after cooldown")
    Assert.equals(apex:GetAttribute("ApexEventActive"), true, "rebroadcast active")
    Assert.equals(apex:GetAttribute("ApexEventSequence"), 2, "rebroadcast advances sequence")

    apex:Destroy(); prey:Destroy()
end })

table.insert(suite.tests, { name = "apex event takes priority over predator chase brain", run = function()
    resetNPCs()
    local apex = makeNPC("ApexPriorityNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("ApexPriorityPreyNPC", Vector3.new(20, 3, 0))
    local _, apexRecord = NPCService:Register(apex, "Apex")
    NPCService:Register(prey, "Prey")
    apexRecord.Hatched = true

    local playerRoot = Instance.new("Part")
    playerRoot.Name = "HumanoidRootPart"
    playerRoot.Position = Vector3.new(10, 3, 0)
    local character = Instance.new("Model")
    playerRoot.Parent = character

    NPCService:RunPredatorBrain(apexRecord, { { Character = character } })
    Assert.equals(apexRecord.State, "ApexEvent", "apex event stays ahead of chase")
    Assert.equals(apex:GetAttribute("LastBrainAction"), "ApexEvent", "apex action stamped before chase")
    Assert.falsy(apex:GetAttribute("AttackRangeConfirmed"), "apex event did not fall through to attack")

    apex:Destroy(); prey:Destroy(); character:Destroy()
end })

table.insert(suite.tests, { name = "herding prey exposes center target and coordinated motion", run = function()
    resetNPCs()
    local lead = makeNPC("HerdAlphaPreyNPC", Vector3.new(0, 3, 0))
    local member = makeNPC("HerdMemberPreyNPC", Vector3.new(30, 3, 0))
    local third = makeNPC("HerdThirdPreyNPC", Vector3.new(60, 3, 0))
    local _, leadRecord = NPCService:Register(lead, "Prey")
    local _, memberRecord = NPCService:Register(member, "Prey")
    local _, thirdRecord = NPCService:Register(third, "Prey")
    leadRecord.Hatched = true
    memberRecord.Hatched = true
    thirdRecord.Hatched = true
    leadRecord.Hunger = 90
    leadRecord.Thirst = 90
    memberRecord.Hunger = 90
    memberRecord.Thirst = 90
    thirdRecord.Hunger = 90
    thirdRecord.Thirst = 90

    NPCService:TickBrain(leadRecord, {}, 1)
    Assert.equals(leadRecord.State, "Herd", "prey enters herd state")
    Assert.equals(lead:GetAttribute("HerdSize"), 3, "herd size visible")
    Assert.equals(lead:GetAttribute("HerdLeader"), "HerdAlphaPreyNPC", "stable herd leader visible")
    Assert.equals(lead:GetAttribute("HerdGroupId"), "Herd:HerdAlphaPreyNPC", "herd group id visible")
    Assert.equals(lead:GetAttribute("HerdCenterX"), 30, "numeric herd center x visible")
    Assert.equals(lead:GetAttribute("HerdCenterY"), 3, "numeric herd center y visible")
    Assert.equals(lead:GetAttribute("HerdCenterZ"), 0, "numeric herd center z visible")
    Assert.equals(lead:GetAttribute("HerdTargetX"), 30, "herd target x visible")
    Assert.equals(lead:GetAttribute("HerdTargetY"), 3, "herd target y visible")
    Assert.equals(lead:GetAttribute("HerdTargetZ"), 0, "herd target z visible")
    Assert.equals(lead:GetAttribute("HerdCoordinatedMotion"), true, "coordinated motion flag visible")
    Assert.equals(lead:GetAttribute("HerdEventState"), "Regrouping", "herd regroup state visible")
    Assert.truthy(lead:GetAttribute("HerdMotionX") > 0.9, "herd motion points toward center")
    Assert.between(lead:GetAttribute("HerdCohesionDistance"), 29.9, 30.1, "cohesion distance visible")
    Assert.equals(lead:GetAttribute("LastBrainAction"), "Herd", "herd action visible")
    Assert.truthy((NPCService:GetRecordPosition(leadRecord) - Vector3.new(0, 3, 0)).Magnitude > 0, "herd leader moves toward center")

    lead:Destroy(); member:Destroy(); third:Destroy()
end })

table.insert(suite.tests, { name = "herding omnivore eats plant and carcass diets", run = function()
    resetNPCs()
    local omnivore = makeNPC("OviraptorOmnivoreNPC", Vector3.new(0, 3, 0))
    local herdMate = makeNPC("OviraptorHerdMateNPC", Vector3.new(8, 3, 0))
    local plant = makeTaggedPart("MixedFern", "FoodSource", Vector3.new(4, 3, 0))
    plant:SetAttribute("Diet", "Herbivore")
    plant:SetAttribute("Nutrition", 25)
    local carcass = makeTaggedPart("MixedCarcass", "FoodSource", Vector3.new(30, 3, 0))
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", 25)
    local _, record = NPCService:Register(omnivore, "Omnivore")
    local _, mateRecord = NPCService:Register(herdMate, "Omnivore")
    record.Hatched = true
    mateRecord.Hatched = true

    Assert.equals(record.Diet, "Omnivore", "omnivore profile diet")
    record.Hunger = 20
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "omnivore eats nearby plant food")
    Assert.equals(plant:GetAttribute("Depleted"), true, "plant food depleted by omnivore")

    record.Hunger = 20
    carcass:SetAttribute("Depleted", false)
    carcass.Position = Vector3.new(4, 3, 0)
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "omnivore eats nearby carcass food")
    Assert.equals(carcass:GetAttribute("Depleted"), true, "carcass food depleted by omnivore")

    record.Hunger = 90
    record.Thirst = 90
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(omnivore:GetAttribute("HerdingEnabled"), true, "herding flag on omnivore")
    Assert.truthy((omnivore:GetAttribute("HerdSize") or 0) >= 2, "omnivore herd size stamped")

    omnivore:Destroy(); herdMate:Destroy(); plant:Destroy(); carcass:Destroy()
end })

return suite
