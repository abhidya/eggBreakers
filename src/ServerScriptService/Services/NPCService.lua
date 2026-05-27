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

function NPCService:CreateCarcassFoodSource(record)
    local npc = record and record.Instance
    if not npc then return nil, "missing_npc" end
    local carcass = Instance.new("Part")
    carcass.Name = (npc.Name or "Prey") .. "_CarcassFood"
    carcass.Anchored = true
    carcass.CanCollide = false
    carcass.CanTouch = true
    carcass.CanQuery = true
    carcass.Size = Vector3.new(7, 1.5, 4)
    carcass.Color = Color3.fromRGB(118, 58, 47)
    carcass.Material = Enum.Material.Slate
    local pos = record.SpawnPosition or Vector3.new(0, 12, 0)
    if npc.GetPivot then pos = npc:GetPivot().Position end
    carcass.Position = Vector3.new(pos.X, math.max(pos.Y, 12), pos.Z)
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", 45)
    carcass:SetAttribute("Depleted", false)
    carcass:SetAttribute("SourceNPC", npc.Name)
    carcass:SetAttribute("PlacementRole", "PreyCarcassFood")
    carcass.Parent = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("FoodSources") or workspace
    CollectionService:AddTag(carcass, "FoodSource")
    return carcass
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

function NPCService:CreateCarcassFoodSource(npc, nutrition)
    local carcass = Instance.new("Part")
    carcass.Name = (npc and npc.Name or "Prey") .. "_CarcassFoodSource"
    carcass.Anchored = true
    carcass.CanCollide = false
    carcass.CanTouch = false
    carcass.CanQuery = true
    carcass.Shape = Enum.PartType.Ball
    carcass.Material = Enum.Material.Leather
    carcass.Color = Color3.fromRGB(125, 58, 48)
    carcass.Size = Vector3.new(8, 3, 5)
    local position = Vector3.new(0, 3, 0)
    if npc and npc.GetPivot then
        position = npc:GetPivot().Position
    elseif npc and npc:IsA("BasePart") then
        position = npc.Position
    end
    carcass.Position = position
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", nutrition or 35)
    carcass:SetAttribute("FoodKind", "PreyCarcass")
    carcass:SetAttribute("Depleted", false)
    carcass:SetAttribute("RespawnCooldownSeconds", 180)
    carcass:SetAttribute("CreatorStoreOnly", true)
    carcass:SetAttribute("ImportedVisibleAsset", true)
    carcass:SetAttribute("AssetManifestId", "CS-739396590")
    carcass.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    CollectionService:AddTag(carcass, "FoodSource")
    return carcass
end

function NPCService:MarkPreyDead(record)
    if not record or record.Kind ~= "Prey" then return false, "not_prey" end
    self:Transition(record, "Dead")
    record.Carcass = self:CreateCarcassFoodSource(record.Instance, 35)
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
