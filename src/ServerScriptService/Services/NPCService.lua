local CollectionService = game:GetService("CollectionService")

local NPCService = {}
NPCService.MinActive = 12
NPCService.MaxActive = 30
NPCService.AllowedStates = { Idle=true, Wander=true, Flee=true, SeekFood=true, SeekWater=true, Chase=true, Attack=true, Dead=true, Despawn=true }
NPCService.NPCs = {}

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

function NPCService:CanChaseIntoZone(zoneId, scriptedTutorialScare)
    if zoneId == "NurseryGrove" and not scriptedTutorialScare then return false end
    return true
end

return NPCService
