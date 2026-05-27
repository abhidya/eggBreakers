local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)

local suite = { name = "CharacterVisualServiceTests.server", category = "Integration", tests = {} }

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

table.insert(suite.tests, { name = "fresh player sees egg visual instead of default avatar", run = function()
    local player = MockPlayer.new(11001, "EggVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "gallimimus")

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "egg visual applied")
    Assert.equals(mode, "egg", "unhatched state renders egg")
    Assert.equals(head.Transparency, 1, "default avatar head hidden")
    Assert.notNil(character:FindFirstChild(CharacterVisualService.VisualFolderName), "game visual folder exists")
    Assert.notNil(character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.EggVisualName), "egg visual exists")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible egg replacement exists")
    cleanup(player)
end })

table.insert(suite.tests, { name = "hatched player sees dinosaur visual instead of default avatar", run = function()
    local player = MockPlayer.new(11002, "DinosaurVisualTester")
    local character, head = makeCharacter()
    player.Character = character
    local state = SurvivalService:CreateState(player, "gallimimus")
    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end

    local ok, mode = CharacterVisualService:ApplyForState(player, state)

    Assert.truthy(ok, "dinosaur visual applied")
    Assert.truthy(mode == "dinosaur_model" or mode == "dinosaur_fallback", "hatched state renders dinosaur visual")
    Assert.equals(head.Transparency, 1, "default avatar remains hidden")
    Assert.notNil(character[CharacterVisualService.VisualFolderName]:FindFirstChild(CharacterVisualService.DinosaurVisualName), "dinosaur visual exists")
    Assert.truthy(CharacterVisualService:HasVisibleGameVisual(character), "visible dinosaur replacement exists")
    cleanup(player)
end })

return TestRunner.registerSuite(suite)
