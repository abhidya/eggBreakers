local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local NPCService = { TickLoopStarted = false }
NPCService.MinActive = 12
NPCService.MaxActive = 30
NPCService.AllowedStates = { HatchAtNest=true, Idle=true, Wander=true, Herd=true, SeekFood=true, Eat=true, SeekWater=true, Drink=true, Hide=true, Flee=true, Chase=true, Attack=true, ApexEvent=true, Dead=true, Despawn=true }
NPCService.NPCs = {}
NPCService.FleeDistance = 80
NPCService.TickSeconds = 1
NPCService.SenseDistance = 90
NPCService.InteractDistance = 10
NPCService.MoveStep = 8
NPCService.HerdRadius = 65
NPCService.ApexThreatRadius = 140
NPCService.KindProfiles = {
    Prey = { Diet = "Herbivore", Health = 80, Damage = 12, Herding = true, SpeciesId = "gallimimus" },
    Predator = { Diet = "Carnivore", Health = 140, Damage = 45, SpeciesId = "carnotaurus" },
    Apex = { Diet = "Carnivore", Health = 260, Damage = 80, Apex = true, SpeciesId = "tyrannosaurus", ThreatRadius = 140 },
    Omnivore = { Diet = "Omnivore", Health = 95, Damage = 18, Herding = true, SpeciesId = "oviraptor" },
}

function NPCService:GetKindProfile(kind)
    local base = self.KindProfiles[kind] or self.KindProfiles.Prey
    local profile = {}
    for key, value in pairs(base) do profile[key] = value end
    local species = SpeciesConfig[profile.SpeciesId]
    if species and species.EcosystemProfile then
        profile.Apex = profile.Apex or species.EcosystemProfile.Apex == true
        profile.Herding = profile.Herding or species.EcosystemProfile.Herding == true
        profile.ThreatRadius = profile.ThreatRadius or species.EcosystemProfile.ThreatRadius
        profile.HerdRadius = profile.HerdRadius or species.EcosystemProfile.HerdRadius
    end
    return profile
end

function NPCService:GetRecordDiet(record)
    if record and record.Diet then return record.Diet end
    return self:GetKindProfile(record and record.Kind or "Prey").Diet
end

function NPCService:CanEatDiet(eaterDiet, foodDiet)
    return eaterDiet == "Omnivore" or foodDiet == "Omnivore" or eaterDiet == foodDiet
end

function NPCService:CanSpawn(positionOk, activeCount)
    activeCount = activeCount or #self.NPCs
    return positionOk == true and activeCount < self.MaxActive
end

function NPCService:Register(npc, kind)
    if #self.NPCs >= self.MaxActive then return false, "cap_reached" end
    local profile = self:GetKindProfile(kind)
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
        Health = profile.Health,
        MaxHealth = profile.Health,
        Damage = profile.Damage,
        Diet = profile.Diet,
        SpeciesId = profile.SpeciesId,
        Apex = profile.Apex == true,
        Herding = profile.Herding == true,
        ThreatRadius = profile.ThreatRadius or self.ApexThreatRadius,
        HerdRadius = profile.HerdRadius or self.HerdRadius,
    }
    if npc then
        npc:SetAttribute("ActiveNPCBrain", true)
        npc:SetAttribute("NPCKind", kind)
        npc:SetAttribute("Diet", record.Diet)
        npc:SetAttribute("SpeciesId", record.SpeciesId)
        npc:SetAttribute("ApexCategory", record.Apex)
        npc:SetAttribute("HerdingEnabled", record.Herding)
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
    record.LastBrainAction = nextState
    if record.Instance then
        record.Instance:SetAttribute("NPCState", nextState)
        record.Instance:SetAttribute("BrainState", nextState)
        record.Instance:SetAttribute("LastBrainAction", nextState)
    end
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

function NPCService:FormatVector3(position)
    return string.format("%.1f,%.1f,%.1f", position.X, position.Y, position.Z)
end

function NPCService:OrientToward(record, targetPosition, actionName)
    if not record or typeof(targetPosition) ~= "Vector3" then return false, "missing_target" end
    local npc = record.Instance
    if not npc then return false, "missing_npc" end
    local position = self:GetRecordPosition(record)
    local lookAt = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
    if (lookAt - position).Magnitude <= 0.05 then
        lookAt = position + Vector3.new(0, 0, -1)
    end
    if npc.PivotTo then
        npc:PivotTo(CFrame.lookAt(position, lookAt))
    elseif npc:IsA("BasePart") then
        npc.CFrame = CFrame.lookAt(position, lookAt)
    end
    record.LastBrainAction = actionName or record.LastBrainAction or "FaceTarget"
    record.ActionTarget = targetPosition
    npc:SetAttribute("LastBrainAction", record.LastBrainAction)
    npc:SetAttribute("BrainActionTarget", self:FormatVector3(targetPosition))
    npc:SetAttribute("FacingTarget", self:FormatVector3(targetPosition))
    return true
end

function NPCService:MoveToward(record, targetPosition, step, actionName, targetInstance)
    if not record or typeof(targetPosition) ~= "Vector3" then return false, "missing_target" end
    local npc = record.Instance
    local position = self:GetRecordPosition(record)
    local delta = targetPosition - position
    if delta.Magnitude <= 0.1 then
        return self:OrientToward(record, targetPosition, actionName or "Move")
    end
    local nextPosition = position + delta.Unit * math.min(step or self.MoveStep, delta.Magnitude)
    local lookAt = Vector3.new(targetPosition.X, nextPosition.Y, targetPosition.Z)
    if (lookAt - nextPosition).Magnitude <= 0.05 then
        lookAt = nextPosition + Vector3.new(0, 0, -1)
    end
    local brainAction = actionName or "Move"
    record.MoveTarget = targetPosition
    record.ActionTarget = targetPosition
    record.LastMoveAt = os.time()
    record.LastBrainAction = brainAction
    if npc then
        local formattedTarget = self:FormatVector3(targetPosition)
        npc:SetAttribute("MoveTargetX", targetPosition.X)
        npc:SetAttribute("MoveTargetY", targetPosition.Y)
        npc:SetAttribute("MoveTargetZ", targetPosition.Z)
        npc:SetAttribute("LastMoveTarget", formattedTarget)
        npc:SetAttribute("BrainTarget", formattedTarget)
        npc:SetAttribute("BrainActionTarget", formattedTarget)
        npc:SetAttribute("BrainMoveCount", (npc:GetAttribute("BrainMoveCount") or 0) + 1)
        npc:SetAttribute("LastBrainAction", brainAction)
        npc:SetAttribute("LastAction", brainAction)
        npc:SetAttribute("ActiveNPCBrain", true)
        if targetInstance then
            npc:SetAttribute("BrainTargetName", targetInstance.Name)
        end
        if npc.PivotTo then
            npc:PivotTo(CFrame.lookAt(nextPosition, lookAt))
        elseif npc:IsA("BasePart") then
            npc.CFrame = CFrame.lookAt(nextPosition, lookAt)
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
    local foodPosition = self:GetInstancePosition(food)
    if foodPosition then
        self:OrientToward(record, foodPosition, "Eat")
    end
    record.Hunger = math.min(100, (record.Hunger or 0) + (food and food:GetAttribute("Nutrition") or 25))
    local position = self:GetRecordPosition(record)
    local expectedDiet = self:GetRecordDiet(record)
    local depletedCount = 0
    local function deplete(target)
        if target and self:CanEatDiet(expectedDiet, target:GetAttribute("Diet")) and target:GetAttribute("Depleted") ~= true then
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
    local waterPosition = self:GetInstancePosition(water)
    if waterPosition then
        self:OrientToward(record, waterPosition, "Drink")
    end
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
    self:OrientToward(attacker, self:GetRecordPosition(target), "Attack")
    attacker.AttackTarget = target.Instance
    attacker.LastAttackAt = os.time()
    if attacker.Instance then
        attacker.Instance:SetAttribute("LastAction", "Attack")
        attacker.Instance:SetAttribute("AttackTarget", target.Instance and target.Instance.Name or "NPC")
    end
    self:Transition(attacker, "Attack")
    return self:DamageRecord(target, attacker.Damage or self:GetKindProfile(attacker.Kind).Damage or 12)
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

function NPCService:FindNearestThreat(record, maxDistance)
    local best, bestDistance = nil, maxDistance or self.FleeDistance
    local position = self:GetRecordPosition(record)
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and (candidate.Kind == "Predator" or candidate.Apex == true) then
            local distance = (self:GetRecordPosition(candidate) - position).Magnitude
            if distance <= bestDistance then
                best, bestDistance = candidate, distance
            end
        end
    end
    return best, bestDistance
end

function NPCService:FindHerdCenter(record)
    if not record or record.Herding ~= true then return nil, 0 end
    local position = self:GetRecordPosition(record)
    local radius = record.HerdRadius or self.HerdRadius
    local total = position
    local count = 1
    local leaderName = record.Instance and record.Instance.Name or "NPC"
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and candidate.Herding == true and self:GetRecordDiet(candidate) == self:GetRecordDiet(record) then
            local candidatePosition = self:GetRecordPosition(candidate)
            if (candidatePosition - position).Magnitude <= radius then
                total = total + candidatePosition
                count = count + 1
                if candidate.Instance and tostring(candidate.Instance.Name) < leaderName then
                    leaderName = candidate.Instance.Name
                end
            end
        end
    end
    return total / count, count, leaderName
end

function NPCService:ApplyHerding(record)
    local center, count, leaderName = self:FindHerdCenter(record)
    if not center or count < 2 then
        if record.Instance then record.Instance:SetAttribute("HerdSize", count or 1) end
        return false, "no_herd"
    end
    record.HerdCenter = center
    record.HerdSize = count
    if record.Instance then
        record.Instance:SetAttribute("HerdSize", count)
        record.Instance:SetAttribute("HerdLeader", leaderName)
        record.Instance:SetAttribute("HerdCenter", string.format("%.1f,%.1f,%.1f", center.X, center.Y, center.Z))
    end
    local distance = (center - self:GetRecordPosition(record)).Magnitude
    if distance > self.InteractDistance then
        self:MoveToward(record, center, self.MoveStep * 0.75)
    end
    return self:Transition(record, "Herd")
end

function NPCService:StampApexEvent(record)
    if not record or record.Apex ~= true then return false, "not_apex" end
    local affected = 0
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and candidate.Apex ~= true then
            local distance = (self:GetRecordPosition(candidate) - self:GetRecordPosition(record)).Magnitude
            if distance <= (record.ThreatRadius or self.ApexThreatRadius) then
                affected = affected + 1
                candidate.LastApexThreat = record.Instance
                if candidate.Instance then
                    candidate.Instance:SetAttribute("LastApexThreat", record.Instance and record.Instance.Name or "Apex")
                end
            end
        end
    end
    record.LastApexEventAt = os.time()
    if record.Instance then
        record.Instance:SetAttribute("ApexEventActive", true)
        record.Instance:SetAttribute("ApexEventAffected", affected)
        record.Instance:SetAttribute("ApexThreatRadius", record.ThreatRadius or self.ApexThreatRadius)
        record.Instance:SetAttribute("LastBrainAction", "ApexEvent")
    end
    return self:Transition(record, "ApexEvent")
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

    if record.Kind == "Prey" then
        local playerRoot = self.FindNearestPlayerRoot and self:FindNearestPlayerRoot(record, players, self.FleeDistance)
        if playerRoot then
            local away = self:GetRecordPosition(record) - playerRoot.Position
            if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
            self:MoveToward(record, self:GetRecordPosition(record) + away.Unit * self.MoveStep, self.MoveStep, "Flee")
            record.FleeFrom = playerRoot.Position
            record.LastFleeAt = os.time()
            return self:Transition(record, "Flee")
        end
    end

    if record.Apex == true then
        local apexEventOk = self:StampApexEvent(record)
        if apexEventOk then return true end
    end

    local nearbyPredator = (record.Kind == "Prey" or record.Kind == "Omnivore") and self:FindNearestThreat(record, self.FleeDistance) or nil
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
        self:MoveToward(record, self:GetRecordPosition(record) + away.Unit * self.MoveStep, self.MoveStep, "Flee")
        return self:Transition(record, "Flee")
    end

    if (record.Thirst or 0) < 45 then
        local water, distance = self:FindNearestTagged(record, "WaterSource", self.SenseDistance)
        if water and distance <= self.InteractDistance then return self:Drink(record, water) end
        if water then
            self:MoveToward(record, self:GetInstancePosition(water), self.MoveStep, "SeekWater", water)
            return self:Transition(record, "SeekWater")
        end
    end

    if (record.Hunger or 0) < 45 then
        local diet = self:GetRecordDiet(record)
        local food, distance = self:FindNearestTagged(record, "FoodSource", self.SenseDistance, function(candidate)
            return candidate:GetAttribute("Depleted") ~= true and self:CanEatDiet(diet, candidate:GetAttribute("Diet"))
        end)
        if food and distance <= self.InteractDistance then return self:Eat(record, food) end
        if food then
            record.FoodTarget = food
            if record.Instance then
                record.Instance:SetAttribute("FoodTarget", food.Name)
                record.Instance:SetAttribute("FoodTargetDiet", diet)
            end
            self:MoveToward(record, self:GetInstancePosition(food), self.MoveStep, "SeekFood", food)
            return self:Transition(record, "SeekFood")
        end
    end

    if record.Kind == "Predator" or record.Apex == true then
        local prey, distance = self:FindNearestRecord(record, "Prey", self.SenseDistance)
        if prey and distance <= self.InteractDistance then return self:AttackRecord(record, prey) end
        if prey then
            self:MoveToward(record, self:GetRecordPosition(prey), self.MoveStep, "Chase", prey.Instance)
            return self:Transition(record, "Chase")
        end
    end

    if record.Herding == true then
        local herdOk = self:ApplyHerding(record)
        if herdOk then return true end
    end

    local wanderTarget = record.SpawnPosition + Vector3.new(math.sin(os.clock()) * 18, 0, math.cos(os.clock()) * 18)
    self:MoveToward(record, wanderTarget, self.MoveStep * 0.5, "Wander")
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
