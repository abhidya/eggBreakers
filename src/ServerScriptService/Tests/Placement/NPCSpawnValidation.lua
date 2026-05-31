local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)

local suite = { name = "NPCSpawnValidation.server", category = "Placement", tests = {} }

local function hasVisiblePart(instance)
    if instance:IsA("BasePart") and instance.Transparency < 1 then return true end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then return true end
    end
    return false
end

table.insert(suite.tests, { name = "NPC spawn zones valid", run = function()
    local spawn = Instance.new("Part")
    spawn.Name = "FernPlainsSpawn"
    Assert.truthy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "valid spawn allowed")
    spawn:SetAttribute("InsideWall", true)
    Assert.falsy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "wall spawn rejected")
    spawn:Destroy()
end })

table.insert(suite.tests, { name = "spawn loop can materialize active NPC records", run = function()
    local old = NPCSpawnService.TargetActive
    local before = #NPCService.NPCs
    NPCSpawnService.TargetActive = math.min(before + 1, NPCService.MaxActive)
    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.truthy(active >= NPCSpawnService.TargetActive, "spawn loop reaches target")
    NPCSpawnService.TargetActive = old
end })

table.insert(suite.tests, { name = "spawn loop prunes parentless records before active count", run = function()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    local oldCreate = NPCSpawnService.CreateNPCRecord
    local spawned = {}

    NPCService.NPCs = {}
    local stale = Instance.new("Model")
    stale.Name = "ParentlessSpawnRecord"
    local staleRoot = Instance.new("Part")
    staleRoot.Name = "Root"
    staleRoot.Parent = stale
    stale.PrimaryPart = staleRoot
    stale.Parent = workspace
    NPCService:Register(stale, "Prey")
    stale:Destroy()

    NPCSpawnService.TargetActive = 1
    NPCSpawnService.CreateNPCRecord = function(self, spawnInstance, kind, index)
        local npc = Instance.new("Model")
        npc.Name = "PrunedRecordReplacement_" .. tostring(index)
        local root = Instance.new("Part")
        root.Name = "Root"
        root.Parent = npc
        npc.PrimaryPart = root
        npc:SetAttribute("NPCKind", kind or "Prey")
        npc.Parent = self:EnsureNPCFolder()
        table.insert(spawned, npc)
        return NPCService:Register(npc, kind or "Prey")
    end

    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.equals(active, 1, "parentless record does not count as active")
    Assert.equals(#NPCService.NPCs, 1, "stale record pruned before top-up")
    Assert.truthy(NPCService.NPCs[1].Instance and NPCService.NPCs[1].Instance.Parent ~= nil, "remaining record has live instance")

    for _, npc in ipairs(spawned) do npc:Destroy() end
    NPCSpawnService.CreateNPCRecord = oldCreate
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "spawn loop continues after one spawn failure", run = function()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    local oldCreate = NPCSpawnService.CreateNPCRecord
    local spawned = {}
    local calls = 0

    NPCService.NPCs = {}
    NPCSpawnService.TargetActive = 2
    NPCSpawnService.CreateNPCRecord = function(self, spawnInstance, kind, index)
        calls = calls + 1
        if calls == 1 then
            return false, "test_missing_model"
        end
        local npc = Instance.new("Model")
        npc.Name = "ContinuationSpawn_" .. tostring(index)
        local root = Instance.new("Part")
        root.Name = "Root"
        root.Parent = npc
        npc.PrimaryPart = root
        npc:SetAttribute("NPCKind", kind or "Prey")
        npc.Parent = self:EnsureNPCFolder()
        table.insert(spawned, npc)
        return NPCService:Register(npc, kind or "Prey")
    end

    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.equals(active, 2, "spawn loop fills target after a single failed spawn")
    Assert.truthy(calls >= 3, "spawn loop attempted later candidates after failure")
    Assert.equals(NPCSpawnService.LastSpawnFailures, 1, "spawn failure probe counted the skipped spawn")
    Assert.equals(NPCSpawnService.LastSpawnFailureReason, "test_missing_model", "spawn failure probe records reason")

    for _, npc in ipairs(spawned) do npc:Destroy() end
    NPCSpawnService.CreateNPCRecord = oldCreate
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "staged NPC helper root remains invisible after prepare", run = function()
    local source = Instance.new("Model")
    source.Name = "StagedNPCHelperProbe"
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(48, 48, 48)
    root.Transparency = 0
    root.Parent = source
    source.PrimaryPart = root
    local body = Instance.new("MeshPart")
    body.Name = "VisibleBody"
    body.Size = Vector3.new(6, 4, 12)
    body.Transparency = 0
    body.Parent = source

    local marker = Instance.new("Part")
    marker.Name = "NPCPrepareProbeSpawn"
    marker.Position = Vector3.new(0, 14, 0)
    local prepared = NPCSpawnService:PrepareNPCModel(source, "Prey", 9001, marker)
    local preparedRoot = prepared:FindFirstChild("RootPart", true)
    local preparedBody = prepared:FindFirstChild("VisibleBody", true)

    Assert.notNil(preparedRoot, "prepared NPC has helper root")
    Assert.notNil(preparedBody, "prepared NPC keeps visible mesh body")
    Assert.equals(preparedRoot.Transparency, 1, "NPC helper root is hidden")
    Assert.equals(preparedRoot.CanCollide, false, "NPC helper root does not collide")
    Assert.equals(preparedRoot.CanTouch, false, "NPC helper root does not touch")
    Assert.equals(preparedRoot.CanQuery, false, "NPC helper root does not query")
    Assert.equals(preparedRoot:GetAttribute("NPCInvisibleRigHelper"), true, "NPC helper root is marked")
    Assert.truthy(preparedBody.Transparency < 1, "NPC mesh body remains visible")

    prepared:Destroy()
    marker:Destroy()
    source:Destroy()
end })

table.insert(suite.tests, { name = "authored NPC spawn markers cover prey and predators", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureNPCSpawnMarkers(folders)
    local prey = 0
    local predators = 0
    local aerialPrey = 0
    local aerialPredators = 0
    for _, marker in ipairs(folders.NPCSpawns:GetChildren()) do
        if marker:GetAttribute("NPCKind") == "Prey" then
            prey = prey + 1
        elseif marker:GetAttribute("NPCKind") == "Predator" then
            predators = predators + 1
        elseif marker:GetAttribute("NPCKind") == "AerialPrey" then
            aerialPrey = aerialPrey + 1
            Assert.equals(marker:GetAttribute("AerialSpawn"), true, marker.Name .. " marked as aerial spawn")
            Assert.truthy((marker:GetAttribute("PreferredAltitude") or 0) > 0, marker.Name .. " has preferred altitude")
        elseif marker:GetAttribute("NPCKind") == "AerialPredator" then
            aerialPredators = aerialPredators + 1
            Assert.equals(marker:GetAttribute("AerialSpawn"), true, marker.Name .. " marked as aerial predator spawn")
        end
        Assert.truthy(marker:GetAttribute("NPCSpawn") == true, marker.Name .. " marked as NPC spawn")
        Assert.truthy(type(marker:GetAttribute("ZoneId")) == "string", marker.Name .. " has zone id")
    end
    Assert.truthy(#folders.NPCSpawns:GetChildren() >= 12, "map has enough authored NPC spawn markers for live population")
    Assert.truthy(prey >= 6, "prey spawns exist across biomes")
    Assert.truthy(predators >= 4, "predator spawns exist outside nursery")
    Assert.truthy(aerialPrey >= 2, "aerial prey spawns exist near cliffs/canyons")
    Assert.truthy(aerialPredators >= 1, "pterodactyl/aerial predator spawn exists")
end })

table.insert(suite.tests, { name = "authored NPC spawns expose species and deferred food metadata", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureNPCSpawnMarkers(folders)

    local bySpecies = {}
    local liveFood = 0
    local defeatedFood = 0
    for _, marker in ipairs(folders.NPCSpawns:GetChildren()) do
        local kind = marker:GetAttribute("NPCKind")
        local speciesId = marker:GetAttribute("SpeciesId")
        Assert.truthy(type(speciesId) == "string" and speciesId ~= "", marker.Name .. " has source species expectation")
        Assert.equals(marker:GetAttribute("FoodSourceCandidate"), true, marker.Name .. " is audited as deferred food candidate")
        Assert.equals(marker:GetAttribute("FoodWhenDefeated"), true, marker.Name .. " can become food when defeated")
        Assert.truthy(type(marker:GetAttribute("CarnivoreFoodKind")) == "string", marker.Name .. " has carcass kind")
        Assert.truthy(type(marker:GetAttribute("GroundTopY")) == "number", marker.Name .. " has ground top for floating checks")
        Assert.equals(marker:GetAttribute("AvoidOverlap"), true, marker.Name .. " opts into overlap validation")
        bySpecies[speciesId] = (bySpecies[speciesId] or 0) + 1
        if marker:GetAttribute("PotentialCarnivoreFood") == true then
            liveFood = liveFood + 1
            Assert.truthy(kind == "Prey" or kind == "AerialPrey" or kind == "FlyingPrey", marker.Name .. " only live prey advertises carnivore food")
        end
        if marker:GetAttribute("FoodWhenDefeated") == true then defeatedFood = defeatedFood + 1 end
    end

    Assert.truthy((bySpecies.gallimimus or 0) >= 6, "gallimimus/prey has multiple relevant spawn points")
    Assert.truthy((bySpecies.carnotaurus or 0) >= 4, "carnotaurus/predator has multiple relevant spawn points")
    Assert.truthy(liveFood >= 6, "live prey NPCs are potential carnivore food")
    Assert.equals(defeatedFood, #folders.NPCSpawns:GetChildren(), "every authored NPC can produce defeated-food metadata")
end })

table.insert(suite.tests, { name = "spawn loop reaches visible world target from authored markers", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    NPCService.NPCs = {}
    NPCSpawnService.TargetActive = 12
    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.truthy(active >= 12, "spawn loop reaches 12 active NPCs")
    local folder = workspace:FindFirstChild("NPCs")
    Assert.truthy(folder and #folder:GetChildren() >= 12, "visible NPC instances exist in Workspace.NPCs")
    local visibleDinosaurs = 0
    local carnivores = 0
    for _, npc in ipairs(folder:GetChildren()) do
        if npc:GetAttribute("NPCKind") == "Prey" or npc:GetAttribute("NPCKind") == "Predator" or npc:GetAttribute("NPCKind") == "AerialPrey" or npc:GetAttribute("NPCKind") == "AerialPredator" then
            if hasVisiblePart(npc) then visibleDinosaurs = visibleDinosaurs + 1 end
            if npc:GetAttribute("NPCKind") == "Predator" or npc:GetAttribute("NPCKind") == "AerialPredator" or npc:GetAttribute("Carnivore") == true or npc:GetAttribute("Diet") == "Carnivore" then
                carnivores = carnivores + 1
            end
        end
    end
    Assert.truthy(visibleDinosaurs >= 10, "at least 10 visible dinosaur NPCs exist")
    Assert.truthy(carnivores >= 4, "visible dinosaur population includes carnivores")
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "prey flees nearby players", run = function()
    local prey = Instance.new("Model")
    prey.Name = "FleePrey"
    prey:PivotTo(CFrame.new(0, 3, 0))
    prey.Parent = workspace
    local ok, record = NPCService:Register(prey, "Prey")
    Assert.truthy(ok, "prey registered")
    local player = { Character = Instance.new("Model") }
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(3, 3, 0)
    root.Parent = player.Character
    NPCService:TickNPCs({ player })
    Assert.equals(record.State, "Flee", "nearby player triggers flee")
    prey:Destroy()
end })


table.insert(suite.tests, { name = "active NPC brain moves prey and predators", run = function()
    local oldRecords = NPCService.NPCs
    NPCService.NPCs = {}

    local prey = Instance.new("Model")
    prey.Name = "BrainPrey"
    local preyRoot = Instance.new("Part")
    preyRoot.Name = "HumanoidRootPart"
    preyRoot.Size = Vector3.new(2, 2, 2)
    preyRoot.Parent = prey
    prey.PrimaryPart = preyRoot
    prey:PivotTo(CFrame.new(0, 3, 0))
    prey.Parent = workspace
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    Assert.truthy(preyOk, "prey registered for brain")

    local predator = Instance.new("Model")
    predator.Name = "BrainPredator"
    local predatorRoot = Instance.new("Part")
    predatorRoot.Name = "HumanoidRootPart"
    predatorRoot.Size = Vector3.new(2, 2, 2)
    predatorRoot.Parent = predator
    predator.PrimaryPart = predatorRoot
    predator:PivotTo(CFrame.new(40, 3, 0))
    predator.Parent = workspace
    local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
    Assert.truthy(predatorOk, "predator registered for brain")

    local player = { Character = Instance.new("Model") }
    local playerRoot = Instance.new("Part")
    playerRoot.Name = "HumanoidRootPart"
    playerRoot.Position = Vector3.new(6, 3, 0)
    playerRoot.Parent = player.Character

    local preyStart = NPCService:GetRecordPosition(preyRecord)
    local predatorStart = NPCService:GetRecordPosition(predatorRecord)
    local active = NPCService:TickNPCs({ player })
    Assert.truthy(active >= 2, "brain ticks both NPCs")
    Assert.equals(preyRecord.State, "Flee", "prey flees nearby player")
    Assert.equals(predatorRecord.State, "Chase", "predator chases player outside attack range")
    Assert.truthy((NPCService:GetRecordPosition(preyRecord) - preyStart).Magnitude > 0, "prey visibly moved")
    Assert.truthy((NPCService:GetRecordPosition(predatorRecord) - predatorStart).Magnitude > 0, "predator visibly moved")
    Assert.equals(prey:GetAttribute("ActiveNPCBrain"), true, "prey has active brain marker")
    Assert.truthy((prey:GetAttribute("BrainMoveCount") or 0) > 0, "prey brain movement count recorded")
    Assert.equals(predator:GetAttribute("LastBrainAction"), "Chase", "predator action marker set")
    Assert.truthy((predator:GetAttribute("BrainMoveCount") or 0) > 0, "predator brain movement count recorded")

    prey:Destroy()
    predator:Destroy()
    player.Character:Destroy()
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "prey/danger spawns separated and hard cap exists", run = function()
    Assert.equals(NPCService.MaxActive, 30, "hard NPC cap")
    Assert.truthy(NPCSpawnService.TargetActive <= NPCService.MaxActive, "target active does not exceed hard cap")
    Assert.falsy(NPCService:CanChaseIntoZone("NurseryGrove", false), "predators cannot chase into nursery without scripted scare")
end })

TestRunner.registerSuite(suite)
return suite
