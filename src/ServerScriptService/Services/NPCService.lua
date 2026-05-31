local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local FoodWaterService = require(script.Parent.FoodWaterService)

local NPCService = { TickLoopStarted = false }
NPCService.MinActive = 12
NPCService.MaxActive = 30
NPCService.AllowedStates = { HatchAtNest=true, Idle=true, Wander=true, Herd=true, Pack=true, Mate=true, SeekFood=true, Eat=true, SeekWater=true, Drink=true, Hide=true, Flee=true, Chase=true, Attack=true, ApexEvent=true, Dead=true, Despawn=true }
NPCService.NPCs = {}
NPCService.FleeDistance = 80
NPCService.TickSeconds = 1
NPCService.SenseDistance = 90
NPCService.InteractDistance = 10
NPCService.MoveStep = 8
NPCService.BrainStepStuds = 8
NPCService.AttackDistance = 10
NPCService.WanderRadius = 28
NPCService.HerdRadius = 65
NPCService.ApexEventCooldownSeconds = 12
NPCService.StuckDistanceEpsilon = 0.35
NPCService.StuckRecoveryTicks = 2
NPCService.StuckRecoveryNudgeStuds = 6
NPCService.MaxBrainTicksPerCycle = 30
NPCService.BrainRoundRobinIndex = 1
NPCService.PackRadius = 75
NPCService.MateRadius = 34
NPCService.MateCooldownSeconds = 90
-- DYING PIPELINE tunables (additive; safe when world absent).
NPCService.DeathSettleSeconds = 1.5        -- brief "settle/ragdoll" beat before the body reads as a carcass
NPCService.CarcassDespawnSeconds = 45      -- how long the carcass food source lingers before cleanup
NPCService.ApexThreatRadius = 140
NPCService.KindProfiles = {
    Prey = { Diet = "Herbivore", Health = 80, Damage = 12, Herding = true, SpeciesId = "parasaurolophus" },
    AerialPrey = { Diet = "Carnivore", Health = 45, Damage = 6, Herding = true, SpeciesId = "quetzalcoatlus", FlightCapable = true, PreferredAltitude = 32, AerialPrey = true },
    Predator = { Diet = "Carnivore", Health = 140, Damage = 45, SpeciesId = "utahraptor", PackHunter = true },
    AerialPredator = { Diet = "Carnivore", Health = 115, Damage = 35, SpeciesId = "pteranodon", FlightCapable = true, PreferredAltitude = 38, HuntsAerialPrey = true, PackHunter = true },
    Apex = { Diet = "Carnivore", Health = 260, Damage = 80, Apex = true, SpeciesId = "tyrannosaurus", ThreatRadius = 140 },
    Omnivore = { Diet = "Omnivore", Health = 95, Damage = 18, Herding = true, SpeciesId = "oviraptor" },
    SemiAquatic = { Diet = "Carnivore", Health = 220, Damage = 60, SpeciesId = "spinosaurus" },
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
        profile.FlightCapable = profile.FlightCapable or (species.MovementModes and species.MovementModes.Flight == true)
        profile.HuntsAerialPrey = profile.HuntsAerialPrey or species.EcosystemProfile.HuntsAerialPrey == true
        profile.PreferredAltitude = profile.PreferredAltitude or species.EcosystemProfile.PreferredAltitude
    end
    return profile
end

function NPCService:IsPreyKind(kind)
    return kind == "Prey" or kind == "AerialPrey" or kind == "FlyingPrey"
end

function NPCService:GetCarnivoreFoodKind(kind)
    if kind == "AerialPrey" or kind == "FlyingPrey" then return "AerialPreyCarcass" end
    if kind == "Predator" or kind == "AerialPredator" then return "PredatorCarcass" end
    if kind == "Apex" then return "LargeCarcass" end
    return "PreyCarcass"
end

function NPCService:IsCarnivoreFoodCandidate(record)
    return record ~= nil and self:IsPreyKind(record.Kind) and record.State ~= "Dead"
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
        FlightCapable = profile.FlightCapable == true,
        PreferredAltitude = profile.PreferredAltitude or pivotPosition.Y,
        HuntsAerialPrey = profile.HuntsAerialPrey == true,
        AerialPrey = profile.AerialPrey == true or kind == "AerialPrey" or kind == "FlyingPrey",
        PackHunter = profile.PackHunter == true,
        MateEligible = true,
        LastMateAt = 0,
    }
    record.PotentialCarnivoreFood = self:IsPreyKind(kind)
    if npc then
        npc:SetAttribute("ActiveNPCBrain", true)
        npc:SetAttribute("NPCKind", kind)
        npc:SetAttribute("Diet", record.Diet)
        npc:SetAttribute("SpeciesId", record.SpeciesId)
        npc:SetAttribute("ApexCategory", record.Apex)
        npc:SetAttribute("ApexEventEligible", record.Apex)
        npc:SetAttribute("ApexThreatRadius", record.ThreatRadius)
        npc:SetAttribute("ApexEventCooldownSeconds", self.ApexEventCooldownSeconds)
        npc:SetAttribute("ApexEventState", record.Apex and "Ready" or "Ineligible")
        npc:SetAttribute("ApexEventActive", false)
        npc:SetAttribute("HerdingEnabled", record.Herding)
        npc:SetAttribute("PackHunter", record.PackHunter)
        npc:SetAttribute("MateEligible", record.MateEligible)
        npc:SetAttribute("HerdCoordinatedMotion", false)
        npc:SetAttribute("FlightCapable", record.FlightCapable)
        npc:SetAttribute("Flying", record.FlightCapable)
        npc:SetAttribute("AerialPrey", record.AerialPrey)
        npc:SetAttribute("PreferredAltitude", record.PreferredAltitude)
        npc:SetAttribute("PotentialCarnivoreFood", record.PotentialCarnivoreFood == true)
        npc:SetAttribute("CarnivoreFoodCandidate", record.PotentialCarnivoreFood == true)
        npc:SetAttribute("FoodWhenDefeated", true)
        npc:SetAttribute("CarnivoreFoodKind", self:GetCarnivoreFoodKind(kind))
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
        if not CollectionService:HasTag(npc, "Damageable") then
            CollectionService:AddTag(npc, "Damageable")
        end
        if record.PotentialCarnivoreFood == true and not CollectionService:HasTag(npc, "CarnivoreFoodCandidate") then
            CollectionService:AddTag(npc, "CarnivoreFoodCandidate")
        end
    end
    table.insert(self.NPCs, record)
    return true, record
end

-- DYING PIPELINE: play a brief death state on the NPC body and let it settle.
-- "Ragdoll-ish": disable the Humanoid (no MoveTo fights), unanchor the root so the body
-- drops/settles under physics if it was anchored, and stamp readable death attributes.
-- Fully guarded: a no-op when there is no Instance (headless tests stay green).
function NPCService:PlayDeathSettle(record)
    if not record then return false, "missing_record" end
    local npc = record.Instance
    if not npc then return false, "missing_npc" end
    record.DiedAt = os.time()
    if npc.SetAttribute then
        npc:SetAttribute("Dead", true)
        npc:SetAttribute("DeathState", "Settling")
        npc:SetAttribute("DiedAt", record.DiedAt)
        npc:SetAttribute("ActiveNPCBrain", false)
    end
    -- Stop the brain from issuing further moves toward this body.
    record.MoveTarget = nil
    local humanoid = npc.FindFirstChildWhichIsA and npc:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        -- Settle in place: cancel any in-flight MoveTo and let physics take over.
        if humanoid.Move then humanoid:Move(Vector3.new(0, 0, 0), false) end
        pcall(function()
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
            humanoid.WalkSpeed = 0
        end)
    end
    -- Unanchor parts so the body ragdoll-settles instead of standing frozen.
    if npc.GetDescendants then
        for _, descendant in ipairs(npc:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = false
                descendant.CanCollide = true
            end
        end
    elseif npc:IsA("BasePart") then
        npc.Anchored = false
    end
    return true
end

-- DYING PIPELINE: tear down the dead NPC body and despawn the carcass food source after a
-- timeout, so downed prey reads as a carcass (StoryModeStoryboard 'dying' beat: "downed prey
-- becomes carcass food, not a disappearing model") and then cleans up. Deferred + guarded:
-- tolerates an already-destroyed/parentless instance (tests Destroy carcasses immediately).
function NPCService:ScheduleCarcassDespawn(record, carcass, despawnSeconds)
    if not record then return false, "missing_record" end
    local delay = despawnSeconds or self.CarcassDespawnSeconds
    -- Retire the original NPC body shortly after the settle beat: it is now represented by
    -- the carcass food source, so remove the live model to avoid a duplicate visual.
    local npc = record.Instance
    if typeof(task) == "table" and type(task.delay) == "function" then
        if npc then
            task.delay(self.DeathSettleSeconds, function()
                if npc and npc.Parent then
                    if npc.SetAttribute then npc:SetAttribute("DeathState", "Despawned") end
                    npc:Destroy()
                end
            end)
        end
        if carcass then
            task.delay(delay, function()
                if carcass and carcass.Parent then
                    carcass:Destroy()
                end
                record.Carcass = nil
            end)
        end
    end
    if record.Instance and record.Instance.SetAttribute then
        record.Instance:SetAttribute("CarcassDespawnSeconds", delay)
    end
    if carcass and carcass.SetAttribute then
        carcass:SetAttribute("DespawnAfterSeconds", delay)
    end
    return true
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
    if nextState == "Dead" then
        if record.Instance then
            record.Instance:SetAttribute("CarnivoreFoodCandidate", false)
            record.Instance:SetAttribute("PotentialCarnivoreFood", false)
            record.Instance:SetAttribute("FoodWhenDefeated", true)
            record.Instance:SetAttribute("CarnivoreFoodKind", self:GetCarnivoreFoodKind(record.Kind))
            if CollectionService:HasTag(record.Instance, "CarnivoreFoodCandidate") then
                CollectionService:RemoveTag(record.Instance, "CarnivoreFoodCandidate")
            end
        end
        -- DYING PIPELINE: settle the body (death state), then convert to a readable carcass
        -- food source (synchronous so Dead-state assertions still find record.Carcass), and
        -- finally schedule a despawn timeout. All steps are additive + world-absent safe.
        self:PlayDeathSettle(record)
        record.Carcass = self:CreateCarcassFoodSource(record)
        self:ScheduleCarcassDespawn(record, record.Carcass)
    end
    return true
end


function NPCService:FindRecordForInstance(instance)
    if not instance then return nil end
    for _, record in ipairs(self.NPCs) do
        if record.Instance == instance then
            return record
        end
    end
    return nil
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

function NPCService:PruneStaleRecords()
    local pruned = 0
    for index = #self.NPCs, 1, -1 do
        local record = self.NPCs[index]
        local instance = record and record.Instance
        if not instance or instance.Parent == nil then
            table.remove(self.NPCs, index)
            pruned = pruned + 1
        end
    end
    return pruned
end

function NPCService:FormatVector3(position)
    return string.format("%.1f,%.1f,%.1f", position.X, position.Y, position.Z)
end

function NPCService:ResolveLocomotionRoot(npc)
    if not npc then return nil, "MissingNPC" end
    if npc:IsA("BasePart") then
        return npc, "KinematicPartStep"
    end
    local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
    local humanoidRoot = npc:FindFirstChild("HumanoidRootPart", true)
    if humanoid and humanoidRoot and humanoidRoot:IsA("BasePart") then
        return humanoidRoot, "HumanoidMoveTo"
    end
    local stagedRoot = npc:FindFirstChild("RootPart", true)
    if stagedRoot and stagedRoot:IsA("BasePart") then
        return stagedRoot, "KinematicRootStep"
    end
    if npc.PrimaryPart then
        return npc.PrimaryPart, "KinematicPrimaryPartStep"
    end
    return nil, "KinematicPivotStep"
end

function NPCService:StampLocomotion(record, mode)
    record.LastLocomotionMode = mode
    local npc = record.Instance
    if npc and npc.SetAttribute then
        npc:SetAttribute("LocomotionMode", mode)
        npc:SetAttribute("LastLocomotionMode", mode)
    end
end

function NPCService:GetMovementModes(record)
    local species = SpeciesConfig[record and record.SpeciesId or ""]
    return species and species.MovementModes or { Ground = true, Swim = false, Flight = false }
end

function NPCService:GetMovementSurface(record, actionName, targetInstance)
    if record and record.FlightCapable == true then
        return "Flight"
    end
    local modes = self:GetMovementModes(record)
    if modes.Swim == true then
        if record and record.Kind == "SemiAquatic" then
            return "Swim"
        end
        if targetInstance and targetInstance.GetAttribute and (targetInstance:GetAttribute("WaterSource") == true or CollectionService:HasTag(targetInstance, "WaterSource")) then
            return "Swim"
        end
        if actionName == "SeekWater" or actionName == "Drink" then
            return "Swim"
        end
    end
    return "Ground"
end

function NPCService:StampMovementState(record, surface, actionName, targetPosition, clamped)
    record.MovementSurface = surface
    record.MovementState = surface .. ":" .. tostring(actionName or "Move")
    local npc = record.Instance
    if npc and npc.SetAttribute then
        npc:SetAttribute("MovementSurface", surface)
        npc:SetAttribute("MovementState", record.MovementState)
        npc:SetAttribute("GroundClampApplied", clamped == true)
        if typeof(targetPosition) == "Vector3" then
            npc:SetAttribute("ResolvedMoveTarget", self:FormatVector3(targetPosition))
        end
    end
end

function NPCService:ResolveMovementTarget(record, targetPosition, actionName, targetInstance)
    if typeof(targetPosition) ~= "Vector3" then return targetPosition, "Ground", false end
    local surface = self:GetMovementSurface(record, actionName, targetInstance)
    if surface == "Flight" then
        return self:GetFlightTarget(record, targetPosition, actionName), surface, false
    end
    local current = self:GetRecordPosition(record)
    if surface == "Ground" then
        return Vector3.new(targetPosition.X, current.Y, targetPosition.Z), surface, math.abs(targetPosition.Y - current.Y) > 0.1
    end
    return targetPosition, surface, false
end

function NPCService:ApplyStuckRecovery(record, targetPosition, actionName)
    local position = self:GetRecordPosition(record)
    local lastPosition = record.LastMovementPosition
    local distanceToTarget = (targetPosition - position).Magnitude
    if lastPosition and distanceToTarget > self.InteractDistance then
        local progress = (position - lastPosition).Magnitude
        if progress <= self.StuckDistanceEpsilon then
            record.StuckTicks = (record.StuckTicks or 0) + 1
        else
            record.StuckTicks = 0
        end
    else
        record.StuckTicks = 0
    end
    record.LastMovementPosition = position
    if (record.StuckTicks or 0) < self.StuckRecoveryTicks then
        return targetPosition, false
    end
    local toTarget = targetPosition - position
    local lateral = Vector3.new(-toTarget.Z, 0, toTarget.X)
    if lateral.Magnitude <= 0.05 then lateral = Vector3.new(1, 0, 0) end
    local recovered = targetPosition + lateral.Unit * self.StuckRecoveryNudgeStuds
    record.StuckRecoveries = (record.StuckRecoveries or 0) + 1
    if record.Instance and record.Instance.SetAttribute then
        record.Instance:SetAttribute("MovementStuckTicks", record.StuckTicks)
        record.Instance:SetAttribute("MovementRecoveryCount", record.StuckRecoveries)
        record.Instance:SetAttribute("MovementState", "Recovering:" .. tostring(actionName or "Move"))
        record.Instance:SetAttribute("StuckRecoveryTarget", self:FormatVector3(recovered))
    end
    record.StuckTicks = 0
    return recovered, true
end

function NPCService:ConfigureHumanoidMovement(record, humanoid, actionName)
    if not humanoid then return end
    local species = SpeciesConfig[record and record.SpeciesId or ""]
    local stage = (record and record.GrowthStage) or "Adult"
    local stats = species and species.BaseStats and (species.BaseStats[stage] or species.BaseStats.Adult or species.BaseStats.Hatchling)
    local walkSpeed = stats and stats.WalkSpeed or humanoid.WalkSpeed
    local sprintSpeed = stats and stats.SprintSpeed or math.max(walkSpeed, humanoid.WalkSpeed)
    if actionName == "Chase" or actionName == "Flee" then
        humanoid.WalkSpeed = sprintSpeed
    else
        humanoid.WalkSpeed = walkSpeed
    end
    humanoid.AutoRotate = true
    if record and record.Instance and record.Instance.SetAttribute then
        record.Instance:SetAttribute("DesiredWalkSpeed", humanoid.WalkSpeed)
    end
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

function NPCService:GetFlightTarget(record, targetPosition, actionName)
    if not record or record.FlightCapable ~= true or typeof(targetPosition) ~= "Vector3" then
        return targetPosition
    end
    local preferredAltitude = record.PreferredAltitude or targetPosition.Y
    local y = math.max(preferredAltitude, targetPosition.Y)
    if actionName == "Flee" then
        y = math.max(y, self:GetRecordPosition(record).Y + 8)
    end
    return Vector3.new(targetPosition.X, y, targetPosition.Z)
end

function NPCService:MoveToward(record, targetPosition, step, actionName, targetInstance)
    if not record or typeof(targetPosition) ~= "Vector3" then return false, "missing_target" end
    local npc = record.Instance
    local surface, clamped
    targetPosition, surface, clamped = self:ResolveMovementTarget(record, targetPosition, actionName, targetInstance)
    local recovered
    targetPosition, recovered = self:ApplyStuckRecovery(record, targetPosition, actionName)
    if recovered then
        surface = surface or self:GetMovementSurface(record, actionName, targetInstance)
    end
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
        self:StampMovementState(record, surface or "Ground", brainAction, targetPosition, clamped)
        if recovered then
            record.MovementState = "Recovering:" .. brainAction
            npc:SetAttribute("MovementState", record.MovementState)
            npc:SetAttribute("StuckRecoveryActive", true)
        else
            npc:SetAttribute("StuckRecoveryActive", false)
        end
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
        npc:SetAttribute("Flying", record.FlightCapable == true)
        npc:SetAttribute("FlightTarget", record.FlightCapable == true and formattedTarget or nil)
        if targetInstance then
            npc:SetAttribute("BrainTargetName", targetInstance.Name)
        end
        local root, mode = self:ResolveLocomotionRoot(npc)
        local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
        self:StampLocomotion(record, mode)
        if humanoid and root and mode == "HumanoidMoveTo" then
            -- Physics-driven locomotion via Humanoid:MoveTo; unanchors root part for smooth motion.
            if root.Anchored then root.Anchored = false end
            self:ConfigureHumanoidMovement(record, humanoid, brainAction)
            humanoid:MoveTo(targetPosition)
            -- Orient model toward target (non-teleporting; Humanoid handles position)
            local lookCF = CFrame.lookAt(root.Position, lookAt)
            root.CFrame = lookCF
        elseif npc.PivotTo then
            -- Humanoid-less staged rigs step only by the bounded nextPosition, never to the full target.
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
    if food then
        FoodWaterService:NormaliseFoliageMetadata(food)
    end
    local nutrition = food and food:GetAttribute("Nutrition") or 25
    record.Hunger = math.min(100, (record.Hunger or 0) + nutrition)
    local position = self:GetRecordPosition(record)
    local expectedDiet = self:GetRecordDiet(record)
    local depletedCount = 0
    local function deplete(target)
        if target and self:CanEatDiet(expectedDiet, target:GetAttribute("Diet")) and target:GetAttribute("Depleted") ~= true then
            local context = FoodWaterService:BuildEatContext(target, record.Instance and record.Instance.Name or "NPC", expectedDiet, target:GetAttribute("Nutrition") or nutrition)
            FoodWaterService:MarkFoodEaten(target, context)
            target:SetAttribute("LastEatenByNPC", context.EaterName)
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
        record.Instance:SetAttribute("EatingState", FoodWaterService:GetEatVerb(food, expectedDiet))
        record.Instance:SetAttribute("EatTarget", food and food.Name or "")
        record.Instance:SetAttribute("EatTargetKind", food and (food:GetAttribute("FoodKind") or food:GetAttribute("Diet")) or "")
        record.Instance:SetAttribute("EatNutrition", nutrition)
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

function NPCService:FindNearestHuntTarget(record, maxDistance)
    local position = self:GetRecordPosition(record)
    local best, bestDistance = nil, maxDistance or self.SenseDistance
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and self:IsPreyKind(candidate.Kind) then
            local canHunt = candidate.Kind == "Prey" or record.FlightCapable == true or record.HuntsAerialPrey == true
            if canHunt then
                local distance = (self:GetRecordPosition(candidate) - position).Magnitude
                if distance <= bestDistance then
                    best, bestDistance = candidate, distance
                end
            end
        end
    end
    return best, bestDistance
end

function NPCService:FindNearestThreat(record, maxDistance)
    local best, bestDistance = nil, maxDistance or self.FleeDistance
    local position = self:GetRecordPosition(record)
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and (candidate.Kind == "Predator" or candidate.Kind == "AerialPredator" or candidate.Apex == true) then
            local distance = (self:GetRecordPosition(candidate) - position).Magnitude
            if distance <= bestDistance then
                best, bestDistance = candidate, distance
            end
        end
    end
    return best, bestDistance
end

function NPCService:FindNearestSocialMate(record, maxDistance)
    if not record or record.MateEligible ~= true or record.State == "Dead" then return nil, nil end
    local position = self:GetRecordPosition(record)
    local best, bestDistance = nil, maxDistance or self.MateRadius
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and candidate.MateEligible == true and candidate.SpeciesId == record.SpeciesId then
            local distance = (self:GetRecordPosition(candidate) - position).Magnitude
            if distance <= bestDistance then
                best, bestDistance = candidate, distance
            end
        end
    end
    return best, bestDistance
end

function NPCService:TryMate(record)
    local now = os.time()
    if not record or record.MateEligible ~= true or (record.Health or 0) <= 0 then return false, "not_eligible" end
    if (record.Hunger or 0) < 65 or (record.Thirst or 0) < 65 then return false, "needs_low" end
    if record.LastMateAt and now - record.LastMateAt < self.MateCooldownSeconds then return false, "cooldown" end
    local mate, distance = self:FindNearestSocialMate(record, self.MateRadius)
    if not mate then return false, "missing_mate" end

    record.MateTarget = mate.Instance
    record.LastMateAt = now
    mate.LastMateAt = mate.LastMateAt or now
    if record.Instance then
        record.Instance:SetAttribute("MateTarget", mate.Instance and mate.Instance.Name or "")
        record.Instance:SetAttribute("MateDistance", distance)
        record.Instance:SetAttribute("MateCooldownSeconds", self.MateCooldownSeconds)
        record.Instance:SetAttribute("LastBrainAction", "Mate")
    end
    self:OrientToward(record, self:GetRecordPosition(mate), "Mate")
    return self:Transition(record, "Mate")
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

function NPCService:ApplyPackBehavior(record)
    if not record or record.PackHunter ~= true then return false, "not_pack_hunter" end
    local position = self:GetRecordPosition(record)
    local radius = record.PackRadius or self.PackRadius
    local total = position
    local count = 1
    local leaderName = record.Instance and record.Instance.Name or "NPC"
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and candidate.PackHunter == true and candidate.SpeciesId == record.SpeciesId then
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
    if count < 2 then
        if record.Instance then
            record.Instance:SetAttribute("PackSize", 1)
            record.Instance:SetAttribute("PackEventState", "Solo")
        end
        return false, "solo"
    end

    local center = total / count
    local target = center
    if record.Instance then
        record.Instance:SetAttribute("PackSize", count)
        record.Instance:SetAttribute("PackLeader", leaderName)
        record.Instance:SetAttribute("PackGroupId", "Pack:" .. leaderName)
        record.Instance:SetAttribute("PackCenterX", center.X)
        record.Instance:SetAttribute("PackCenterY", center.Y)
        record.Instance:SetAttribute("PackCenterZ", center.Z)
        record.Instance:SetAttribute("PackEventState", "Regrouping")
    end
    self:MoveToward(record, target, self.MoveStep * 0.75, "Pack")
    return self:Transition(record, "Pack")
end

function NPCService:ApplyHerding(record)
    local center, count, leaderName = self:FindHerdCenter(record)
    if not center or count < 2 then
        if record.Instance then
            record.Instance:SetAttribute("HerdSize", count or 1)
            record.Instance:SetAttribute("HerdCoordinatedMotion", false)
            record.Instance:SetAttribute("HerdEventState", "Solo")
        end
        return false, "no_herd"
    end
    local position = self:GetRecordPosition(record)
    local toCenter = center - position
    local distance = toCenter.Magnitude
    local motion = distance > 0.05 and toCenter.Unit or Vector3.new(0, 0, 0)
    local herdTarget = distance > self.InteractDistance and center or position
    local groupId = "Herd:" .. tostring(leaderName)
    record.HerdCenter = center
    record.HerdSize = count
    record.HerdLeader = leaderName
    record.HerdGroupId = groupId
    record.HerdMotion = motion
    record.HerdTarget = herdTarget
    record.HerdCohesionDistance = distance
    if record.Instance then
        record.Instance:SetAttribute("HerdSize", count)
        record.Instance:SetAttribute("HerdLeader", leaderName)
        record.Instance:SetAttribute("HerdGroupId", groupId)
        record.Instance:SetAttribute("HerdCenter", self:FormatVector3(center))
        record.Instance:SetAttribute("HerdCenterX", center.X)
        record.Instance:SetAttribute("HerdCenterY", center.Y)
        record.Instance:SetAttribute("HerdCenterZ", center.Z)
        record.Instance:SetAttribute("HerdMotionX", motion.X)
        record.Instance:SetAttribute("HerdMotionY", motion.Y)
        record.Instance:SetAttribute("HerdMotionZ", motion.Z)
        record.Instance:SetAttribute("HerdTarget", self:FormatVector3(herdTarget))
        record.Instance:SetAttribute("HerdTargetX", herdTarget.X)
        record.Instance:SetAttribute("HerdTargetY", herdTarget.Y)
        record.Instance:SetAttribute("HerdTargetZ", herdTarget.Z)
        record.Instance:SetAttribute("HerdCohesionDistance", distance)
        record.Instance:SetAttribute("HerdCoordinatedMotion", true)
        record.Instance:SetAttribute("HerdEventState", distance > self.InteractDistance and "Regrouping" or "Cohesive")
    end
    if distance > self.InteractDistance then
        self:MoveToward(record, center, self.MoveStep * 0.75, "Herd")
    end
    return self:Transition(record, "Herd")
end

function NPCService:GetApexEventNow()
    return os.clock()
end

function NPCService:CanTriggerApexEvent(record, now)
    if not record or record.Apex ~= true then return false, "not_apex" end
    now = now or self:GetApexEventNow()
    local cooldown = record.ApexEventCooldownSeconds or self.ApexEventCooldownSeconds
    local last = record.LastApexEventAt
    if last and (now - last) < cooldown then
        return false, "cooldown", cooldown - (now - last)
    end
    return true, "ready", 0
end

function NPCService:StampApexEvent(record, now)
    if not record or record.Apex ~= true then return false, "not_apex" end
    now = now or self:GetApexEventNow()
    local canTrigger, gateReason, remaining = self:CanTriggerApexEvent(record, now)
    if not canTrigger then
        if record.Instance then
            record.Instance:SetAttribute("ApexEventActive", false)
            record.Instance:SetAttribute("ApexEventState", "Gated")
            record.Instance:SetAttribute("ApexEventGateReason", gateReason)
            record.Instance:SetAttribute("ApexEventCooldownRemaining", remaining or 0)
            record.Instance:SetAttribute("ApexThreatRadius", record.ThreatRadius or self.ApexThreatRadius)
        end
        return false, gateReason
    end
    local affected = 0
    local apexPosition = self:GetRecordPosition(record)
    for _, candidate in ipairs(self.NPCs) do
        if candidate ~= record and candidate.State ~= "Dead" and candidate.Apex ~= true then
            local distance = (self:GetRecordPosition(candidate) - apexPosition).Magnitude
            if distance <= (record.ThreatRadius or self.ApexThreatRadius) then
                affected = affected + 1
                candidate.LastApexThreat = record.Instance
                candidate.LastApexThreatDistance = distance
                if candidate.Instance then
                    candidate.Instance:SetAttribute("LastApexThreat", record.Instance and record.Instance.Name or "Apex")
                    candidate.Instance:SetAttribute("LastApexThreatDistance", distance)
                    candidate.Instance:SetAttribute("ApexThreatSourceX", apexPosition.X)
                    candidate.Instance:SetAttribute("ApexThreatSourceY", apexPosition.Y)
                    candidate.Instance:SetAttribute("ApexThreatSourceZ", apexPosition.Z)
                    candidate.Instance:SetAttribute("ApexThreatState", "Warned")
                end
            end
        end
    end
    record.LastApexEventAt = now
    record.LastApexEventAffected = affected
    record.ApexEventSequence = (record.ApexEventSequence or 0) + 1
    if record.Instance then
        record.Instance:SetAttribute("ApexEventActive", true)
        record.Instance:SetAttribute("ApexEventState", affected > 0 and "Broadcast" or "BroadcastNoTargets")
        record.Instance:SetAttribute("ApexEventGateReason", "ready")
        record.Instance:SetAttribute("ApexEventAffected", affected)
        record.Instance:SetAttribute("ApexThreatRadius", record.ThreatRadius or self.ApexThreatRadius)
        record.Instance:SetAttribute("ApexEventSequence", record.ApexEventSequence)
        record.Instance:SetAttribute("ApexEventSourceX", apexPosition.X)
        record.Instance:SetAttribute("ApexEventSourceY", apexPosition.Y)
        record.Instance:SetAttribute("ApexEventSourceZ", apexPosition.Z)
        record.Instance:SetAttribute("ApexEventCooldownSeconds", record.ApexEventCooldownSeconds or self.ApexEventCooldownSeconds)
        record.Instance:SetAttribute("ApexEventCooldownRemaining", 0)
        record.Instance:SetAttribute("ApexEventLastAt", now)
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

    if self:IsPreyKind(record.Kind) then
        local playerRoot = self.FindNearestPlayerRoot and self:FindNearestPlayerRoot(record, players, self.FleeDistance)
        if playerRoot then
            local away = self:GetRecordPosition(record) - playerRoot.Position
            if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
            local fleeTarget = self:GetRecordPosition(record) + away.Unit * self.MoveStep
            if record.FlightCapable == true then
                fleeTarget = Vector3.new(fleeTarget.X, math.max(record.PreferredAltitude or fleeTarget.Y, fleeTarget.Y + 8), fleeTarget.Z)
            end
            self:MoveToward(record, fleeTarget, self.MoveStep, "Flee")
            record.FleeFrom = playerRoot.Position
            record.LastFleeAt = os.time()
            return self:Transition(record, "Flee")
        end
    end

    if record.Apex == true then
        local apexEventOk = self:StampApexEvent(record)
        if apexEventOk then return true end
    end

    local nearbyPredator = (self:IsPreyKind(record.Kind) or record.Kind == "Omnivore") and self:FindNearestThreat(record, self.FleeDistance) or nil
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
        local fleeTarget = self:GetRecordPosition(record) + away.Unit * self.MoveStep
        if record.FlightCapable == true then
            fleeTarget = Vector3.new(fleeTarget.X, math.max(record.PreferredAltitude or fleeTarget.Y, fleeTarget.Y + 8), fleeTarget.Z)
        end
        self:MoveToward(record, fleeTarget, self.MoveStep, "Flee")
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

    if record.Kind == "Predator" or record.Kind == "AerialPredator" or record.Apex == true then
        local prey, distance = self:FindNearestHuntTarget(record, self.SenseDistance)
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

    if record.PackHunter == true then
        local packOk = self:ApplyPackBehavior(record)
        if packOk then return true end
    end

    local mateOk = self:TryMate(record)
    if mateOk then return true end

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
    local ok, reason = self:MoveToward(record, targetPosition, stepStuds or self.BrainStepStuds, actionName or "Move")
    if ok and record and record.Instance and record.Instance.SetAttribute then
        record.Instance:SetAttribute("LastBrainMovedAt", os.time())
    end
    return ok, reason
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
    if record and record.Apex == true then
        local apexEventOk = self:StampApexEvent(record)
        if apexEventOk then return true end
    end
    -- Lane D: prefer hunting a live player over wandering (safe-zone filtered internally).
    local playerRoot, playerTarget, playerDist = self:FindNearestPlayerHuntTarget(record, players, record.MaxChaseDistance or 120)
    local npcRoot, npcDistance = self:FindNearestPlayerRoot(record, players, record.MaxChaseDistance or 120)
    -- Pick whichever valid target is closer.
    local root, distance, isPlayerTarget = nil, math.huge, false
    if playerRoot and playerDist then
        root, distance, isPlayerTarget = playerRoot, playerDist, true
    end
    if npcRoot and npcDistance and npcDistance < distance then
        root, distance, isPlayerTarget = npcRoot, npcDistance, false
    end
    if root and distance then
        record.ChaseTarget = root.Parent
        if isPlayerTarget and record.Instance then
            record.Instance:SetAttribute("ChasingPlayer", true)
        end
        if distance <= self.AttackDistance then
            record.LastAttackAt = os.time()
            self:Transition(record, "Attack")
            if record.Instance and record.Instance.SetAttribute then
                record.Instance:SetAttribute("LastBrainAction", "Attack")
                record.Instance:SetAttribute("AttackRangeConfirmed", true)
            end
            -- Lane D: NPC attack on player — damage is applied via CombatService
            -- when the client fires RequestAttack; NPC brain only sets state here.
            -- Direct NPC→player damage is handled by the NPC attack event listener
            -- in the main game loop (not in NPCService to keep separation of concerns).
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
    carcass:SetAttribute("FoodKind", record and self:GetCarnivoreFoodKind(record.Kind) or "PreyCarcass")
    carcass:SetAttribute("Depleted", false)
    carcass:SetAttribute("RespawnCooldownSeconds", 180)
    carcass:SetAttribute("CreatorStoreOnly", true)
    carcass:SetAttribute("ImportedVisibleAsset", true)
    carcass:SetAttribute("AssetManifestId", carcass:GetAttribute("AssetManifestId") or "ImportedPreyCarcass")
    carcass:SetAttribute("SourceNPC", npc.Name)
    carcass:SetAttribute("PotentialCarnivoreFood", true)
    carcass:SetAttribute("CarcassFoodSource", true)
    carcass:SetAttribute("GameplayQuery", true)
    carcass:SetAttribute("CompactFoodGroup", "NPCCarcass")
    carcass.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    CollectionService:AddTag(carcass, "FoodSource")
    CollectionService:AddTag(carcass, "CarnivoreFoodCandidate")
    return carcass
end

-- Lane D: Create a carcass food source from a dead player (parallel to CreateCarcassFoodSource
-- for NPC records). Uses the same imported visual + tagging pipeline so carnivore NPCs and
-- players can eat it via the existing FoodSource / CarnivoreFoodCandidate tags.
-- Parameters:
--   deadPlayer  — the Roblox Player object (used for name + character position)
--   deadState   — the SurvivalService state table at time of death
--   nutrition   — optional override; defaults to 30 (slightly less than NPC prey)
function NPCService:CreatePlayerCarcassFoodSource(deadPlayer, deadState, nutrition)
    if not deadPlayer then return nil, "missing_player" end
    -- Resolve position from character if available, else state data.
    local position = Vector3.new(0, 3, 0)
    local character = deadPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        position = root.Position
    end

    local source = self:ResolveImportedCarcassVisual()
    if not source then return nil, "missing_imported_carcass_visual" end
    local carcass = source:Clone()
    local baseName = (deadPlayer.Name or "Player") .. "_PlayerCarcass"
    if carcass:IsA("BasePart") then
        local wrapper = Instance.new("Model")
        wrapper.Name = baseName
        carcass.Parent = wrapper
        wrapper.PrimaryPart = carcass
        carcass = wrapper
    else
        carcass.Name = baseName
    end
    -- Strip scripts; anchor geometry.
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
        if not carcass.PrimaryPart then
            carcass.PrimaryPart = carcass:FindFirstChildWhichIsA("BasePart", true)
        end
        if carcass.PrimaryPart then carcass:PivotTo(CFrame.new(position)) end
    end
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", nutrition or 30)
    carcass:SetAttribute("FoodKind", "PlayerCarcass")
    carcass:SetAttribute("Depleted", false)
    carcass:SetAttribute("RespawnCooldownSeconds", 120)
    carcass:SetAttribute("CreatorStoreOnly", true)
    carcass:SetAttribute("ImportedVisibleAsset", true)
    carcass:SetAttribute("AssetManifestId", carcass:GetAttribute("AssetManifestId") or "ImportedPreyCarcass")
    carcass:SetAttribute("SourcePlayer", deadPlayer.Name)
    carcass:SetAttribute("SourcePlayerUserId", deadPlayer.UserId)
    carcass:SetAttribute("PotentialCarnivoreFood", true)
    carcass:SetAttribute("CarcassFoodSource", true)
    carcass:SetAttribute("GameplayQuery", true)
    carcass:SetAttribute("CompactFoodGroup", "PlayerCarcass")
    carcass:SetAttribute("PlayerCarcass", true)
    -- Store stage at death for growth-reward lookups by eating players.
    if deadState then
        carcass:SetAttribute("VictimGrowthStage", deadState.GrowthStage or "Hatchling")
        carcass:SetAttribute("VictimSpeciesId", deadState.SpeciesId or "")
    end
    carcass.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    CollectionService:AddTag(carcass, "FoodSource")
    CollectionService:AddTag(carcass, "CarnivoreFoodCandidate")
    return carcass
end

-- Lane D: Find the nearest living player character that a carnivore NPC could hunt.
-- Respects safe-zone exclusion: players tagged SafeZone or with character inside a
-- SafeZone-tagged region are skipped.
-- Returns (root, player, distance) or (nil, nil, nil).
function NPCService:FindNearestPlayerHuntTarget(record, players, maxDistance)
    local position = self:GetRecordPosition(record)
    local bestRoot, bestPlayer, bestDistance = nil, nil, maxDistance or self.SenseDistance
    for _, player in ipairs(players or {}) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local distance = (root.Position - position).Magnitude
            if distance <= bestDistance then
                -- Safe-zone gate: skip players in safe zones.
                local inSafe = false
                local CollSvc = CollectionService
                -- Check if any touching part has SafeZone tag (lightweight region check).
                local params = OverlapParams.new()
                params.FilterType = Enum.RaycastFilterType.Include
                local touching = workspace:GetPartBoundsInRadius(root.Position, 6, params)
                for _, part in ipairs(touching) do
                    if CollSvc:HasTag(part, "SafeZone") then
                        inSafe = true
                        break
                    end
                end
                if not inSafe then
                    bestRoot, bestPlayer, bestDistance = root, player, distance
                end
            end
        end
    end
    return bestRoot, bestPlayer, bestDistance
end

function NPCService:MarkPreyDead(record)
    if not record or not self:IsPreyKind(record.Kind) then return false, "not_prey" end
    self:Transition(record, "Dead")
    if not record.Carcass then
        record.Carcass = self:CreateCarcassFoodSource(record, 35)
    end
    return true, record.Carcass
end

function NPCService:TickNPCs(players)
    self:PruneStaleRecords()
    local active = 0
    local total = #self.NPCs
    if total == 0 then return 0 end
    local budget = math.max(1, math.min(self.MaxBrainTicksPerCycle or self.MaxActive or total, total))
    local startIndex = math.clamp(self.BrainRoundRobinIndex or 1, 1, total)
    local ticked = {}
    for offset = 0, budget - 1 do
        local index = ((startIndex + offset - 1) % total) + 1
        ticked[index] = true
        local record = self.NPCs[index]
        local ok = self:TickBrain(record, players, self.TickSeconds)
        if record.Instance then
            record.Instance:SetAttribute("ActiveNPCBrain", true)
            record.Instance:SetAttribute("BrainState", record.State)
            record.Instance:SetAttribute("BrainCycleBudget", budget)
            record.Instance:SetAttribute("BrainCycleTotal", total)
            record.Instance:SetAttribute("BrainDeferred", false)
        end
        if ok then
            active = active + 1
        end
    end
    self.BrainRoundRobinIndex = ((startIndex + budget - 1) % total) + 1
    if budget < total then
        for index = 1, total do
            local record = self.NPCs[index]
            if record.Instance and not ticked[index] then
                record.Instance:SetAttribute("BrainDeferred", true)
                record.Instance:SetAttribute("BrainCycleBudget", budget)
                record.Instance:SetAttribute("BrainCycleTotal", total)
            end
        end
    end
    return active
end

function NPCService:StartTickLoop(playersService)
    if self.TickLoopStarted then return false, "already_started" end
    self.TickLoopStarted = true
    -- Brain decision tick (1 s intervals) — decides state & issues MoveTo targets.
    task.spawn(function()
        while self.TickLoopStarted do
            task.wait(self.TickSeconds)
            self:TickNPCs((playersService or game:GetService("Players")):GetPlayers())
        end
    end)
    -- Continuous MoveToTarget heartbeat — keeps Humanoid-driven NPCs walking toward their
    -- current target every frame so motion stays smooth even between brain ticks.
    task.spawn(function()
        local RunService = game:GetService("RunService")
        while self.TickLoopStarted do
            RunService.Heartbeat:Wait()
            for _, record in ipairs(self.NPCs) do
                if record.State ~= "Dead" and record.MoveTarget then
                    local npc = record.Instance
                    if npc then
                        local root, mode = self:ResolveLocomotionRoot(npc)
                        local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
                        if humanoid and root and mode == "HumanoidMoveTo" then
                            local dist = (root.Position - record.MoveTarget).Magnitude
                            if dist > 2 then
                                humanoid:MoveTo(record.MoveTarget)
                            else
                                record.MoveTarget = nil
                            end
                        end
                    end
                end
            end
        end
    end)
    return true
end

return NPCService
