local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)

local suite = { name = "E2E_MovementEatingLifecycle.server", category = "E2E", tests = {} }

local function makeNPC(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 2)
    root.Position = position or Vector3.new(0, 3, 0)
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model, root
end

table.insert(suite.tests, { name = "NPC ground movement and eating expose readable lifecycle state", run = function()
    local npc, root = makeNPC("E2EMovingEatingPrey", Vector3.new(0, 3, 0))
    local ok, record = NPCService:Register(npc, "Prey")
    Assert.truthy(ok, "prey NPC registers")
    record.Hatched = true
    record.Hunger = 20

    local target = Vector3.new(80, 24, 0)
    Assert.truthy(NPCService:MoveToward(record, target, 8, "SeekFood"), "NPC movement succeeds")
    Assert.equals(record.MovementSurface, "Ground", "ground prey reports ground movement")
    Assert.equals(npc:GetAttribute("MovementSurface"), "Ground", "NPC instance exposes movement surface")
    Assert.equals(npc:GetAttribute("GroundClampApplied"), true, "bad target height is clamped to ground plane")
    Assert.truthy(math.abs(root.Position.Y - 3) < 0.01, "ground movement does not dive/fly vertically")

    local food = Instance.new("Part")
    food.Name = "E2EReadableFern"
    food.Position = root.Position + Vector3.new(2, 0, 0)
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("FoodKind", "TreeBrowse")
    food:SetAttribute("Nutrition", 30)
    food.Parent = workspace
    CollectionService:AddTag(food, "FoodSource")

    Assert.truthy(NPCService:Eat(record, food), "NPC eats valid food")
    Assert.equals(npc:GetAttribute("EatingState"), "Browse", "NPC exposes readable eating verb")
    Assert.equals(npc:GetAttribute("EatTarget"), "E2EReadableFern", "NPC exposes eat target")
    Assert.equals(food:GetAttribute("LastEatAction"), "Browse", "food records readable bite verb")
    Assert.equals(food:GetAttribute("Depleted"), true, "food depletes after bite")

    food:Destroy()
    npc:Destroy()
end })

table.insert(suite.tests, { name = "player rest age and death lifecycle is E2E readable", run = function()
    local player = MockPlayer.new(49101, "RestAgeLoop")
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true
    state.Health = 25
    state.Stamina = 0

    Assert.truthy(SurvivalService:SetResting(player, true), "player enters rest")
    SurvivalService:ApplyNeedsTick(player, 4)
    Assert.equals(state.SleepState, "Resting", "resting sleep state visible")
    Assert.truthy((state.AgeSeconds or 0) >= 4, "age advances during rest")
    Assert.truthy(state.Stamina > 0, "stamina recovers during rest")
    Assert.truthy(state.Health > 25, "health recovers during rest")

    SurvivalService:Kill(player, "AgeLoopTest")
    Assert.equals(state.DeathState, "Dying", "dying state visible")
    Assert.equals(state.SleepState, "Dead", "dead sleep state visible")
    Assert.equals(state.DiedAtAgeSeconds, state.AgeSeconds, "death stamps current age")
end })

return suite
