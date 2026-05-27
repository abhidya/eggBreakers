local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)

local suite = { name = "CharacterVisualServiceTests.server", category = "Integration", tests = {} }

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
                part.Name = segment .. "VisibleMesh"
                part.Size = Vector3.new(2, 2, 3)
                part.Parent = child
                child.PrimaryPart = part
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
    local state = SurvivalService:CreateState(player, "gallimimus")

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
    local state = SurvivalService:CreateState(player, "gallimimus")
    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "dinosaur visual applied")
    Assert.equals(mode, "dinosaur_model", "hatched state renders imported dinosaur model")
    Assert.equals(head.Transparency, 1, "default avatar remains hidden")
    local visual = character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName)
    Assert.notNil(visual, "dinosaur visual exists")
    Assert.truthy(visual:GetAttribute("ImportedVisual"), "dinosaur visual is imported asset clone")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible dinosaur replacement exists")
    cleanup(player)
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
    local character = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "gallimimus")
    state.Hatched = true
    state.SpeciesId = "missing_species"

    local ok, reason = CharacterVisualService:ApplyForState(player, state)

    Assert.falsy(ok, "release mode rejects generic dinosaur fallback")
    Assert.equals(reason, "fallback_disabled_in_release", "fallback disabled reason")
    cleanup(player)
end })

return TestRunner.registerSuite(suite)
