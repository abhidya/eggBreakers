local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local NPCService = require(script.Parent.NPCService)

local NPCSpawnService = { SpawnLoopRunning = false }
NPCSpawnService.TargetActive = 12
NPCSpawnService.SpawnKinds = { "Prey", "Prey", "Prey", "Predator" }
NPCSpawnService.SpawnTickSeconds = 10

function NPCSpawnService:GetSpawnFolder()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("NPCSpawns")
end

function NPCSpawnService:IsSpawnPositionAllowed(spawnInstance)
    if not spawnInstance then return false end
    if spawnInstance:GetAttribute("InsideWall") then return false end
    if spawnInstance:GetAttribute("InsideWater") then return false end
    if spawnInstance:GetAttribute("InsideCityProp") then return false end
    if spawnInstance:GetAttribute("SafeBabyArea") and spawnInstance:GetAttribute("DangerousNPC") then return false end
    return true
end

function NPCSpawnService:CreateNPCRecord(spawnInstance, kind, index)
    local model = Instance.new("Model")
    model.Name = kind .. "NPC_" .. tostring(index)
    model:SetAttribute("NPCKind", kind)
    model:SetAttribute("SpawnZone", spawnInstance and spawnInstance.Name or "Generated")
    model.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    return NPCService:Register(model, kind)
end

function NPCSpawnService:EnsureNPCFolder()
    local folder = Workspace:FindFirstChild("NPCs")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "NPCs"
        folder.Parent = Workspace
    end
    return folder
end

function NPCSpawnService:MaintainMinimumActive()
    self:EnsureNPCFolder()
    local active = #NPCService.NPCs
    local spawnFolder = self:GetSpawnFolder()
    local spawns = spawnFolder and spawnFolder:GetChildren() or {}
    local index = active
    while active < self.TargetActive and active < NPCService.MaxActive do
        index = index + 1
        local spawnInstance = spawns[((index - 1) % math.max(#spawns, 1)) + 1]
        if #spawns == 0 or self:IsSpawnPositionAllowed(spawnInstance) then
            local kind = self.SpawnKinds[((index - 1) % #self.SpawnKinds) + 1]
            local ok = self:CreateNPCRecord(spawnInstance, kind, index)
            if ok then active = active + 1 else break end
        else
            break
        end
    end
    return active
end

function NPCSpawnService:StartSpawnLoop(intervalSeconds)
    if self.SpawnLoopRunning then return false, "already_running" end
    self.SpawnLoopRunning = true
    task.spawn(function()
        while self.SpawnLoopRunning do
            self:MaintainMinimumActive()
            NPCService:Tick(Players:GetPlayers())
            task.wait(intervalSeconds or 3)
        end
    end)
    return true
end

function NPCSpawnService:StopSpawnLoop()
    self.SpawnLoopRunning = false
end

return NPCSpawnService
