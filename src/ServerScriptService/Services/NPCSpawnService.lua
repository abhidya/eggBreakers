local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCService = require(script.Parent.NPCService)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local StagedMeshLibrary = require(ReplicatedStorage.Shared.StagedMeshLibrary)
local EcosystemRoster = require(ReplicatedStorage.Shared.EcosystemRoster)

local NPCSpawnService = { SpawnLoopRunning = false }
NPCSpawnService.TargetActive = 12
NPCSpawnService.SpawnKinds = { "Prey", "Prey", "Prey", "AerialPrey", "Omnivore", "Predator", "AerialPredator", "Apex", "SemiAquatic" }
NPCSpawnService.SpawnTickSeconds = 10
NPCSpawnService.NPCModelCandidatePaths = {
    Prey = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Triceratops_Model_Set/Hatchling",
    },
    AerialPrey = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/Hatchling",
    },
    Predator = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Hatchling",
    },
    AerialPredator = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Pteranodon_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Velociraptor_Model_Set/Hatchling",
    },
    Apex = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Tyrannosaurus_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Carnotaurus_Model_Set/Adult",
    },
    Omnivore = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Oviraptor_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Gallimimus_Model_Set/Juvenile",
    },
    SemiAquatic = {
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/Hatchling",
        "ReplicatedStorage/ImportedAssetLibrary/Imported_Playable_Spinosaurus_Model_Set/Adult",
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

local function isHelperVisualPart(part)
    local name = string.lower(part.Name)
    return name == "rootpart"
        or name == "humanoidrootpart"
        or string.find(name, "hitbox", 1, true) ~= nil
        or string.find(name, "collision", 1, true) ~= nil
        or string.find(name, "collider", 1, true) ~= nil
        or string.find(name, "bounding", 1, true) ~= nil
        or string.find(name, "bounds", 1, true) ~= nil
        or string.find(name, "helper", 1, true) ~= nil
end

function NPCSpawnService:ResolveImportedNPCModel(kind)
    local profile = NPCService:GetKindProfile(kind)
    local speciesId = profile and profile.SpeciesId
    if speciesId then
        local staged = StagedMeshLibrary:ResolveModel(speciesId)
        if staged and hasVisiblePart(staged) then return staged end
    end
    for _, path in ipairs(self.NPCModelCandidatePaths[kind] or {}) do
        local candidate = resolvePath(path)
        if candidate and hasVisiblePart(candidate) then return candidate end
    end
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        for _, descendant in ipairs(library:GetDescendants()) do
            local name = string.lower(descendant.Name)
            if (string.find(name, "dinosaur", 1, true) or string.find(name, "raptor", 1, true) or string.find(name, "triceratops", 1, true) or string.find(name, "pterodactyl", 1, true) or string.find(name, "pteranodon", 1, true) or string.find(name, "pterosaur", 1, true)) and hasVisiblePart(descendant) then
                return descendant
            end
        end
    end
    return nil
end

function NPCSpawnService:IsLiveCarnivoreFoodKind(kind)
    return NPCService:IsPreyKind(kind)
end

function NPCSpawnService:GetCarnivoreFoodKind(kind)
    if kind == "AerialPrey" or kind == "FlyingPrey" then return "AerialPreyCarcass" end
    if kind == "Predator" or kind == "AerialPredator" then return "PredatorCarcass" end
    if kind == "Apex" then return "LargeCarcass" end
    return "PreyCarcass"
end

function NPCSpawnService:PrepareNPCModel(source, kind, index, spawnInstance)
    local profile = NPCService:GetKindProfile(kind)
    local species = SpeciesConfig[profile.SpeciesId]
    local clone = source:Clone()
    clone.Name = kind .. "NPC_" .. tostring(index)
    clone:SetAttribute("NPCKind", kind)
    clone:SetAttribute("SpeciesId", profile.SpeciesId)
    clone:SetAttribute("SpeciesRole", species and species.Role or kind)
    clone:SetAttribute("Diet", profile.Diet)
    clone:SetAttribute("Carnivore", profile.Diet == "Carnivore")
    clone:SetAttribute("ApexCategory", profile.Apex == true)
    clone:SetAttribute("HerdingEnabled", profile.Herding == true)
    clone:SetAttribute("FlightCapable", profile.FlightCapable == true)
    clone:SetAttribute("Flying", profile.FlightCapable == true)
    local potentialCarnivoreFood = NPCService:IsPreyKind(kind)
    clone:SetAttribute("AerialPrey", kind == "AerialPrey" or kind == "FlyingPrey")
    clone:SetAttribute("PreferredAltitude", profile.PreferredAltitude)
    clone:SetAttribute("PotentialCarnivoreFood", potentialCarnivoreFood)
    clone:SetAttribute("CarnivoreFoodCandidate", potentialCarnivoreFood)
    clone:SetAttribute("FoodWhenDefeated", true)
    clone:SetAttribute("CarnivoreFoodKind", self:GetCarnivoreFoodKind(kind))
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
            if isHelperVisualPart(descendant) then
                descendant.Transparency = 1
                descendant.CanQuery = false
                descendant:SetAttribute("NPCInvisibleRigHelper", true)
            else
                descendant.CanQuery = true
            end
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
        wrapper:SetAttribute("SpeciesId", profile.SpeciesId)
        wrapper:SetAttribute("SpeciesRole", species and species.Role or kind)
        wrapper:SetAttribute("Diet", profile.Diet)
        wrapper:SetAttribute("Carnivore", profile.Diet == "Carnivore")
        wrapper:SetAttribute("ApexCategory", profile.Apex == true)
        wrapper:SetAttribute("HerdingEnabled", profile.Herding == true)
        wrapper:SetAttribute("FlightCapable", profile.FlightCapable == true)
        wrapper:SetAttribute("Flying", profile.FlightCapable == true)
        wrapper:SetAttribute("AerialPrey", kind == "AerialPrey" or kind == "FlyingPrey")
        wrapper:SetAttribute("PreferredAltitude", profile.PreferredAltitude)
        wrapper:SetAttribute("PotentialCarnivoreFood", potentialCarnivoreFood)
        wrapper:SetAttribute("CarnivoreFoodCandidate", potentialCarnivoreFood)
        wrapper:SetAttribute("FoodWhenDefeated", true)
        wrapper:SetAttribute("CarnivoreFoodKind", self:GetCarnivoreFoodKind(kind))
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

-- A carcass / food source is gameplay-relevant and must never be despawned by NPC cleanup.
function NPCSpawnService:IsCarcassFoodSource(instance)
    if not instance then return false end
    return instance:GetAttribute("CarcassFoodSource") == true
        or instance:GetAttribute("PlayerCarcass") == true
end

-- True when the instance looks like a live-NPC model (carries a kind, is not a carcass).
function NPCSpawnService:IsNPCModel(instance)
    if not instance then return false end
    if self:IsCarcassFoodSource(instance) then return false end
    return instance:GetAttribute("NPCKind") ~= nil
end

-- Count MeshParts anywhere in the model; 0 means a primitive (Part-only) placeholder body.
function NPCSpawnService:CountMeshParts(instance)
    if not instance then return 0 end
    local count = 0
    if instance:IsA("MeshPart") then count = count + 1 end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("MeshPart") then count = count + 1 end
    end
    return count
end

-- A staged mesh is available for a kind when StagedMeshLibrary resolves a visible model for its species.
function NPCSpawnService:HasStagedMeshForKind(kind)
    if not kind then return false end
    local profile = NPCService:GetKindProfile(kind)
    local speciesId = profile and profile.SpeciesId
    if not speciesId then return false end
    local staged = StagedMeshLibrary:ResolveModel(speciesId)
    return staged ~= nil and hasVisiblePart(staged)
end

function NPCSpawnService:PruneStaleNPCRecords()
    local pruned = 0
    for index = #NPCService.NPCs, 1, -1 do
        local record = NPCService.NPCs[index]
        local instance = record and record.Instance
        if not instance or instance.Parent == nil then
            table.remove(NPCService.NPCs, index)
            pruned = pruned + 1
        end
    end
    return pruned
end

-- Remove NPC models from Workspace.NPCs that are stale:
--   * not registered in NPCService.NPCs, OR
--   * beyond NPCService.MaxActive (excess), OR
--   * primitive (0 MeshParts) when a staged mesh is available for that kind.
-- Carcass/food sources are always preserved. Returns the number removed.
function NPCSpawnService:CleanupStaleNPCs()
    local folder = Workspace:FindFirstChild("NPCs")
    if not folder then return 0 end

    -- Build a fast lookup of currently registered live NPC instances.
    local registered = {}
    for _, record in ipairs(NPCService.NPCs) do
        if record.Instance then registered[record.Instance] = true end
    end

    local maxActive = NPCService.MaxActive or 30
    local keptActive = 0
    local removed = 0

    for _, child in ipairs(folder:GetChildren()) do
        if self:IsNPCModel(child) then
            local kind = child:GetAttribute("NPCKind")
            local isRegistered = registered[child] == true
            local stale = false

            if not isRegistered then
                -- Orphaned model from a prior session / direct parenting.
                stale = true
            elseif self:HasStagedMeshForKind(kind) and self:CountMeshParts(child) == 0 then
                -- Registered but a primitive placeholder while a real staged mesh exists.
                stale = true
            else
                keptActive = keptActive + 1
                if keptActive > maxActive then
                    -- Beyond the hard active cap — trim the excess.
                    stale = true
                end
            end

            if stale then
                if isRegistered then
                    local record = NPCService:FindRecordForInstance(child)
                    if record then
                        for index = #NPCService.NPCs, 1, -1 do
                            if NPCService.NPCs[index] == record then
                                table.remove(NPCService.NPCs, index)
                                break
                            end
                        end
                    end
                end
                child:Destroy()
                removed = removed + 1
            end
        end
    end

    return removed
end

function NPCSpawnService:MaintainMinimumActive()
    self:EnsureNPCFolder()
    self:PruneStaleNPCRecords()
    -- Despawn stale/excess/primitive NPC models before topping up so the world
    -- never accumulates leftover placeholder bodies across sessions.
    self:CleanupStaleNPCs()
    local active = #NPCService.NPCs
    local spawnFolder = self:GetSpawnFolder()
    local spawns = spawnFolder and spawnFolder:GetChildren() or {}
    local index = active
    local attempts = 0
    local maxAttempts = math.max(self.TargetActive * 2, #spawns * 2, 1)
    local failures = 0
    local lastFailureReason = nil
    local lastFailureKind = nil
    while active < self.TargetActive and active < NPCService.MaxActive and attempts < maxAttempts do
        attempts = attempts + 1
        index = index + 1
        local spawnInstance = spawns[((index - 1) % math.max(#spawns, 1)) + 1]
        if #spawns == 0 or self:IsSpawnPositionAllowed(spawnInstance) then
            local kind = spawnInstance and spawnInstance:GetAttribute("NPCKind") or self.SpawnKinds[((index - 1) % #self.SpawnKinds) + 1]
            local ok, result = self:CreateNPCRecord(spawnInstance, kind, index)
            if ok then
                active = active + 1
            else
                failures = failures + 1
                lastFailureReason = result or "spawn_failed"
                lastFailureKind = kind
            end
        end
    end
    self.LastMaintainAttempts = attempts
    self.LastSpawnFailures = failures
    self.LastSpawnFailureReason = lastFailureReason
    self.LastSpawnFailureKind = lastFailureKind
    return active
end

-- =============================================================================
-- ECOSYSTEM MODE (additive)
-- Spawns the full staged ecosystem — EVERY distinct species enumerated by
-- EcosystemRoster from Workspace.dinosaur — as living NPCs, instead of only the
-- ~9 fixed SpawnKinds. This path is entirely separate from MaintainMinimumActive /
-- SpawnKinds (which it never calls or mutates) so the existing spawn loop + its
-- tests are unaffected. Fully world-absent safe: with no Workspace.dinosaur the
-- roster is empty and SpawnEcosystem is a no-op returning 0.
-- =============================================================================

-- Map a roster diet (+ aquatic flag) to the NPCService "kind" whose profile/brain
-- best matches it. Kinds drive NPCService:Register's stats and the brain; species
-- identity is preserved separately via SpeciesId/SpeciesName attributes.
function NPCSpawnService:EcosystemKindFor(entry)
    if entry.aquatic then
        return "SemiAquatic"
    end
    if entry.diet == "Herbivore" then
        return "Prey"
    elseif entry.diet == "Omnivore" then
        return "Omnivore"
    elseif entry.diet == "Carnivore" then
        return "Predator"
    end
    return "Prey"
end

-- Prepare a clone of a staged ecosystem source model into a ready-to-register NPC.
-- Mirrors PrepareNPCModel's clone + strip-scripts + ground/pivot pattern, but stamps
-- the SPECIES identity (from the roster) on top of the kind-derived attributes so the
-- spawned NPC reads as its true species rather than the generic kind substitute.
function NPCSpawnService:PrepareEcosystemNPCModel(entry, kind, index, spawnPosition)
    local clone = self:PrepareNPCModel(entry.sourceModel, kind, index, nil)
    clone.Name = entry.speciesName .. "NPC_" .. tostring(index)
    -- Species identity (overrides the kind-substitute SpeciesId from PrepareNPCModel).
    clone:SetAttribute("SpeciesId", entry.speciesId)
    clone:SetAttribute("SpeciesName", entry.speciesName)
    clone:SetAttribute("DietFolder", entry.dietFolder)
    clone:SetAttribute("Diet", entry.diet)
    clone:SetAttribute("Carnivore", entry.diet == "Carnivore")
    clone:SetAttribute("EcosystemNPC", true)
    clone:SetAttribute("Aquatic", entry.aquatic == true)
    clone:SetAttribute("AquaticSpecies", entry.aquatic == true)
    -- A spinosaur-style semi-aquatic kind already implies swim; an aquatic species also flies? no.
    if entry.aquatic then
        clone:SetAttribute("FlightCapable", false)
        clone:SetAttribute("Flying", false)
    end
    clone:SetAttribute("AssetManifestId", "EcosystemNPC_" .. entry.speciesId)
    -- Ground / position the prepared model.
    if typeof(spawnPosition) == "Vector3" then
        if clone:IsA("Model") then
            if not clone.PrimaryPart then
                clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
            end
            if clone.PrimaryPart then clone:PivotTo(CFrame.new(spawnPosition)) end
        elseif clone:IsA("BasePart") then
            clone.CFrame = CFrame.new(spawnPosition)
        end
    end
    return clone
end

-- Compute a spread of spawn positions across the map. Prefers authored NPC spawn
-- markers (Map.NPCSpawns); falls back to a deterministic ring grid around the origin
-- so the ecosystem still spreads out when no markers exist.
function NPCSpawnService:ResolveEcosystemSpawnPositions(count)
    local positions = {}
    local spawnFolder = self:GetSpawnFolder()
    local spawns = spawnFolder and spawnFolder:GetChildren() or {}
    local allowed = {}
    for _, spawn in ipairs(spawns) do
        if spawn:IsA("BasePart") and self:IsSpawnPositionAllowed(spawn) then
            table.insert(allowed, spawn.Position)
        end
    end
    for i = 1, count do
        if #allowed > 0 then
            positions[i] = allowed[((i - 1) % #allowed) + 1]
        else
            -- Deterministic spiral grid fallback.
            local ring = math.floor(math.sqrt(i))
            local angle = i * 2.399963 -- golden-angle-ish spread
            local radius = 40 + ring * 36
            positions[i] = Vector3.new(math.cos(angle) * radius, 12, math.sin(angle) * radius)
        end
    end
    return positions
end

-- Spawn a spread of DISTINCT species NPCs across the map. Each enumerated species is
-- spawned at least once (clamped to NPCService.MaxActive). Additive: never touches the
-- SpawnKinds / MaintainMinimumActive path.
-- opts:
--   maxSpecies     — optional cap on number of distinct species to spawn
--   perSpecies     — copies of each species to spawn (default 1)
--   respectMaxCap  — when not false, stops at NPCService.MaxActive (default true)
-- Returns: spawnedCount, results (array of { entry, kind, ok, reason, record })
function NPCSpawnService:SpawnEcosystem(opts)
    opts = opts or {}
    self:EnsureNPCFolder()

    local roster = EcosystemRoster:GetRoster()
    local results = {}
    local spawned = 0

    if #roster == 0 then
        self.LastEcosystemSpawned = 0
        self.LastEcosystemSpecies = 0
        return 0, results
    end

    local perSpecies = math.max(1, opts.perSpecies or 1)
    local maxSpecies = opts.maxSpecies or #roster
    local respectMaxCap = opts.respectMaxCap ~= false

    local distinctSpecies = 0
    local index = #NPCService.NPCs

    for _, entry in ipairs(roster) do
        if distinctSpecies >= maxSpecies then break end
        distinctSpecies = distinctSpecies + 1

        for copy = 1, perSpecies do
            if respectMaxCap and #NPCService.NPCs >= NPCService.MaxActive then
                break
            end
            index = index + 1
            local kind = self:EcosystemKindFor(entry)
            local positions = self:ResolveEcosystemSpawnPositions(index + 1)
            local spawnPosition = positions[index] or Vector3.new(0, 12, 0)

            local ok, reason, record = pcall(function()
                local model = self:PrepareEcosystemNPCModel(entry, kind, index, spawnPosition)
                model.Parent = Workspace:FindFirstChild("NPCs") or Workspace
                local registered, result = NPCService:Register(model, kind)
                if not registered then
                    model:Destroy()
                end
                return registered, result
            end)

            -- pcall returns (success, ...); normalize.
            local createOk, registerResult
            if ok then
                createOk, registerResult = reason, record
            else
                createOk, registerResult = false, tostring(reason)
            end

            table.insert(results, {
                entry = entry,
                kind = kind,
                ok = createOk == true,
                reason = createOk == true and nil or (registerResult or "spawn_failed"),
                record = type(registerResult) == "table" and registerResult or nil,
            })
            if createOk == true then
                spawned = spawned + 1
            end
        end
    end

    self.LastEcosystemSpawned = spawned
    self.LastEcosystemSpecies = distinctSpecies
    return spawned, results
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
