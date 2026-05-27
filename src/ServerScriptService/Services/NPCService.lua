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

function NPCService:Transition(record, nextState)
    if not self.AllowedStates[nextState] then return false, "bad_state" end
    if record.Kind == "Prey" and not ({ Idle=true, Wander=true, Flee=true, Dead=true, Despawn=true })[nextState] then return false, "prey_state_forbidden" end
    if record.Kind == "Predator" and not ({ Idle=true, Wander=true, Chase=true, Attack=true, Dead=true, Despawn=true })[nextState] then return false, "predator_state_forbidden" end
    record.State = nextState
    return true
end

function NPCService:CanChaseIntoZone(zoneId, scriptedTutorialScare)
    if zoneId == "NurseryGrove" and not scriptedTutorialScare then return false end
    return true
end

return NPCService
