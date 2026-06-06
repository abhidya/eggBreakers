local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local StagedMeshLibrary = require(ReplicatedStorage.Shared.StagedMeshLibrary)

local suite = { name = "NPCSpawnValidation.server", category = "Placement", tests = {} }

local function hasVisiblePart(instance)
    if instance:IsA("BasePart") and instance.Transparency < 1 then return true end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then return true end
    end
    return false
end

local function withIsolatedImportedLibrary(callback)
    local original = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    local savedName
    if original then
        savedName = "ImportedAssetLibrary_SavedForNPCSpawnValidation_" .. tostring(math.floor(os.clock() * 1000000))
        original.Name = savedName
    end
    local library = Instance.new("Folder")
    library.Name = "ImportedAssetLibrary"
    library.Parent = ReplicatedStorage
    local ok, result = pcall(callback, library)
    library:Destroy()
    if original then
        original.Name = "ImportedAssetLibrary"
    end
    if not ok then
        error(result, 2)
    end
    return result
end

table.insert(suite.tests, { name = "NPC spawn zones valid", run = function()
    local spawn = Instance.new("Part")
    spawn.Name = "FernPlainsSpawn"
    Assert.truthy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "valid spawn allowed")
    spawn:SetAttribute("InsideWall", true)
    Assert.falsy(NPCSpawnService:IsSpawnPositionAllowed(spawn), "wall spawn rejected")
    spawn:Destroy()
end })

table.insert(suite.tests, { name = "spawn loop can materialize active NPC records", run = function()
    local old = NPCSpawnService.TargetActive
    local before = #NPCService.NPCs
    NPCSpawnService.TargetActive = math.min(before + 1, NPCService.MaxActive)
    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.truthy(active >= NPCSpawnService.TargetActive, "spawn loop reaches target")
    NPCSpawnService.TargetActive = old
end })

table.insert(suite.tests, { name = "spawn loop prunes parentless records before active count", run = function()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    local oldCreate = NPCSpawnService.CreateNPCRecord
    local spawned = {}

    NPCService.NPCs = {}
    local stale = Instance.new("Model")
    stale.Name = "ParentlessSpawnRecord"
    local staleRoot = Instance.new("Part")
    staleRoot.Name = "Root"
    staleRoot.Parent = stale
    stale.PrimaryPart = staleRoot
    stale.Parent = workspace
    NPCService:Register(stale, "Prey")
    stale:Destroy()

    NPCSpawnService.TargetActive = 1
    NPCSpawnService.CreateNPCRecord = function(self, spawnInstance, kind, index)
        local npc = Instance.new("Model")
        npc.Name = "PrunedRecordReplacement_" .. tostring(index)
        local root = Instance.new("Part")
        root.Name = "Root"
        root.Parent = npc
        npc.PrimaryPart = root
        npc:SetAttribute("NPCKind", kind or "Prey")
        npc.Parent = self:EnsureNPCFolder()
        table.insert(spawned, npc)
        return NPCService:Register(npc, kind or "Prey")
    end

    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.equals(active, 1, "parentless record does not count as active")
    Assert.equals(#NPCService.NPCs, 1, "stale record pruned before top-up")
    Assert.truthy(NPCService.NPCs[1].Instance and NPCService.NPCs[1].Instance.Parent ~= nil, "remaining record has live instance")

    for _, npc in ipairs(spawned) do npc:Destroy() end
    NPCSpawnService.CreateNPCRecord = oldCreate
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "spawn loop continues after one spawn failure", run = function()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    local oldCreate = NPCSpawnService.CreateNPCRecord
    local spawned = {}
    local calls = 0

    NPCService.NPCs = {}
    NPCSpawnService.TargetActive = 2
    NPCSpawnService.CreateNPCRecord = function(self, spawnInstance, kind, index)
        calls = calls + 1
        if calls == 1 then
            return false, "test_missing_model"
        end
        local npc = Instance.new("Model")
        npc.Name = "ContinuationSpawn_" .. tostring(index)
        local root = Instance.new("Part")
        root.Name = "Root"
        root.Parent = npc
        npc.PrimaryPart = root
        npc:SetAttribute("NPCKind", kind or "Prey")
        npc.Parent = self:EnsureNPCFolder()
        table.insert(spawned, npc)
        return NPCService:Register(npc, kind or "Prey")
    end

    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.equals(active, 2, "spawn loop fills target after a single failed spawn")
    Assert.truthy(calls >= 3, "spawn loop attempted later candidates after failure")
    Assert.equals(NPCSpawnService.LastSpawnFailures, 1, "spawn failure probe counted the skipped spawn")
    Assert.equals(NPCSpawnService.LastSpawnFailureReason, "test_missing_model", "spawn failure probe records reason")

    for _, npc in ipairs(spawned) do npc:Destroy() end
    NPCSpawnService.CreateNPCRecord = oldCreate
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "staged NPC helper root remains invisible after prepare", run = function()
    local source = Instance.new("Model")
    source.Name = "StagedNPCHelperProbe"
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(48, 48, 48)
    root.Transparency = 0
    root.Parent = source
    source.PrimaryPart = root
    local body = Instance.new("MeshPart")
    body.Name = "VisibleBody"
    body.Size = Vector3.new(6, 4, 12)
    body.Transparency = 0
    body.Parent = source

    local marker = Instance.new("Part")
    marker.Name = "NPCPrepareProbeSpawn"
    marker.Position = Vector3.new(0, 14, 0)
    local prepared = NPCSpawnService:PrepareNPCModel(source, "Prey", 9001, marker)
    local preparedRoot = prepared:FindFirstChild("RootPart", true)
    local preparedBody = prepared:FindFirstChild("VisibleBody", true)

    Assert.notNil(preparedRoot, "prepared NPC has helper root")
    Assert.notNil(preparedBody, "prepared NPC keeps visible mesh body")
    Assert.equals(preparedRoot.Transparency, 1, "NPC helper root is hidden")
    Assert.equals(preparedRoot.CanCollide, false, "NPC helper root does not collide")
    Assert.equals(preparedRoot.CanTouch, false, "NPC helper root does not touch")
    Assert.equals(preparedRoot.CanQuery, false, "NPC helper root does not query")
    Assert.equals(preparedRoot:GetAttribute("NPCInvisibleRigHelper"), true, "NPC helper root is marked")
    Assert.truthy(preparedBody.Transparency < 1, "NPC mesh body remains visible")

    prepared:Destroy()
    marker:Destroy()
    source:Destroy()
end })

table.insert(suite.tests, { name = "prepared NPC dinosaur meshes are auto-uprighted and forward-normalized", run = function()
    local source = Instance.new("Model")
    source.Name = "RolledNPCDinosaurProbe"
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(10, 10, 10)
    root.Transparency = 1
    root.Parent = source
    source.PrimaryPart = root
    local roll = CFrame.Angles(0, 0, math.rad(90))
    local body = Instance.new("MeshPart")
    body.Name = "VisibleBody"
    body.Size = Vector3.new(5, 3, 12)
    body.CFrame = CFrame.new(0, 0, 0) * roll
    body.Transparency = 0
    body.Parent = source
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.CFrame = CFrame.new(0, 0, -7) * roll
    head.Transparency = 0
    head.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(2, 2, 3)
    tail.CFrame = CFrame.new(0, 0, 7) * roll
    tail.Transparency = 0
    tail.Parent = source

    local marker = Instance.new("Part")
    marker.Name = "NPCOrientationProbeSpawn"
    marker.Position = Vector3.new(0, 14, 0)

    local prepared = NPCSpawnService:PrepareNPCModel(source, "Prey", 9002, marker)
    local preparedBody = prepared:FindFirstChild("VisibleBody", true)

    Assert.notNil(preparedBody, "prepared NPC keeps body")
    Assert.equals(prepared:GetAttribute("NPCOrientationNormalized"), true, "NPC orientation normalization ran")
    Assert.equals(prepared:GetAttribute("AutoUprightApplied"), true, "rolled NPC mesh was corrected upright")
    Assert.truthy(preparedBody.CFrame.UpVector:Dot(Vector3.yAxis) >= 0.82, "NPC body is upright")
    Assert.truthy((prepared:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "NPC faces its target forward")

    prepared:Destroy()
    marker:Destroy()
    source:Destroy()
end })

table.insert(suite.tests, { name = "NPC spawn resolves staged MeshPart model before fallback", run = function()
    local oldRecords = NPCService.NPCs
    local oldStagingFolderName = StagedMeshLibrary.StagingFolderName
    local oldTyrannosaurusEntry = StagedMeshLibrary.SpeciesMesh.tyrannosaurus
    NPCService.NPCs = {}
    StagedMeshLibrary.StagingFolderName = "NPCSpawnValidation_StagedDinosaurs_" .. tostring(math.floor(os.clock() * 1000000))
    StagedMeshLibrary.SpeciesMesh.tyrannosaurus = {
        folder = "Carnivores (land)",
        name = "TyrannosaurusProbe",
    }
    local stagingRoot
    local marker
    local record
    local ok, err = pcall(function()
        local leaked = workspace:FindFirstChild(StagedMeshLibrary.StagingFolderName)
        if leaked then leaked:Destroy() end
        stagingRoot = Instance.new("Folder")
        stagingRoot.Name = StagedMeshLibrary.StagingFolderName
        stagingRoot.Parent = workspace
        local carnivores = Instance.new("Folder")
        carnivores.Name = "Carnivores (land)"
        carnivores.Parent = stagingRoot

        local source = Instance.new("Model")
        source.Name = "TyrannosaurusProbe"
        source:SetAttribute("SourceAssetId", "probe-staged-mesh")
        local root = Instance.new("Part")
        root.Name = "RootPart"
        root.Size = Vector3.new(16, 16, 16)
        root.Transparency = 1
        root.Parent = source
        local body = Instance.new("MeshPart")
        body.Name = "VisibleApexBody"
        body.Size = Vector3.new(8, 4, 16)
        body.Transparency = 0
        body.Parent = source
        local animationController = Instance.new("AnimationController")
        animationController.Parent = source
        source.PrimaryPart = root
        source.Parent = carnivores

        marker = Instance.new("Part")
        marker.Name = "StagedApexSpawnProbe"
        marker.Position = Vector3.new(0, 18, 0)
        marker:SetAttribute("NPCKind", "Apex")
        marker.Parent = workspace

        local resolved = NPCSpawnService:ResolveImportedNPCModel("Apex")
        Assert.equals(resolved, source, "Apex resolves staged Tyrannosaurus source model")
        local createOk
        createOk, record = NPCSpawnService:CreateNPCRecord(marker, "Apex", 9102)
        Assert.truthy(createOk, "staged apex NPC record creates")
        Assert.notNil(record and record.Instance, "record has spawned staged instance")
        Assert.truthy(NPCSpawnService:CountMeshParts(record.Instance) > 0, "spawned staged NPC keeps MeshPart body")
        local spawnedRoot = record.Instance:FindFirstChild("RootPart", true)
        local spawnedBody = record.Instance:FindFirstChild("VisibleApexBody", true)
        Assert.notNil(spawnedRoot, "spawned staged NPC has root helper")
        Assert.notNil(spawnedBody, "spawned staged NPC has mesh body")
        Assert.equals(spawnedRoot.Transparency, 1, "spawned staged helper root hidden")
        Assert.equals(spawnedRoot:GetAttribute("NPCInvisibleRigHelper"), true, "spawned staged helper marked")
        Assert.truthy(spawnedBody.Transparency < 1, "spawned staged MeshPart remains visible")
        Assert.equals(record.Instance:GetAttribute("SourceAssetId"), "probe-staged-mesh", "spawned NPC preserves staged source asset id")
    end)
    if record and record.Instance then record.Instance:Destroy() end
    if marker then marker:Destroy() end
    if stagingRoot then stagingRoot:Destroy() end
    StagedMeshLibrary.StagingFolderName = oldStagingFolderName
    StagedMeshLibrary.SpeciesMesh.tyrannosaurus = oldTyrannosaurusEntry
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "NPC resolver rejects legacy primitive fallback candidates", run = function()
    local oldPaths = NPCSpawnService.NPCModelCandidatePaths.Prey
    local oldResolveAny = StagedMeshLibrary.ResolveAny
    local oldResolveModel = StagedMeshLibrary.ResolveModel
    local oldRecords = NPCService.NPCs
    local ok, err = pcall(function()
        withIsolatedImportedLibrary(function(library)
            local primitiveRoot = Instance.new("Folder")
            primitiveRoot.Name = "PrimitiveNPCFallbackProbe"
            primitiveRoot.Parent = library
            local hatchling = Instance.new("Model")
            hatchling.Name = "Hatchling"
            hatchling.Parent = primitiveRoot
            local block = Instance.new("Part")
            block.Name = "ThreePartBlockBody"
            block.Size = Vector3.new(2, 2, 4)
            block.Parent = hatchling
            hatchling.PrimaryPart = block

            NPCService.NPCs = {}
            StagedMeshLibrary.ResolveAny = function()
                return nil, "test_no_staged_mesh"
            end
            StagedMeshLibrary.ResolveModel = function()
                return nil, "test_no_staged_mesh"
            end
            NPCSpawnService.NPCModelCandidatePaths.Prey = {
                "ReplicatedStorage/ImportedAssetLibrary/PrimitiveNPCFallbackProbe/Hatchling",
            }

            local resolved = NPCSpawnService:ResolveImportedNPCModel("Prey")
            Assert.equals(resolved, nil, "primitive NPC fallback is rejected instead of spawning blocky dinos")
        end)
    end)
    NPCSpawnService.NPCModelCandidatePaths.Prey = oldPaths
    StagedMeshLibrary.ResolveAny = oldResolveAny
    StagedMeshLibrary.ResolveModel = oldResolveModel
    NPCService.NPCs = oldRecords
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "NPC resolver uses mesh child from 50 plus pack, not the whole pack root", run = function()
    local oldPaths = NPCSpawnService.NPCModelCandidatePaths.Predator
    local oldResolveAny = StagedMeshLibrary.ResolveAny
    local oldResolveModel = StagedMeshLibrary.ResolveModel
    local ok, err = pcall(function()
        withIsolatedImportedLibrary(function(library)
            local pack = Instance.new("Folder")
            pack.Name = "NPCSpawnValidation_AssetPackFixture"
            pack:SetAttribute("DinosaurRosterPack", true)
            pack:SetAttribute("UseAsDinoVisualHappyPath", true)
            pack.Parent = library
            local mesh = Instance.new("MeshPart")
            mesh.Name = "Velociraptor Mongoliensis"
            mesh.Size = Vector3.new(2, 4, 9)
            mesh.Parent = pack

            StagedMeshLibrary.ResolveAny = function()
                return nil, "test_no_staged_mesh"
            end
            StagedMeshLibrary.ResolveModel = function()
                return nil, "test_no_staged_mesh"
            end
            NPCSpawnService.NPCModelCandidatePaths.Predator = {}

            local resolved = NPCSpawnService:ResolveImportedNPCModel("Predator")
            Assert.equals(resolved, mesh, "fallback scan picks a mesh dino child, not the container pack")
        end)
    end)
    NPCSpawnService.NPCModelCandidatePaths.Predator = oldPaths
    StagedMeshLibrary.ResolveAny = oldResolveAny
    StagedMeshLibrary.ResolveModel = oldResolveModel
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "NPC resolver never uses bones or fossils as live dino fallback", run = function()
    local oldPaths = NPCSpawnService.NPCModelCandidatePaths.Predator
    local oldResolveAny = StagedMeshLibrary.ResolveAny
    local oldResolveModel = StagedMeshLibrary.ResolveModel
    local ok, err = pcall(function()
        withIsolatedImportedLibrary(function(library)
            local boneDisplay = Instance.new("Model")
            boneDisplay.Name = "Rex Skeleton Display"
            boneDisplay:SetAttribute("FossilDecoration", true)
            boneDisplay.Parent = library
            local boneMesh = Instance.new("MeshPart")
            boneMesh.Name = "RexSkeletonMesh"
            boneMesh.Size = Vector3.new(5, 3, 9)
            boneMesh.Parent = boneDisplay

            local liveMesh = Instance.new("MeshPart")
            liveMesh.Name = "Utahraptor Imported Mesh"
            liveMesh.Size = Vector3.new(3, 4, 10)
            liveMesh.Parent = library

            StagedMeshLibrary.ResolveAny = function()
                return nil, "test_no_staged_mesh"
            end
            StagedMeshLibrary.ResolveModel = function()
                return nil, "test_no_staged_mesh"
            end
            NPCSpawnService.NPCModelCandidatePaths.Predator = {}

            local resolved = NPCSpawnService:ResolveImportedNPCModel("Predator")
            Assert.equals(resolved, liveMesh, "bone/fossil meshes are skipped as live NPC bodies")
        end)
    end)
    NPCSpawnService.NPCModelCandidatePaths.Predator = oldPaths
    StagedMeshLibrary.ResolveAny = oldResolveAny
    StagedMeshLibrary.ResolveModel = oldResolveModel
    if not ok then error(err) end
end })

table.insert(suite.tests, { name = "authored NPC spawn markers cover prey and predators", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureNPCSpawnMarkers(folders)
    local prey = 0
    local predators = 0
    local aerialPrey = 0
    local aerialPredators = 0
    for _, marker in ipairs(folders.NPCSpawns:GetChildren()) do
        if marker:GetAttribute("NPCKind") == "Prey" then
            prey = prey + 1
        elseif marker:GetAttribute("NPCKind") == "Predator" then
            predators = predators + 1
        elseif marker:GetAttribute("NPCKind") == "AerialPrey" then
            aerialPrey = aerialPrey + 1
            Assert.equals(marker:GetAttribute("AerialSpawn"), true, marker.Name .. " marked as aerial spawn")
            Assert.truthy((marker:GetAttribute("PreferredAltitude") or 0) > 0, marker.Name .. " has preferred altitude")
        elseif marker:GetAttribute("NPCKind") == "AerialPredator" then
            aerialPredators = aerialPredators + 1
            Assert.equals(marker:GetAttribute("AerialSpawn"), true, marker.Name .. " marked as aerial predator spawn")
        end
        Assert.truthy(marker:GetAttribute("NPCSpawn") == true, marker.Name .. " marked as NPC spawn")
        Assert.truthy(type(marker:GetAttribute("ZoneId")) == "string", marker.Name .. " has zone id")
    end
    Assert.truthy(#folders.NPCSpawns:GetChildren() >= 12, "map has enough authored NPC spawn markers for live population")
    Assert.truthy(prey >= 6, "prey spawns exist across biomes")
    Assert.truthy(predators >= 4, "predator spawns exist outside nursery")
    Assert.truthy(aerialPrey >= 2, "aerial prey spawns exist near cliffs/canyons")
    Assert.truthy(aerialPredators >= 1, "pterodactyl/aerial predator spawn exists")
end })

table.insert(suite.tests, { name = "authored NPC spawns expose species and deferred food metadata", run = function()
    local folders = MapLayoutService:EnsureMapFolders()
    MapLayoutService:EnsureNPCSpawnMarkers(folders)

    local bySpecies = {}
    local liveFood = 0
    local defeatedFood = 0
    for _, marker in ipairs(folders.NPCSpawns:GetChildren()) do
        local kind = marker:GetAttribute("NPCKind")
        local speciesId = marker:GetAttribute("SpeciesId")
        Assert.truthy(type(speciesId) == "string" and speciesId ~= "", marker.Name .. " has source species expectation")
        Assert.equals(marker:GetAttribute("FoodSourceCandidate"), true, marker.Name .. " is audited as deferred food candidate")
        Assert.equals(marker:GetAttribute("FoodWhenDefeated"), true, marker.Name .. " can become food when defeated")
        Assert.truthy(type(marker:GetAttribute("CarnivoreFoodKind")) == "string", marker.Name .. " has carcass kind")
        Assert.truthy(type(marker:GetAttribute("GroundTopY")) == "number", marker.Name .. " has ground top for floating checks")
        Assert.equals(marker:GetAttribute("AvoidOverlap"), true, marker.Name .. " opts into overlap validation")
        bySpecies[speciesId] = (bySpecies[speciesId] or 0) + 1
        if marker:GetAttribute("PotentialCarnivoreFood") == true then
            liveFood = liveFood + 1
            Assert.truthy(kind == "Prey" or kind == "AerialPrey" or kind == "FlyingPrey", marker.Name .. " only live prey advertises carnivore food")
        end
        if marker:GetAttribute("FoodWhenDefeated") == true then defeatedFood = defeatedFood + 1 end
    end

    Assert.truthy((bySpecies.parasaurolophus or 0) >= 6, "parasaurolophus/prey has multiple relevant spawn points")
    Assert.truthy((bySpecies.utahraptor or 0) >= 4, "utahraptor/predator has multiple relevant spawn points")
    Assert.truthy(liveFood >= 6, "live prey NPCs are potential carnivore food")
    Assert.equals(defeatedFood, #folders.NPCSpawns:GetChildren(), "every authored NPC can produce defeated-food metadata")
end })

table.insert(suite.tests, { name = "spawn loop reaches visible world target from authored markers", run = function()
    MapLayoutService:EnsureSpawnSafety()
    local oldTarget = NPCSpawnService.TargetActive
    local oldRecords = NPCService.NPCs
    NPCService.NPCs = {}
    NPCSpawnService.TargetActive = 12
    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.truthy(active >= 12, "spawn loop reaches 12 active NPCs")
    local folder = workspace:FindFirstChild("NPCs")
    Assert.truthy(folder and #folder:GetChildren() >= 12, "visible NPC instances exist in Workspace.NPCs")
    local visibleDinosaurs = 0
    local carnivores = 0
    for _, npc in ipairs(folder:GetChildren()) do
        if npc:GetAttribute("NPCKind") == "Prey" or npc:GetAttribute("NPCKind") == "Predator" or npc:GetAttribute("NPCKind") == "AerialPrey" or npc:GetAttribute("NPCKind") == "AerialPredator" then
            if hasVisiblePart(npc) then visibleDinosaurs = visibleDinosaurs + 1 end
            if npc:GetAttribute("NPCKind") == "Predator" or npc:GetAttribute("NPCKind") == "AerialPredator" or npc:GetAttribute("Carnivore") == true or npc:GetAttribute("Diet") == "Carnivore" then
                carnivores = carnivores + 1
            end
        end
    end
    Assert.truthy(visibleDinosaurs >= 10, "at least 10 visible dinosaur NPCs exist")
    Assert.truthy(carnivores >= 4, "visible dinosaur population includes carnivores")
    NPCSpawnService.TargetActive = oldTarget
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "prey flees nearby players", run = function()
    local prey = Instance.new("Model")
    prey.Name = "FleePrey"
    prey:PivotTo(CFrame.new(0, 3, 0))
    prey.Parent = workspace
    local ok, record = NPCService:Register(prey, "Prey")
    Assert.truthy(ok, "prey registered")
    local player = { Character = Instance.new("Model") }
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(3, 3, 0)
    root.Parent = player.Character
    NPCService:TickNPCs({ player })
    Assert.equals(record.State, "Flee", "nearby player triggers flee")
    prey:Destroy()
end })


table.insert(suite.tests, { name = "active NPC brain moves prey and predators", run = function()
    local oldRecords = NPCService.NPCs
    NPCService.NPCs = {}

    local prey = Instance.new("Model")
    prey.Name = "BrainPrey"
    local preyRoot = Instance.new("Part")
    preyRoot.Name = "HumanoidRootPart"
    preyRoot.Size = Vector3.new(2, 2, 2)
    preyRoot.Parent = prey
    prey.PrimaryPart = preyRoot
    prey:PivotTo(CFrame.new(0, 3, 0))
    prey.Parent = workspace
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    Assert.truthy(preyOk, "prey registered for brain")

    local predator = Instance.new("Model")
    predator.Name = "BrainPredator"
    local predatorRoot = Instance.new("Part")
    predatorRoot.Name = "HumanoidRootPart"
    predatorRoot.Size = Vector3.new(2, 2, 2)
    predatorRoot.Parent = predator
    predator.PrimaryPart = predatorRoot
    predator:PivotTo(CFrame.new(40, 3, 0))
    predator.Parent = workspace
    local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
    Assert.truthy(predatorOk, "predator registered for brain")

    local player = { Character = Instance.new("Model") }
    local playerRoot = Instance.new("Part")
    playerRoot.Name = "HumanoidRootPart"
    playerRoot.Position = Vector3.new(6, 3, 0)
    playerRoot.Parent = player.Character

    local preyStart = NPCService:GetRecordPosition(preyRecord)
    local predatorStart = NPCService:GetRecordPosition(predatorRecord)
    local active = NPCService:TickNPCs({ player })
    Assert.truthy(active >= 2, "brain ticks both NPCs")
    Assert.equals(preyRecord.State, "Flee", "prey flees nearby player")
    Assert.equals(predatorRecord.State, "Chase", "predator chases player outside attack range")
    Assert.truthy((NPCService:GetRecordPosition(preyRecord) - preyStart).Magnitude > 0, "prey visibly moved")
    Assert.truthy((NPCService:GetRecordPosition(predatorRecord) - predatorStart).Magnitude > 0, "predator visibly moved")
    Assert.equals(prey:GetAttribute("ActiveNPCBrain"), true, "prey has active brain marker")
    Assert.truthy((prey:GetAttribute("BrainMoveCount") or 0) > 0, "prey brain movement count recorded")
    Assert.equals(predator:GetAttribute("LastBrainAction"), "Chase", "predator action marker set")
    Assert.truthy((predator:GetAttribute("BrainMoveCount") or 0) > 0, "predator brain movement count recorded")

    prey:Destroy()
    predator:Destroy()
    player.Character:Destroy()
    NPCService.NPCs = oldRecords
end })

table.insert(suite.tests, { name = "prey/danger spawns separated and hard cap exists", run = function()
    Assert.equals(NPCService.MaxActive, 30, "hard NPC cap")
    Assert.truthy(NPCSpawnService.TargetActive <= NPCService.MaxActive, "target active does not exceed hard cap")
    Assert.falsy(NPCService:CanChaseIntoZone("NurseryGrove", false), "predators cannot chase into nursery without scripted scare")
end })

TestRunner.registerSuite(suite)
return suite
