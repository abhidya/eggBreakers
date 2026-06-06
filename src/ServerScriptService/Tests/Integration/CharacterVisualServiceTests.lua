local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local StagedMeshLibrary = require(ReplicatedStorage.Shared.StagedMeshLibrary)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)

local suite = { name = "CharacterVisualServiceTests.server", category = "Integration", tests = {} }

local function axisMax(vector)
    return math.max(vector.X, vector.Y, vector.Z)
end

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local function ensureModelPath(path)
    local current = game
    local parts = {}
    for segment in string.gmatch(path, "[^/]+") do
        table.insert(parts, segment)
    end
    for index, segment in ipairs(parts) do
        local child = current:FindFirstChild(segment)
        if not child then
            if index == #parts then
                child = Instance.new("Model")
                child.Name = segment
                local part = Instance.new("Part")
                part.Name = segment .. "VisibleBodyMesh"
                part.Size = Vector3.new(2, 2, 3)
                part.Parent = child
                child.PrimaryPart = part
                local head = Instance.new("Part")
                head.Name = segment .. "ReadableHeadMesh"
                head.Size = Vector3.new(1, 1, 1)
                head.CFrame = CFrame.new(0, 0, -3)
                head.Parent = child
                local tail = Instance.new("Part")
                tail.Name = segment .. "ReadableTailMesh"
                tail.Size = Vector3.new(1, 1, 3)
                tail.CFrame = CFrame.new(0, 0, 3)
                tail.Parent = child
            else
                child = Instance.new("Folder")
                child.Name = segment
            end
            child.Parent = current
        end
        current = child
    end
    return current
end

local function setupImportedVisuals()
    local library = ensureFolder(ReplicatedStorage, "ImportedAssetLibrary")
    local eggModel = ensureFolder(library, "Imported_Egg_Nest")
    local egg = eggModel:FindFirstChild("Egg") or Instance.new("Model")
    egg.Name = "Egg"
    egg.Parent = eggModel
    if not egg:FindFirstChild("EggMesh") then
        local part = Instance.new("Part")
        part.Name = "EggMesh"
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(3, 4, 3)
        part.Parent = egg
        egg.PrimaryPart = part
    end

    for _, species in pairs(SpeciesConfig) do
        for _, path in pairs(species.ModelPaths) do
            ensureModelPath(path)
        end
    end
    return library
end

local function makeCharacter()
    local character = Instance.new("Model")
    character.Name = "DefaultRobloxAvatar"
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Parent = character
    character.PrimaryPart = root
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Transparency = 0
    head.Parent = character
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = character
    character.Parent = workspace
    return character, head
end

local function cleanup(player)
    if player.Character then player.Character:Destroy() end
    SurvivalService.States[player] = nil
end

table.insert(suite.tests, { name = "fresh player sees imported egg visual instead of default avatar", run = function()
    setupImportedVisuals()
    local player = MockPlayer.new(11001, "EggVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "parasaurolophus")

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "imported egg visual applied")
    Assert.equals(mode, "imported_egg", "unhatched state renders imported egg")
    Assert.equals(head.Transparency, 1, "default avatar head hidden")
    Assert.notNil(character:FindFirstChild(CharacterVisualService.VisualFolderName), "game visual folder exists")
    local visual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.EggVisualName)
    Assert.notNil(visual, "egg visual exists")
    Assert.truthy(visual:GetAttribute("ImportedVisual"), "egg visual is imported asset clone")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible egg replacement exists")
    cleanup(player)
end })

table.insert(suite.tests, { name = "hatched player sees imported dinosaur visual instead of default avatar", run = function()
    setupImportedVisuals()
    local player = MockPlayer.new(11002, "DinosaurVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "dinosaur visual applied")
    Assert.truthy(mode == "dinosaur_model" or mode == "staged_dinosaur_mesh", "hatched state renders an imported dinosaur model (got " .. tostring(mode) .. ")")
    Assert.equals(head.Transparency, 1, "default avatar remains hidden")
    local visual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)
    Assert.notNil(visual, "dinosaur visual exists")
    Assert.truthy(visual:GetAttribute("ImportedVisual"), "dinosaur visual is imported asset clone")
    Assert.truthy((visual:GetAttribute("ReadableHeight") or 0) >= CharacterVisualService.MinimumDinosaurHeight, "dinosaur visual height is readable")
    Assert.truthy((visual:GetAttribute("ReadableLength") or 0) >= CharacterVisualService.MinimumDinosaurLength, "dinosaur visual length is readable")
    Assert.truthy((visual:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "imported dinosaur faces the HumanoidRootPart look direction")
    Assert.truthy(visual:GetAttribute("ForwardFacingVerified"), "forward-facing correction is verified from model geometry")
    local _, size = visual:GetBoundingBox()
    Assert.truthy(math.max(size.X, size.Y, size.Z) >= CharacterVisualService.MinimumDinosaurLength, "attached model preserves readable part offsets")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible dinosaur replacement exists")
    cleanup(player)
end })

table.insert(suite.tests, { name = "starter visual fallback hatches citipati into imported dinosaur", run = function()
    setupImportedVisuals()
    local player = MockPlayer.new(11022, "CitipatiVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "citipati")
    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "citipati starter visual fallback applied")
    Assert.truthy(mode == "dinosaur_model" or mode == "staged_dinosaur_mesh", "citipati renders as imported dinosaur proxy")
    Assert.equals(head.Transparency, 1, "default avatar hidden after citipati hatch")
    local visual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)
    Assert.notNil(visual, "citipati dinosaur visual exists")
    Assert.truthy(visual:GetAttribute("ImportedVisual"), "citipati proxy remains an imported asset clone")
    cleanup(player)
end })


table.insert(suite.tests, { name = "sideways and backwards imported dinosaurs are rotated to face player forward", run = function()
    local player = MockPlayer.new(11006, "DinosaurForwardProbe")
    local character = makeCharacter()
    player.Character = character
    character.HumanoidRootPart.CFrame = CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(0, 4, -10))

    local source = Instance.new("Model")
    source.Name = "SidewaysDinosaur"
    source.Parent = ReplicatedStorage
    local body = Instance.new("Part")
    body.Name = "SidewaysBody"
    body.Size = Vector3.new(2, 2, 3)
    body.Parent = source
    source.PrimaryPart = body
    local head = Instance.new("Part")
    head.Name = "SidewaysHead"
    head.Size = Vector3.new(1, 1, 1)
    head.CFrame = CFrame.new(4, 0, 0)
    head.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "SidewaysTail"
    tail.Size = Vector3.new(1, 1, 2)
    tail.CFrame = CFrame.new(-4, 0, 0)
    tail.Parent = source

    local clone = CharacterVisualService:_prepareDinosaurClone(source, { Growth = 0 })
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)

    Assert.notNil(attached, "sideways dinosaur attaches")
    Assert.truthy((attached:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "sideways source is rotated to face forward")
    Assert.truthy(attached:GetAttribute("ForwardFacingVerified"), "forward proof attr set")
    Assert.truthy(math.abs(attached:GetAttribute("ForwardCorrectionDegrees") or 0) >= 80, "non-zero yaw correction applied")

    CharacterVisualService:ClearVisual(character)
    local backwardSource = Instance.new("Model")
    backwardSource.Name = "BackwardDinosaur"
    backwardSource.Parent = ReplicatedStorage
    local backwardBody = Instance.new("Part")
    backwardBody.Name = "BackwardBody"
    backwardBody.Size = Vector3.new(2, 2, 3)
    backwardBody.Parent = backwardSource
    backwardSource.PrimaryPart = backwardBody
    local backwardHead = Instance.new("Part")
    backwardHead.Name = "BackwardHead"
    backwardHead.Size = Vector3.new(1, 1, 1)
    backwardHead.CFrame = CFrame.new(0, 0, 3)
    backwardHead.Parent = backwardSource
    local backwardTail = Instance.new("Part")
    backwardTail.Name = "BackwardTail"
    backwardTail.Size = Vector3.new(1, 1, 2)
    backwardTail.CFrame = CFrame.new(0, 0, -3)
    backwardTail.Parent = backwardSource

    local backwardClone = CharacterVisualService:_prepareDinosaurClone(backwardSource, { Growth = 0 })
    local backwardAttached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, backwardClone)

    Assert.notNil(backwardAttached, "backward dinosaur attaches")
    Assert.truthy((backwardAttached:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "backward source is rotated to face forward")
    Assert.truthy(backwardAttached:GetAttribute("ForwardFacingVerified"), "backward forward proof attr set")
    Assert.truthy(math.abs(backwardAttached:GetAttribute("ForwardCorrectionDegrees") or 0) >= 170, "backward yaw correction applied")
    source:Destroy()
    backwardSource:Destroy()
    cleanup(player)
end })

table.insert(suite.tests, { name = "face-down imported dinosaurs are auto-uprighted before forward correction", run = function()
    local player = MockPlayer.new(11016, "DinosaurAutoUprightProbe")
    local character = makeCharacter()
    player.Character = character
    character.HumanoidRootPart.CFrame = CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(0, 4, -10))

    local source = Instance.new("Model")
    source.Name = "RolledUnknownDinosaur"
    source.Parent = ReplicatedStorage
    local roll = CFrame.Angles(0, 0, math.rad(90))
    local rootPart = Instance.new("Part")
    rootPart.Name = "RootPart"
    rootPart.Size = Vector3.new(1, 1, 1)
    rootPart.Transparency = 1
    rootPart.Parent = source
    source.PrimaryPart = rootPart
    local body = Instance.new("Part")
    body.Name = "RolledBody"
    body.Size = Vector3.new(2, 2, 4)
    body.CFrame = CFrame.new(0, 0, 0) * roll
    body.Parent = source
    local head = Instance.new("Part")
    head.Name = "RolledHead"
    head.Size = Vector3.new(1, 1, 1)
    head.CFrame = CFrame.new(0, 0, -4) * roll
    head.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "RolledTail"
    tail.Size = Vector3.new(1, 1, 2)
    tail.CFrame = CFrame.new(0, 0, 4) * roll
    tail.Parent = source

    local clone = CharacterVisualService:_prepareDinosaurClone(source, { SpeciesId = "unknown", Growth = 0 })
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)
    local attachedBody = attached and attached:FindFirstChild("RolledBody", true)

    Assert.notNil(attached, "rolled dinosaur visual attaches")
    Assert.equals(attached:GetAttribute("AutoUprightApplied"), true, "generic auto-upright correction applied")
    Assert.truthy(attached:GetAttribute("UprightVerified"), "auto-upright verification attr set")
    Assert.truthy(attachedBody and attachedBody.CFrame.UpVector:Dot(character.HumanoidRootPart.CFrame.UpVector) >= 0.82, "rolled body is upright")
    Assert.truthy((attached:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "auto-uprighted dinosaur still faces forward")

    source:Destroy()
    cleanup(player)
end })


table.insert(suite.tests, { name = "utahraptor imported visual is corrected upright and forward", run = function()
    local player = MockPlayer.new(11007, "UtahraptorUprightProbe")
    local character = makeCharacter()
    player.Character = character
    character.HumanoidRootPart.CFrame = CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(0, 4, -10))
    local oldUtahraptor = SpeciesConfig.utahraptor
    SpeciesConfig.utahraptor = {
        SpeciesId = "utahraptor",
        VisualOrientationCorrection = { PitchDegrees = 180, ForceUpright = true, Reason = "test_imported_pack_axis" },
    }

    local source = Instance.new("Model")
    source.Name = "UpsideDownUtahraptor"
    source.Parent = ReplicatedStorage
    local body = Instance.new("Part")
    body.Name = "UtahraptorBody"
    body.Size = Vector3.new(2, 2, 4)
    body.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(180), 0, 0)
    body.Parent = source
    source.PrimaryPart = body
    local head = Instance.new("Part")
    head.Name = "UtahraptorHead"
    head.Size = Vector3.new(1, 1, 1)
    head.CFrame = CFrame.new(0, 0, -4) * CFrame.Angles(math.rad(180), 0, 0)
    head.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "UtahraptorTail"
    tail.Size = Vector3.new(1, 1, 2)
    tail.CFrame = CFrame.new(0, 0, 4) * CFrame.Angles(math.rad(180), 0, 0)
    tail.Parent = source

    local clone = CharacterVisualService:_prepareDinosaurClone(source, { SpeciesId = "utahraptor", Growth = 0 })
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)
    local attachedBody = attached and attached:FindFirstChild("UtahraptorBody", true)

    Assert.notNil(attached, "utahraptor visual attaches")
    Assert.truthy(attached:GetAttribute("SpeciesOrientationCorrected") == true or attached:GetAttribute("AutoUprightApplied") == true, "utahraptor upright correction applied")
    Assert.truthy(attached:GetAttribute("UprightVerified"), "utahraptor upright verification attr set")
    Assert.truthy(attachedBody and attachedBody.CFrame.UpVector:Dot(character.HumanoidRootPart.CFrame.UpVector) >= 0.92, "utahraptor body is upright after correction")
    Assert.truthy((attached:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "utahraptor still faces player forward")
    Assert.truthy(attached:GetAttribute("ForwardFacingVerified"), "forward-facing proof remains verified")
    SpeciesConfig.utahraptor = oldUtahraptor
    source:Destroy()
    cleanup(player)
end })


table.insert(suite.tests, { name = "utahraptor force-upright recovers when static pitch over-rotates", run = function()
    local player = MockPlayer.new(11008, "UtahraptorForceUprightProbe")
    local character = makeCharacter()
    player.Character = character
    character.HumanoidRootPart.CFrame = CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(0, 4, -10))
    local oldUtahraptor = SpeciesConfig.utahraptor
    SpeciesConfig.utahraptor = {
        SpeciesId = "utahraptor",
        VisualOrientationCorrection = { PitchDegrees = 180, ForceUpright = true, Reason = "test_imported_pack_axis" },
    }

    local source = Instance.new("Model")
    source.Name = "AlreadyUprightUtahraptor"
    source.Parent = ReplicatedStorage
    local body = Instance.new("Part")
    body.Name = "UtahraptorBody"
    body.Size = Vector3.new(2, 2, 4)
    body.CFrame = CFrame.new(0, 0, 0)
    body.Parent = source
    source.PrimaryPart = body
    local head = Instance.new("Part")
    head.Name = "UtahraptorHead"
    head.Size = Vector3.new(1, 1, 1)
    head.CFrame = CFrame.new(0, 0, -4)
    head.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "UtahraptorTail"
    tail.Size = Vector3.new(1, 1, 2)
    tail.CFrame = CFrame.new(0, 0, 4)
    tail.Parent = source

    local clone = CharacterVisualService:_prepareDinosaurClone(source, { SpeciesId = "utahraptor", Growth = 0 })
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)
    local attachedBody = attached and attached:FindFirstChild("UtahraptorBody", true)

    Assert.notNil(attached, "upright utahraptor visual attaches")
    Assert.truthy(attached:GetAttribute("SpeciesOrientationCorrected") == true or attached:GetAttribute("AutoUprightApplied") == true, "utahraptor correction path applied")
    Assert.truthy((attached:GetAttribute("UprightDotBeforeCorrection") or attached:GetAttribute("AutoUprightDotBefore") or 1) < 0.82, "static over-rotation was detected")
    Assert.truthy(attached:GetAttribute("UprightVerified"), "force-upright restored visual orientation")
    Assert.truthy(attachedBody and attachedBody.CFrame.UpVector:Dot(character.HumanoidRootPart.CFrame.UpVector) >= 0.92, "body remains upright after force-upright")
    Assert.truthy((attached:GetAttribute("ForwardFacingDot") or 0) >= 0.92, "forward correction still succeeds after force-upright")
    SpeciesConfig.utahraptor = oldUtahraptor
    source:Destroy()
    cleanup(player)
end })

table.insert(suite.tests, { name = "growth progress makes dinosaur visual larger", run = function()
    setupImportedVisuals()
    local player = MockPlayer.new(11005, "GrowthScaleVisualTester")
    local character = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.Growth = 0

    local ok = CharacterVisualService:ApplyForState(player, state)
    Assert.truthy(ok, "base dinosaur visual applied")
    local baseVisual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)
    local _, baseSize = baseVisual:GetBoundingBox()

    state.Growth = 25
    ok = CharacterVisualService:ApplyForState(player, state)
    Assert.truthy(ok, "grown dinosaur visual applied")
    local grownVisual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)
    local _, grownSize = grownVisual:GetBoundingBox()

    Assert.truthy(grownVisual:GetAttribute("GrowthVisualScale") > 1, "growth visual scale recorded")
    Assert.truthy(axisMax(grownSize) > axisMax(baseSize), "grown visual is larger than hatchling visual")
    cleanup(player)
end })

table.insert(suite.tests, { name = "oversized staged hatchlings are scaled down to hatchling readable size", run = function()
    local source = Instance.new("Model")
    source.Name = "OversizedParasaurolophusSource"
    source.Parent = ReplicatedStorage
    local body = Instance.new("Part")
    body.Name = "ParasaurolophusBodyMesh"
    body.Size = Vector3.new(10, 24, 46)
    body.Parent = source
    source.PrimaryPart = body

    local hatchling = CharacterVisualService:_prepareDinosaurClone(source, {
        SpeciesId = "parasaurolophus",
        GrowthStage = "Hatchling",
        Growth = 0,
    })
    local hatchlingLength = hatchling:GetAttribute("ReadableLength")
    local hatchlingHeight = hatchling:GetAttribute("ReadableHeight")

    Assert.truthy(hatchlingLength <= CharacterVisualService.TargetDinosaurLengthByStage.Hatchling + 0.25, "hatchling visual is not adult-sized")
    Assert.truthy(hatchlingHeight >= CharacterVisualService.MinimumDinosaurHeight, "hatchling remains readable after downscale")
    Assert.truthy((hatchling:GetAttribute("ReadableScaleApplied") or 1) < 1, "oversized staged source was downscaled")

    local adult = CharacterVisualService:_prepareDinosaurClone(source, {
        SpeciesId = "parasaurolophus",
        GrowthStage = "Adult",
        Growth = 0,
    })
    Assert.truthy((adult:GetAttribute("ReadableLength") or 0) > hatchlingLength, "adult visual remains larger than hatchling")

    hatchling:Destroy()
    adult:Destroy()
    source:Destroy()
end })

table.insert(suite.tests, { name = "release validation fails when imported visuals are missing", run = function()
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    local originalParent = library and library.Parent
    if library then library.Parent = nil end
    local result = CharacterVisualService:ValidateReleaseVisualAssets()
    if library then library.Parent = originalParent end
    Assert.falsy(result.passed, "release validation must fail without imported egg/dinosaur assets")
    Assert.truthy(#result.failures >= 1, "release validation reports failures")
end })

table.insert(suite.tests, { name = "debug fallback is disabled for release ApplyForState", run = function()
    local player = MockPlayer.new(11003, "NoFallbackTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.SpeciesId = "missing_species"

    local ok, reason = CharacterVisualService:ApplyForState(player, state)

    Assert.falsy(ok, "release mode rejects generic dinosaur fallback")
    Assert.equals(reason, "fallback_disabled_in_release", "fallback disabled reason")
    Assert.equals(head.Transparency, 0, "default avatar stays visible when no replacement exists")
    Assert.equals(character:GetAttribute("CharacterVisualApplyFailed"), true, "visual failure is recorded")
    Assert.equals(character:GetAttribute("CharacterVisualFailureReason"), "fallback_disabled_in_release", "visual failure reason is recorded")
    Assert.equals(character:FindFirstChild(CharacterVisualService.VisualFolderName), nil, "failed visual apply does not leave an empty replacement folder")
    cleanup(player)
end })

table.insert(suite.tests, { name = "staged mesh library resolves imported dinosaur storage fallback", run = function()
    local workspaceRoot = workspace:FindFirstChild(StagedMeshLibrary.StagingFolderName)
    local workspaceRootParent = workspaceRoot and workspaceRoot.Parent
    if workspaceRoot then
        workspaceRoot.Parent = nil
    end

    local library = ensureFolder(ReplicatedStorage, "ImportedAssetLibrary")
    local root = ensureFolder(library, StagedMeshLibrary.StagingFolderName)
    local carnivores = ensureFolder(root, "Carnivores (land)")
    local coelophysis = carnivores:FindFirstChild("Coelophysis") or Instance.new("Model")
    coelophysis.Name = "Coelophysis"
    coelophysis.Parent = carnivores
    if not coelophysis:FindFirstChild("CoelophysisBodyMesh") then
        local body = Instance.new("Part")
        body.Name = "CoelophysisBodyMesh"
        body.Size = Vector3.new(2, 3, 8)
        body.Parent = coelophysis
        coelophysis.PrimaryPart = body
    end

    StagedMeshLibrary:RefreshRoster()
    local resolved, reason = StagedMeshLibrary:ResolveAny("coelophysis")

    Assert.equals(resolved, coelophysis, "staged library resolves ReplicatedStorage imported dinosaur root")
    Assert.equals(reason, nil, "staged fallback resolves without a failure reason")

    root:Destroy()
    if workspaceRoot then
        workspaceRoot.Parent = workspaceRootParent
    end
    StagedMeshLibrary:RefreshRoster()
end })

table.insert(suite.tests, { name = "50 plus asset pack species hatches into mesh visual", run = function()
    setupImportedVisuals()
    local library = ensureFolder(ReplicatedStorage, "ImportedAssetLibrary")
    local oldAllosaurus = StagedMeshLibrary.AssetPackSpecies.allosaurus

    local pack = Instance.new("Folder")
    pack.Name = "CharacterVisual_AssetPackFixture"
    pack.Parent = library
    local allosaurus = Instance.new("MeshPart")
    allosaurus.Name = "Allosaurus"
    allosaurus.Size = Vector3.new(5, 9, 18)
    allosaurus:SetAttribute("SourceAssetId", "8289268262")
    allosaurus.Parent = pack
    StagedMeshLibrary.AssetPackSpecies.allosaurus = {
        folder = "Carnivores (land)",
        name = "Allosaurus",
        sourceFolder = pack.Name,
        sourceName = "Allosaurus",
        sourceAssetId = "8289268262",
    }

    local player = MockPlayer.new(11023, "AllosaurusVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "allosaurus")
    state.Hatched = true
    state.GrowthStage = "Hatchling"

    local testOk, err = pcall(function()
        local ok, mode = CharacterVisualService:ApplyForState(player, state)
        local visual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)

        Assert.truthy(ok, "asset-pack mesh species visual applied")
        Assert.equals(mode, "staged_dinosaur_mesh", "asset-pack mesh follows staged dinosaur path")
        Assert.equals(head.Transparency, 1, "default avatar is hidden only after mesh replacement exists")
        Assert.notNil(visual, "asset-pack dinosaur visual exists")
        Assert.truthy(visual:IsA("MeshPart"), "asset-pack visual remains a MeshPart, not a Lego block model")
        Assert.equals(visual:GetAttribute("VisualKind"), "ImportedDinosaur", "mesh visual is stamped as imported dinosaur")
        Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible mesh replacement exists")
    end)

    StagedMeshLibrary.AssetPackSpecies.allosaurus = oldAllosaurus
    pack:Destroy()
    cleanup(player)
    if not testOk then error(err) end
end })


table.insert(suite.tests, { name = "avatar hide preserves existing imported dinosaur visual", run = function()
    local character, head = makeCharacter()
    local folder = Instance.new("Folder")
    folder.Name = CharacterVisualService.VisualFolderName
    folder.Parent = character
    local visual = Instance.new("Model")
    visual.Name = CharacterVisualService.DinosaurVisualName
    visual:SetAttribute("EggBreakersVisual", true)
    visual:SetAttribute("ImportedVisual", true)
    visual.Parent = folder
    local body = Instance.new("Part")
    body.Name = "ImportedDinoBody"
    body.Transparency = 0
    body.Parent = visual

    CharacterVisualService:HideDefaultAvatar(character)

    Assert.equals(head.Transparency, 1, "default avatar hidden")
    Assert.equals(body.Transparency, 0, "imported dinosaur remains visible")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible imported dinosaur survives avatar hiding")
    character:Destroy()
end })

table.insert(suite.tests, { name = "staged rig helper root remains invisible after attach", run = function()
    local player = MockPlayer.new(11009, "RigHelperTransparencyProbe")
    local character = makeCharacter()
    player.Character = character

    local source = Instance.new("Model")
    source.Name = "StagedRigWithLargeRoot"
    source.Parent = ReplicatedStorage
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(34, 42, 28)
    root.Transparency = 1
    root.Parent = source
    source.PrimaryPart = root
    local body = Instance.new("Part")
    body.Name = "UtahraptorBodyMesh"
    body.Size = Vector3.new(5, 4, 12)
    body.CFrame = CFrame.new(0, 0, -4)
    body.Transparency = 0.2
    body.Parent = source
    local head = Instance.new("Part")
    head.Name = "UtahraptorHeadMesh"
    head.Size = Vector3.new(3, 3, 4)
    head.CFrame = CFrame.new(0, 1, -11)
    head.Transparency = 0.2
    head.Parent = source
    local motor = Instance.new("Motor6D")
    motor.Name = "BodyRigMotor"
    motor.Part0 = root
    motor.Part1 = body
    motor.Parent = root

    local clone = CharacterVisualService:_prepareDinosaurClone(source, { SpeciesId = "utahraptor", Growth = 0 })
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)
    local attachedRoot = attached and attached:FindFirstChild("RootPart", true)
    local attachedBody = attached and attached:FindFirstChild("UtahraptorBodyMesh", true)

    Assert.notNil(attached, "staged rig attaches")
    Assert.equals(attachedRoot.Transparency, 1, "large rig RootPart stays invisible")
    Assert.equals(attachedRoot.CanCollide, false, "large rig RootPart cannot collide")
    Assert.equals(attachedRoot.CanQuery, false, "large rig RootPart cannot block queries")
    Assert.truthy(attachedBody.Transparency < 1, "renderable mesh body remains visible")

    source:Destroy()
    cleanup(player)
end })

table.insert(suite.tests, { name = "folder based imported dinosaur stays readable after attach", run = function()
    local player = MockPlayer.new(11004, "FolderDinoVisualTester")
    local character = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true

    local source = Instance.new("Folder")
    source.Name = "ImportedFolderDinosaur"
    source.Parent = ReplicatedStorage
    local body = Instance.new("Part")
    body.Name = "FolderDinoBody"
    body.Size = Vector3.new(1, 1, 2)
    body.CFrame = CFrame.new(0, 0, 0)
    body.Parent = source
    local tail = Instance.new("Part")
    tail.Name = "FolderDinoTail"
    tail.Size = Vector3.new(1, 1, 2)
    tail.CFrame = CFrame.new(0, 0, 2)
    tail.Parent = source

    local clone = CharacterVisualService:_prepareDinosaurClone(source)
    local attached = CharacterVisualService:_attachModel(character, character.HumanoidRootPart, clone)

    Assert.notNil(attached, "folder visual attaches")
    Assert.truthy((attached:GetAttribute("ReadableLength") or 0) >= CharacterVisualService.MinimumDinosaurLength, "folder visual was scaled to readable length")
    local parts = attached:GetDescendants()
    local minZ, maxZ = math.huge, -math.huge
    for _, descendant in ipairs(parts) do
        if descendant:IsA("BasePart") then
            minZ = math.min(minZ, descendant.Position.Z - descendant.Size.Z / 2)
            maxZ = math.max(maxZ, descendant.Position.Z + descendant.Size.Z / 2)
        end
    end
    Assert.truthy((maxZ - minZ) >= CharacterVisualService.MinimumDinosaurLength, "folder attach preserves part offsets instead of collapsing into a block")
    source:Destroy()
    cleanup(player)
end })

return TestRunner.registerSuite(suite)
