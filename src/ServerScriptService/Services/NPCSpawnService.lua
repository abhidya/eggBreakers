local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCService = require(script.Parent.NPCService)

local NPCSpawnService = { SpawnLoopRunning = false }
NPCSpawnService.TargetActive = 12
NPCSpawnService.SpawnKinds = { "Prey", "Prey", "Prey", "Predator" }
NPCSpawnService.SpawnTickSeconds = 10
NPCSpawnService.NPCModelCandidatePaths = {
    Prey = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/Hatchling",
    },
    Predator = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Hatchling",
    },
}

local function resolvePath(path)
    local current = game
    for segment in string.gmatch(path, "[^/]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

local function hasVisiblePart(instance)
    if instance:IsA("BasePart") and instance.Transparency < 1 then return true end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then return true end
    end
    return false
end

function NPCSpawnService:ResolveImportedNPCModel(kind)
    for _, path in ipairs(self.NPCModelCandidatePaths[kind] or {}) do
        local candidate = resolvePath(path)
        if candidate and hasVisiblePart(candidate) then return candidate end
    end
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        for _, descendant in ipairs(library:GetDescendants()) do
            local name = string.lower(descendant.Name)
            if (string.find(name, "dinosaur", 1, true) or string.find(name, "raptor", 1, true) or string.find(name, "triceratops", 1, true)) and hasVisiblePart(descendant) then
                return descendant
            end
        end
    end
    return nil
end

function NPCSpawnService:PrepareNPCModel(source, kind, index, spawnInstance)
    local clone = source:Clone()
    clone.Name = kind .. "NPC_" .. tostring(index)
    clone:SetAttribute("NPCKind", kind)
    clone:SetAttribute("Diet", kind == "Predator" and "Carnivore" or "Herbivore")
    clone:SetAttribute("Carnivore", kind == "Predator")
    clone:SetAttribute("ImportedVisibleAsset", true)
    clone:SetAttribute("CreatorStoreOnly", true)
    clone:SetAttribute("AssetManifestId", clone:GetAttribute("AssetManifestId") or ("NPC_" .. kind))
    clone:SetAttribute("SourceAssetId", clone:GetAttribute("SourceAssetId") or source:GetAttribute("SourceAssetId"))
    clone:SetAttribute("SpawnZone", spawnInstance and spawnInstance.Name or "Generated")
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        elseif descendant:IsA("ModuleScript") then
            descendant:SetAttribute("ImportedScriptAudited", true)
            descendant:SetAttribute("Sandboxed", true)
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
        end
    end
    local spawnPosition = spawnInstance and spawnInstance:IsA("BasePart") and spawnInstance.Position or Vector3.new(0, 12, 0)
    if clone:IsA("Model") then
        if not clone.PrimaryPart then clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true) end
        if clone.PrimaryPart then clone:PivotTo(CFrame.new(spawnPosition)) end
    elseif clone:IsA("BasePart") then
        local wrapper = Instance.new("Model")
        wrapper.Name = clone.Name
        wrapper:SetAttribute("NPCKind", kind)
        wrapper:SetAttribute("Diet", kind == "Predator" and "Carnivore" or "Herbivore")
        wrapper:SetAttribute("Carnivore", kind == "Predator")
        wrapper:SetAttribute("ImportedVisibleAsset", true)
        wrapper:SetAttribute("CreatorStoreOnly", true)
        wrapper:SetAttribute("AssetManifestId", clone:GetAttribute("AssetManifestId") or ("NPC_" .. kind))
        wrapper:SetAttribute("SourceAssetId", clone:GetAttribute("SourceAssetId"))
        clone.Parent = wrapper
        clone.CFrame = CFrame.new(spawnPosition)
        wrapper.PrimaryPart = clone
        clone = wrapper
    end
    return clone
end

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
    kind = spawnInstance and spawnInstance:GetAttribute("NPCKind") or kind
    local source = self:ResolveImportedNPCModel(kind)
    if not source then return false, "missing_imported_npc_model" end
    local model = self:PrepareNPCModel(source, kind, index, spawnInstance)
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
            local kind = spawnInstance and spawnInstance:GetAttribute("NPCKind") or self.SpawnKinds[((index - 1) % #self.SpawnKinds) + 1]
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
            NPCService:TickNPCs(Players:GetPlayers())
            task.wait(intervalSeconds or 3)
        end
    end)
    return true
end

function NPCSpawnService:StopSpawnLoop()
    self.SpawnLoopRunning = false
end

return NPCSpawnService
