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
