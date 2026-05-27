local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)

local suite = { name = "CharacterVisualServiceTests.server", category = "Integration", tests = {} }

local function characterFor(player)
    local character = Instance.new("Model")
    character.Name = player.Name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Parent = character
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Parent = character
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = character
    character.PrimaryPart = root
    player.Character = character
    character.Parent = workspace
    return character
end

table.insert(suite.tests, {
    name = "unhatched player sees egg visual not default avatar",
    run = function()
        local player = MockPlayer.new(90001, "EggVisualTester")
        local character = characterFor(player)
        local state = SurvivalService:CreateState(player, "gallimimus")
        local ok, visual = CharacterVisualService:ApplyForState(player, state)
        Assert.truthy(ok, "egg visual applied")
        Assert.notNil(visual, "visual model exists")
        Assert.equals(visual:GetAttribute("VisualKind"), "Egg", "unhatched visual is egg")
        Assert.equals(character.Head.Transparency, 1, "default avatar head hidden")
        character:Destroy()
    end,
})

table.insert(suite.tests, {
    name = "hatched player sees dinosaur visual not default avatar",
    run = function()
        local player = MockPlayer.new(90002, "DinoVisualTester")
        local character = characterFor(player)
        local state = SurvivalService:CreateState(player, "velociraptor")
        state.Hatched = true
        local ok, visual = CharacterVisualService:ApplyForState(player, state)
        Assert.truthy(ok, "dinosaur visual applied")
        Assert.notNil(visual, "visual model exists")
        Assert.truthy(tostring(visual:GetAttribute("VisualKind")):find("Dinosaur") ~= nil, "hatched visual is dinosaur")
        Assert.equals(character.Head.Transparency, 1, "default avatar head hidden")
        character:Destroy()
    end,
})

return suite
