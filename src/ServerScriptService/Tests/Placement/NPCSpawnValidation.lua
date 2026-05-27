local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)

local suite = { name = "NPCSpawnValidation.server", category = "Placement", tests = {} }

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

table.insert(suite.tests, { name = "prey/danger spawns separated and hard cap exists", run = function()
    Assert.equals(NPCService.MaxActive, 30, "hard NPC cap")
    Assert.truthy(NPCSpawnService.TargetActive <= NPCService.MaxActive, "target active does not exceed hard cap")
    Assert.falsy(NPCService:CanChaseIntoZone("NurseryGrove", false), "predators cannot chase into nursery without scripted scare")
end })

TestRunner.registerSuite(suite)
return suite
