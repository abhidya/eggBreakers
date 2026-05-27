local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local NPCService = { TickLoopStarted = false }
NPCService.MinActive = 12
NPCService.MaxActive = 30
NPCService.AllowedStates = { HatchAtNest=true, Idle=true, Wander=true, SeekFood=true, Eat=true, SeekWater=true, Drink=true, Hide=true, Flee=true, Chase=true, Attack=true, Dead=true, Despawn=true }
NPCService.NPCs = {}
NPCService.FleeDistance = 80
NPCService.TickSeconds = 1
NPCService.SenseDistance = 90
NPCService.InteractDistance = 10
NPCService.MoveStep = 8

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
    local record = {
        Instance = npc,
        Kind = kind,
        State = "HatchAtNest",
        MaxChaseDistance = 120,
        DespawnDistance = 350,
        SpawnPosition = pivotPosition,
        NestPosition = pivotPosition,
        Hatched = false,
        Hunger = 65,
        Thirst = 65,
        Health = kind == "Predator" and 140 or 80,
        MaxHealth = kind == "Predator" and 140 or 80,
    }
    if npc then
        npc:SetAttribute("ActiveNPCBrain", true)
        npc:SetAttribute("BrainMoveCount", 0)
        npc:SetAttribute("LastBrainAction", "HatchAtNest")
        npc:SetAttribute("NPCState", record.State)
        npc:SetAttribute("Hatched", false)
        npc:SetAttribute("Hunger", record.Hunger)
        npc:SetAttribute("Thirst", record.Thirst)
        npc:SetAttribute("Health", record.Health)
        npc:SetAttribute("NestX", pivotPosition.X)
        npc:SetAttribute("NestY", pivotPosition.Y)
        npc:SetAttribute("NestZ", pivotPosition.Z)
    end
    table.insert(self.NPCs, record)
    return true, record
end

function NPCService:Transition(record, nextState)
    if not self.AllowedStates[nextState] then return false, "bad_state" end
    record.State = nextState
    if record.Instance then record.Instance:SetAttribute("NPCState", nextState) end
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

function NPCService:GetInstancePosition(instance)
    if not instance then return nil end
    if instance.GetPivot then
        return instance:GetPivot().Position
    elseif instance:IsA("BasePart") then
        return instance.Position
    end
    return nil
end

function NPCService:MoveToward(record, targetPosition, step)
    if not record or typeof(targetPosition) ~= "Vector3" then return false, "missing_target" end
    local npc = record.Instance
    local position = self:GetRecordPosition(record)
    local delta = targetPosition - position
    if delta.Magnitude <= 0.1 then return true end
    local nextPosition = position + delta.Unit * math.min(step or self.MoveStep, delta.Magnitude)
    record.MoveTarget = targetPosition
    record.LastMoveAt = os.time()
    if npc then
        npc:SetAttribute("MoveTargetX", targetPosition.X)
        npc:SetAttribute("MoveTargetY", targetPosition.Y)
        npc:SetAttribute("MoveTargetZ", targetPosition.Z)
        npc:SetAttribute("LastMoveTarget", string.format("%.1f,%.1f,%.1f", targetPosition.X, targetPosition.Y, targetPosition.Z))
        npc:SetAttribute("BrainMoveCount", (npc:GetAttribute("BrainMoveCount") or 0) + 1)
        npc:SetAttribute("LastBrainAction", "Move")
        npc:SetAttribute("LastAction", "Move")
        if npc.PivotTo then
            npc:PivotTo(CFrame.new(nextPosition))
        elseif npc:IsA("BasePart") then
            npc.Position = nextPosition
        end
    end
    return true
end

function NPCService:FindNearestTagged(record, tagName, maxDistance, predicate)
    local position = self:GetRecordPosition(record)
    local best, bestDistance = nil, maxDistance or self.SenseDistance
    for _, candidate in ipairs(CollectionService:GetTagged(tagName)) do
        if not predicate or predicate(candidate) then
            local candidatePosition
            candidatePosition = self:GetInstancePosition(candidate)
            if candidatePosition then
                local distance = (candidatePosition - position).Magnitude
                if distance <= bestDistance then
                    best, bestDistance = candidate, distance
                end
            end
        end
    end
    return best, bestDistance
end

function NPCService:ApplyNeeds(record, deltaSeconds)
    record.Hunger = math.max(0, (record.Hunger or 65) - 2 * (deltaSeconds or 1))
    record.Thirst = math.max(0, (record.Thirst or 65) - 3 * (deltaSeconds or 1))
    if record.Instance then
        record.Instance:SetAttribute("Hunger", record.Hunger)
        record.Instance:SetAttribute("Thirst", record.Thirst)
    end
end

function NPCService:Eat(record, food)
    record.Hunger = math.min(100, (record.Hunger or 0) + (food and food:GetAttribute("Nutrition") or 25))
    local position = self:GetRecordPosition(record)
    local expectedDiet = record.Kind == "Predator" and "Carnivore" or "Herbivore"
    local depletedCount = 0
    local function deplete(target)
        if target and target:GetAttribute("Diet") == expectedDiet and target:GetAttribute("Depleted") ~= true then
            target:SetAttribute("Depleted", true)
            target:SetAttribute("LastEatenByNPC", record.Instance and record.Instance.Name or "NPC")
            depletedCount = depletedCount + 1
        end
    end
    deplete(food)
    for _, candidate in ipairs(CollectionService:GetTagged("FoodSource")) do
        local candidatePosition = self:GetInstancePosition(candidate)
        if candidate ~= food and candidatePosition and (candidatePosition - position).Magnitude <= self.InteractDistance then
            deplete(candidate)
        end
    end
    if record.Instance then
        record.Instance:SetAttribute("Hunger", record.Hunger)
        record.Instance:SetAttribute("LastAction", "Eat")
        record.Instance:SetAttribute("LastBrainAction", "Eat")
        record.Instance:SetAttribute("FoodSourcesDepleted", depletedCount)
    end
    return self:Transition(record, "Eat")
end

function NPCService:Drink(record, water)
    record.Thirst = math.min(100, (record.Thirst or 0) + 35)
    if record.Instance then
        record.Instance:SetAttribute("Thirst", record.Thirst)
        record.Instance:SetAttribute("LastAction", "Drink")
    end
    return self:Transition(record, "Drink")
end

function NPCService:DamageRecord(record, amount)
    if not record or record.State == "Dead" then return false, "not_active" end
    record.Health = math.max(0, (record.Health or record.MaxHealth or 80) - (amount or 10))
    if record.Instance then record.Instance:SetAttribute("Health", record.Health) end
    if record.Health <= 0 then
        return self:Transition(record, "Dead")
    end
    return true
end

function NPCService:AttackRecord(attacker, target)
    if not attacker or not target or target.State == "Dead" then return false, "bad_target" end
    attacker.AttackTarget = target.Instance
    attacker.LastAttackAt = os.time()
    if attacker.Instance then
        attacker.Instance:SetAttribute("LastAction", "Attack")
        attacker.Instance:SetAttribute("AttackTarget", target.Instance and target.Instance.Name or "NPC")
    end
    self:Transition(attacker, "Attack")
    return self:DamageRecord(target, attacker.Kind == "Predator" and 45 or 12)
end

function NPCService:FindNearestRecord(record, kind, maxDistance)
    local position = self:GetRecordPosition(record)
    local best, bestDistance = nil, maxDistance or self.SenseDistance
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.Kind == kind and candidate.State ~= "Dead" then
            local distance = (self:GetRecordPosition(candidate) - position).Magnitude
            if distance <= bestDistance then
                best, bestDistance = candidate, distance
            end
        end
    end
    return best, bestDistance
end

function NPCService:TickBrain(record, players, deltaSeconds)
    if not record or record.State == "Dead" then return false, "not_active" end
    if record.Hatched ~= true then
        record.Hatched = true
        if record.Instance then
            record.Instance:SetAttribute("Hatched", true)
            record.Instance:SetAttribute("LastAction", "HatchAtNest")
        end
        self:Transition(record, "Wander")
    end
    self:ApplyNeeds(record, deltaSeconds)

    local nearbyPredator = record.Kind == "Prey" and self:FindNearestRecord(record, "Predator", self.FleeDistance) or nil
    if nearbyPredator then
        record.FleeFrom = nearbyPredator.Instance
        if record.Health <= (record.MaxHealth or 80) * 0.35 then
            if record.Instance then
                record.Instance:SetAttribute("Hidden", true)
                record.Instance:SetAttribute("LastAction", "Hide")
            end
            return self:Transition(record, "Hide")
        end
        local away = self:GetRecordPosition(record) - self:GetRecordPosition(nearbyPredator)
        if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
        self:MoveToward(record, self:GetRecordPosition(record) + away.Unit * self.MoveStep)
        return self:Transition(record, "Flee")
    end

    if (record.Thirst or 0) < 45 then
        local water, distance = self:FindNearestTagged(record, "WaterSource", self.SenseDistance)
        if water and distance <= self.InteractDistance then return self:Drink(record, water) end
        if water then
            self:MoveToward(record, self:GetInstancePosition(water))
            return self:Transition(record, "SeekWater")
        end
    end

    if (record.Hunger or 0) < 45 then
        local diet = record.Kind == "Predator" and "Carnivore" or "Herbivore"
        local food, distance = self:FindNearestTagged(record, "FoodSource", self.SenseDistance, function(candidate)
            return candidate:GetAttribute("Depleted") ~= true and candidate:GetAttribute("Diet") == diet
        end)
        if food and distance <= self.InteractDistance then return self:Eat(record, food) end
        if food then
            self:MoveToward(record, self:GetInstancePosition(food))
            return self:Transition(record, "SeekFood")
        end
    end

    if record.Kind == "Predator" then
        local prey, distance = self:FindNearestRecord(record, "Prey", self.SenseDistance)
        if prey and distance <= self.InteractDistance then return self:AttackRecord(record, prey) end
        if prey then
            self:MoveToward(record, self:GetRecordPosition(prey))
            return self:Transition(record, "Chase")
        end
    end

    local wanderTarget = record.SpawnPosition + Vector3.new(math.sin(os.clock()) * 18, 0, math.cos(os.clock()) * 18)
    self:MoveToward(record, wanderTarget, self.MoveStep * 0.5)
    return self:Transition(record, "Wander")
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
    return self:TickNPCs(players)
end

function NPCService:CanChaseIntoZone(zoneId, scriptedTutorialScare)
    if zoneId == "NurseryGrove" and not scriptedTutorialScare then return false end
    return true
end

function NPCService:MoveRecordToward(record, targetPosition, stepStuds, actionName)
    local npc = record and record.Instance
    if not npc or typeof(targetPosition) ~= "Vector3" then return false, "missing_target" end
    local position = self:GetRecordPosition(record)
    local offset = targetPosition - position
    if offset.Magnitude <= 0.05 then return false, "already_at_target" end
    local travel = math.min(stepStuds or self.BrainStepStuds, offset.Magnitude)
    local nextPosition = position + offset.Unit * travel
    local lookAt = Vector3.new(targetPosition.X, nextPosition.Y, targetPosition.Z)
    if (lookAt - nextPosition).Magnitude <= 0.05 then
        lookAt = nextPosition + Vector3.new(0, 0, -1)
    end
    if npc.PivotTo then
        npc:PivotTo(CFrame.lookAt(nextPosition, lookAt))
    elseif npc:IsA("BasePart") then
        npc.CFrame = CFrame.lookAt(nextPosition, lookAt)
    end
    record.LastMoveTarget = targetPosition
    record.LastBrainAction = actionName or "Move"
    if npc.SetAttribute then
        npc:SetAttribute("LastBrainAction", record.LastBrainAction)
        npc:SetAttribute("BrainTarget", string.format("%.1f,%.1f,%.1f", targetPosition.X, targetPosition.Y, targetPosition.Z))
        npc:SetAttribute("LastMoveTarget", string.format("%.1f,%.1f,%.1f", targetPosition.X, targetPosition.Y, targetPosition.Z))
        npc:SetAttribute("BrainMoveCount", (npc:GetAttribute("BrainMoveCount") or 0) + 1)
        npc:SetAttribute("LastBrainMovedAt", os.time())
    end
    return true
end

function NPCService:FindNearestPlayerRoot(record, players, maxDistance)
    local position = self:GetRecordPosition(record)
    local nearestRoot = nil
    local nearestDistance = maxDistance or math.huge
    for _, player in ipairs(players or {}) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local distance = (root.Position - position).Magnitude
            if distance <= nearestDistance then
                nearestRoot = root
                nearestDistance = distance
            end
        end
    end
    return nearestRoot, nearestDistance
end

function NPCService:Wander(record)
    record.BrainTick = (record.BrainTick or 0) + 1
    local angle = (record.BrainTick % 8) * (math.pi / 4)
    local radius = math.min(self.WanderRadius, 10 + (record.BrainTick % 4) * 4)
    local origin = record.SpawnPosition or self:GetRecordPosition(record)
    local target = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    self:Transition(record, "Wander")
    return self:MoveRecordToward(record, target, self.BrainStepStuds, "Wander")
end

function NPCService:RunPreyBrain(record, players)
    local root, distance = self:FindNearestPlayerRoot(record, players, self.FleeDistance)
    if root and distance then
        local position = self:GetRecordPosition(record)
        local away = position - root.Position
        if away.Magnitude <= 0.05 then away = Vector3.new(1, 0, 0) end
        local target = position + away.Unit * self.BrainStepStuds
        record.FleeFrom = root.Position
        record.LastFleeAt = os.time()
        self:Transition(record, "Flee")
        return self:MoveRecordToward(record, target, self.BrainStepStuds, "Flee")
    end
    return self:Wander(record)
end

function NPCService:RunPredatorBrain(record, players)
    local root, distance = self:FindNearestPlayerRoot(record, players, record.MaxChaseDistance or 120)
    if root and distance then
        record.ChaseTarget = root.Parent
        if distance <= self.AttackDistance then
            record.LastAttackAt = os.time()
            self:Transition(record, "Attack")
            if record.Instance and record.Instance.SetAttribute then
                record.Instance:SetAttribute("LastBrainAction", "Attack")
                record.Instance:SetAttribute("AttackRangeConfirmed", true)
            end
            return true
        end
        self:Transition(record, "Chase")
        return self:MoveRecordToward(record, root.Position, self.BrainStepStuds, "Chase")
    end
    return self:Wander(record)
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
    local active = 0
    for _, record in ipairs(self.NPCs) do
        local ok = self:TickBrain(record, players, self.TickSeconds)
        if record.Instance then
            record.Instance:SetAttribute("ActiveNPCBrain", true)
            record.Instance:SetAttribute("BrainState", record.State)
        end
        if ok then
            active = active + 1
        end
    end
    return active
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
