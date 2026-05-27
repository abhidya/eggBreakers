local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local NPCService = { TickLoopStarted = false }
NPCService.MinActive = 12
NPCService.MaxActive = 30
NPCService.AllowedStates = { Idle=true, Wander=true, Flee=true, SeekFood=true, SeekWater=true, Chase=true, Attack=true, Dead=true, Despawn=true }
NPCService.NPCs = {}
NPCService.FleeDistance = 80
NPCService.TickSeconds = 1

function NPCService:CanSpawn(positionOk, activeCount)
    activeCount = activeCount or #self.NPCs
    return positionOk == true and activeCount < self.MaxActive
end

function NPCService:Register(npc, kind)
    if #self.NPCs >= self.MaxActive then return false, "cap_reached" end
    local pivotPosition = Vector3.new(0, 0, 0)
    if npc.GetPivot then
        pivotPosition = npc:GetPivot().Position
    end
    local record = { Instance = npc, Kind = kind, State = "Idle", MaxChaseDistance = 120, DespawnDistance = 350, SpawnPosition = pivotPosition }
    table.insert(self.NPCs, record)
    return true, record
end

function NPCService:Transition(record, nextState)
    if not self.AllowedStates[nextState] then return false, "bad_state" end
    if record.Kind == "Prey" and not ({ Idle=true, Wander=true, Flee=true, Dead=true, Despawn=true })[nextState] then return false, "prey_state_forbidden" end
    if record.Kind == "Predator" and not ({ Idle=true, Wander=true, Chase=true, Attack=true, Dead=true, Despawn=true })[nextState] then return false, "predator_state_forbidden" end
    record.State = nextState
    if nextState == "Dead" and record.Kind == "Prey" then
        record.Carcass = self:CreateCarcassFoodSource(record)
    end
    return true
end

function NPCService:GetRecordPosition(record)
    local npc = record and record.Instance
    if npc and npc.GetPivot then
        return npc:GetPivot().Position
    elseif npc and npc:IsA("BasePart") then
        return npc.Position
    end
    return record and record.SpawnPosition or Vector3.new(0, 0, 0)
end

function NPCService:TickPreyFlee(record, threatPosition, fleeDistance)
    if not record or record.Kind ~= "Prey" or record.State == "Dead" then return false, "not_active_prey" end
    if typeof(threatPosition) ~= "Vector3" then return false, "missing_threat" end
    local position = self:GetRecordPosition(record)
    if (position - threatPosition).Magnitude <= (fleeDistance or 55) then
        record.FleeFrom = threatPosition
        record.LastFleeAt = os.time()
        return self:Transition(record, "Flee")
    end
    if record.State == "Flee" then
        return self:Transition(record, "Wander")
    end
    return false, "no_threat"
end

function NPCService:Tick(players)
    local fled = 0
    for _, record in ipairs(self.NPCs) do
        if record.Kind == "Prey" and record.State ~= "Dead" then
            for _, player in ipairs(players or {}) do
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and self:TickPreyFlee(record, root.Position) then
                    fled = fled + 1
                    break
                end
            end
        end
    end
    return fled
end

function NPCService:CanChaseIntoZone(zoneId, scriptedTutorialScare)
    if zoneId == "NurseryGrove" and not scriptedTutorialScare then return false end
    return true
end

function NPCService:ResolveImportedCarcassVisual()
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("ImportedAssetLibrary")
    if not library then return nil end
    for _, descendant in ipairs(library:GetDescendants()) do
        local name = string.lower(descendant.Name)
        if (string.find(name, "fossil", 1, true) or string.find(name, "bone", 1, true) or string.find(name, "dinosaur", 1, true) or string.find(name, "egg", 1, true)) then
            if descendant:IsA("Model") or descendant:IsA("BasePart") then
                if descendant:IsA("BasePart") or descendant:FindFirstChildWhichIsA("BasePart", true) then
                    return descendant
                end
            end
        end
    end
    return nil
end

function NPCService:CreateCarcassFoodSource(npcOrRecord, nutrition)
	local record = type(npcOrRecord) == "table" and npcOrRecord.Instance ~= nil and npcOrRecord or nil
	local npc = record and record.Instance or npcOrRecord
    if not npc then return nil, "missing_npc" end
    local position = Vector3.new(0, 3, 0)
    if npc and npc.GetPivot then
        position = npc:GetPivot().Position
    elseif npc and npc:IsA("BasePart") then
        position = npc.Position
    elseif record and record.SpawnPosition then
        position = record.SpawnPosition
    end
    local source = self:ResolveImportedCarcassVisual()
    if not source then return nil, "missing_imported_carcass_visual" end
    local carcass = source:Clone()
    if carcass:IsA("BasePart") then
        local wrapper = Instance.new("Model")
        wrapper.Name = (npc.Name or "Prey") .. "_CarcassFoodSource"
        carcass.Parent = wrapper
        wrapper.PrimaryPart = carcass
        carcass = wrapper
    else
        carcass.Name = (npc.Name or "Prey") .. "_CarcassFoodSource"
    end
    for _, descendant in ipairs(carcass:GetDescendants()) do
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
    if carcass:IsA("Model") then
        if not carcass.PrimaryPart then carcass.PrimaryPart = carcass:FindFirstChildWhichIsA("BasePart", true) end
        if carcass.PrimaryPart then carcass:PivotTo(CFrame.new(position)) end
    end
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", nutrition or 35)
    carcass:SetAttribute("FoodKind", "PreyCarcass")
    carcass:SetAttribute("Depleted", false)
    carcass:SetAttribute("RespawnCooldownSeconds", 180)
    carcass:SetAttribute("CreatorStoreOnly", true)
    carcass:SetAttribute("ImportedVisibleAsset", true)
    carcass:SetAttribute("AssetManifestId", carcass:GetAttribute("AssetManifestId") or "ImportedPreyCarcass")
    carcass:SetAttribute("SourceNPC", npc.Name)
    carcass.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    CollectionService:AddTag(carcass, "FoodSource")
    return carcass
end

function NPCService:MarkPreyDead(record)
    if not record or record.Kind ~= "Prey" then return false, "not_prey" end
    self:Transition(record, "Dead")
    if not record.Carcass then
        record.Carcass = self:CreateCarcassFoodSource(record, 35)
    end
    return true, record.Carcass
end

function NPCService:TickNPCs(players)
    for _, record in ipairs(self.NPCs) do
        if record.State ~= "Dead" and record.Kind == "Prey" then
            local npc = record.Instance
            local npcPosition = record.SpawnPosition
            if npc and npc.GetPivot then npcPosition = npc:GetPivot().Position end
            for _, player in ipairs(players or {}) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - npcPosition).Magnitude <= self.FleeDistance then
                    record.State = "Flee"
                    record.FleeFrom = player
                    record.LastFleeAt = os.time()
                    break
                end
            end
        end
    end
    return #self.NPCs
end

function NPCService:StartTickLoop(playersService)
    if self.TickLoopStarted then return false, "already_started" end
    self.TickLoopStarted = true
    task.spawn(function()
        while self.TickLoopStarted do
            task.wait(self.TickSeconds)
            self:TickNPCs((playersService or game:GetService("Players")):GetPlayers())
        end
    end)
    return true
end

return NPCService
