local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local WaterService = require(game:GetService("ServerScriptService").Services.WaterService)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local CityDiscoveryService = require(game:GetService("ServerScriptService").Services.CityDiscoveryService)
local FossilService = require(game:GetService("ServerScriptService").Services.FossilService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)

local suite = { name = "E2E_PlayableLoopClosure.server", category = "E2E", tests = {} }


local function ensureCarcassAsset()
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = game:GetService("ReplicatedStorage")
    end
    local asset = library:FindFirstChild("PlayableLoopBoneRemains")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "PlayableLoopBoneRemains"
        asset.Size = Vector3.new(4, 1, 2)
        asset.Parent = library
    end
    return asset
end

local function rootFor(player, position)
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = position or Vector3.new(0, 3, 0)
    local character = Instance.new("Model")
    root.Parent = character
    player.Character = character
    return root
end

local function makeNPC(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(2, 2, 2)
    root.Position = position or Vector3.new(0, 3, 0)
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model
end

local function resetNPCs()
    NPCService.NPCs = {}
end

table.insert(suite.tests, { name = "hatched player can sprint after egg movement is locked", run = function()
    local player = MockPlayer.new(49002, "LoopMovement")
    RateLimitService:ClearPlayer(player)
    rootFor(player)

    local state = SurvivalService:CreateState(player, "utahraptor")
    local eggSprintOk = SurvivalService:SetSprinting(player, true)
    Assert.falsy(eggSprintOk, "egg cannot sprint before hatch")

    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end
    local sprintOk = SurvivalService:SetSprinting(player, true)
    Assert.truthy(sprintOk, "hatched player can sprint")
    Assert.equals(state.Sprinting, true, "sprint state is readable")
    Assert.truthy(state.CurrentWalkSpeed > SpeciesConfig.utahraptor.BaseStats.Hatchling.WalkSpeed, "sprint increases movement speed")

    SurvivalService:SetSprinting(player, false)
    Assert.equals(state.Sprinting, false, "sprint can stop")
end })

table.insert(suite.tests, { name = "nearby NPCs react to food events in playable loop", run = function()
    resetNPCs()
    local eater = makeNPC("LoopReactionEatingPreyNPC", Vector3.new(0, 3, 0))
    local bystander = makeNPC("LoopReactionBystanderPreyNPC", Vector3.new(12, 3, 0))
    local food = Instance.new("Part")
    food.Name = "LoopReactionFern"
    food.Position = Vector3.new(4, 3, 0)
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 20)
    food.Parent = workspace
    CollectionService:AddTag(food, "FoodSource")

    local _, eaterRecord = NPCService:Register(eater, "Prey")
    local _, bystanderRecord = NPCService:Register(bystander, "Prey")
    eaterRecord.Hatched = true
    bystanderRecord.Hatched = true

    NPCService:Eat(eaterRecord, food)
    Assert.equals(bystander:GetAttribute("LastReaction"), "FoodSignal", "nearby NPC notices food event")
    Assert.equals(bystander:GetAttribute("NearbyFoodTarget"), "LoopReactionFern", "food target is stamped on bystander")
    Assert.equals(eater:GetAttribute("FoodSignalReactionAffected"), 1, "food reaction affected count is stamped")

    eater:Destroy(); bystander:Destroy(); food:Destroy()
    resetNPCs()
end })

table.insert(suite.tests, { name = "nearby NPCs react to fight events in playable loop", run = function()
    resetNPCs()
    local bystander = makeNPC("LoopFightBystanderPreyNPC", Vector3.new(12, 3, 0))
    local predator = makeNPC("LoopFightPredatorNPC", Vector3.new(3, 3, 0))
    local prey = makeNPC("LoopFightPreyNPC", Vector3.new(6, 3, 0))

    local _, bystanderRecord = NPCService:Register(bystander, "Prey")
    local _, predatorRecord = NPCService:Register(predator, "Predator")
    local _, preyRecord = NPCService:Register(prey, "Prey")
    bystanderRecord.Hatched = true
    predatorRecord.Hatched = true
    preyRecord.Hatched = true
    preyRecord.Health = 80

    NPCService:AttackRecord(predatorRecord, preyRecord)
    Assert.equals(predator:GetAttribute("FightEventState"), "Attacking", "attacker fight state is stamped")
    Assert.equals(prey:GetAttribute("FightEventState"), "Hit", "target fight state is stamped")
    Assert.equals(bystander:GetAttribute("LastReaction"), "FightSignal", "nearby NPC notices fight event")
    Assert.equals(bystander:GetAttribute("NearbyFightTarget"), "LoopFightPreyNPC", "fight target is stamped on bystander")

    bystander:Destroy(); predator:Destroy(); prey:Destroy()
    resetNPCs()
end })

table.insert(suite.tests, { name = "nearby same-species NPCs react to mating events in playable loop", run = function()
    resetNPCs()
    local first = makeNPC("LoopMateFirstOviraptorNPC", Vector3.new(0, 3, 0))
    local second = makeNPC("LoopMateSecondOviraptorNPC", Vector3.new(12, 3, 0))
    local bystander = makeNPC("LoopMateBystanderOviraptorNPC", Vector3.new(50, 3, 0))

    local _, firstRecord = NPCService:Register(first, "Omnivore")
    local _, secondRecord = NPCService:Register(second, "Omnivore")
    local _, bystanderRecord = NPCService:Register(bystander, "Omnivore")
    firstRecord.Hatched = true
    secondRecord.Hatched = true
    bystanderRecord.Hatched = true
    firstRecord.Hunger = 90
    firstRecord.Thirst = 90
    secondRecord.Hunger = 90
    secondRecord.Thirst = 90
    bystanderRecord.Hunger = 90
    bystanderRecord.Thirst = 90
    firstRecord.Herding = false
    secondRecord.Herding = false
    bystanderRecord.Herding = false

    NPCService:TickBrain(firstRecord, {}, 1)
    Assert.equals(firstRecord.State, "Mate", "healthy matching NPC enters mating beat")
    Assert.equals(first:GetAttribute("MateTarget"), "LoopMateSecondOviraptorNPC", "mating target is stamped")
    Assert.equals(bystander:GetAttribute("LastReaction"), "MateSignal", "nearby same-species NPC notices mating event")
    Assert.equals(bystander:GetAttribute("ReactionIntent"), "SocialMate", "mating reaction records social intent")

    NPCService:TickBrain(bystanderRecord, {}, 1)
    Assert.equals(bystanderRecord.State, "Mate", "mating signal pulls bystander into social beat")
    Assert.equals(bystander:GetAttribute("ReactionConsumed"), "Mate", "mating reaction is consumed by movement")

    first:Destroy(); second:Destroy(); bystander:Destroy()
    resetNPCs()
end })

table.insert(suite.tests, { name = "validated shallow water is drinkable while deep water is not", run = function()
    local player = MockPlayer.new(49003, "LoopWater")
    RateLimitService:ClearPlayer(player)
    rootFor(player)
    local state = SurvivalService:CreateState(player, "parasaurolophus")
    state.Hatched = true

    local shallow = Instance.new("Part")
    shallow.Name = "LoopDrinkableShallowWater"
    shallow.Size = Vector3.new(18, 4, 18)
    shallow.Position = Vector3.new(2, 3, 0)
    shallow.Parent = workspace
    CollectionService:AddTag(shallow, "WaterSource")

    local deep = Instance.new("Part")
    deep.Name = "LoopDeepSwimWater"
    deep.Size = Vector3.new(18, 10, 18)
    deep.Position = Vector3.new(2, 3, 0)
    deep.Parent = workspace
    CollectionService:AddTag(deep, "WaterSource")

    WaterService:ValidateAllWaterSources()
    Assert.truthy(CollectionService:HasTag(shallow, "DrinkableWater"), "shallow water is tagged drinkable")
    Assert.falsy(CollectionService:HasTag(deep, "DrinkableWater"), "deep water is not tagged drinkable")

    state.Thirst = 30
    Assert.truthy(FoodWaterService:RequestDrink(player, shallow), "validated shallow water restores thirst")
    RateLimitService:ClearPlayer(player)
    local deepOk = FoodWaterService:RequestDrink(player, deep)
    Assert.falsy(deepOk, "deep water is rejected as a drink target")

    shallow:Destroy(); deep:Destroy()
end })

table.insert(suite.tests, { name = "hostile NPC fights back when player is in attack range", run = function()
    resetNPCs()
    local player = MockPlayer.new(49004, "LoopFightBack")
    RateLimitService:ClearPlayer(player)
    rootFor(player, Vector3.new(0, 3, 0))
    local state = SurvivalService:CreateState(player, "utahraptor")
    state.Hatched = true

    local predator = makeNPC("LoopFightBackPredatorNPC", Vector3.new(3, 3, 0))
    local _, predatorRecord = NPCService:Register(predator, "Predator")
    predatorRecord.Hatched = true

    Assert.truthy(NPCService:RunPredatorBrain(predatorRecord, { player }), "predator brain responds to nearby player")
    Assert.equals(predatorRecord.State, "Attack", "hostile NPC enters attack state")
    Assert.equals(predator:GetAttribute("AttackRangeConfirmed"), true, "hostile NPC confirms attack range")

    predator:Destroy()
    resetNPCs()
end })

table.insert(suite.tests, { name = "fresh player egg to death respawn loop is server authoritative", run = function()
    resetNPCs()
    local player = MockPlayer.new(49001, "LoopClosure")
    RateLimitService:ClearPlayer(player)
    PlayerDataService:Get(player)
    local root = rootFor(player)

    local state = SurvivalService:CreateState(player, "utahraptor")
    local eggFood = Instance.new("Part")
    eggFood.Position = Vector3.new(2, 3, 0)
    eggFood:SetAttribute("Diet", "Carnivore")
    eggFood:SetAttribute("Nutrition", 25)
    eggFood.Parent = workspace
    CollectionService:AddTag(eggFood, "FoodSource")
    local eggOk = FoodWaterService:RequestEat(player, eggFood)
    Assert.falsy(eggOk, "egg cannot eat before hatch")

    for _ = 1, 5 do SurvivalService:RequestHatch(player, "tap") end
    Assert.equals(state.Hatched, true, "egg hatches")

    state.Hunger = 40
    RateLimitService:ClearPlayer(player)
    Assert.truthy(FoodWaterService:RequestEat(player, eggFood), "hatched player eats")
    Assert.truthy(state.Hunger > 40, "food restores hunger")
    eggFood:SetAttribute("DepletedUntil", os.time() - 1)
    FoodWaterService:RefreshDepletion(eggFood)
    Assert.equals(eggFood:GetAttribute("Depleted"), false, "food respawns after cooldown")

    local water = Instance.new("Part")
    water.Position = Vector3.new(2, 3, 0)
    water.Parent = workspace
    CollectionService:AddTag(water, "WaterSource")
    state.Thirst = 35
    RateLimitService:ClearPlayer(player)
    Assert.truthy(FoodWaterService:RequestDrink(player, water), "drink succeeds")
    Assert.truthy(state.Thirst > 35, "water restores thirst")

    state.Stamina = 0
    SurvivalService:ApplyNeedsTick(player, 2)
    Assert.truthy(state.Stamina > 0, "server tick regens stamina")
    SurvivalService:AddGrowth(player, 25)
    Assert.equals(state.GrowthStage, "Juvenile", "growth reaches juvenile")

    local ageBeforeRest = state.AgeSeconds or 0
    state.Health = math.max(1, state.Health - 10)
    state.Stamina = 0
    Assert.truthy(SurvivalService:SetResting(player, true), "rest starts")
    SurvivalService:ApplyNeedsTick(player, 2)
    Assert.equals(state.SleepState, "Resting", "rest/sleep state is readable")
    Assert.truthy((state.AgeSeconds or 0) > ageBeforeRest, "age advances during survival loop")
    Assert.truthy(state.Stamina > 0, "rest restores stamina")
    Assert.truthy(state.Health > 0, "rest keeps recovery state alive")
    Assert.truthy(SurvivalService:SetResting(player, false), "rest stops")
    Assert.equals(state.SleepState, "Awake", "sleep state returns to awake")

    local prey = Instance.new("Part")
    prey.Name = "DamageablePrey"
    prey.Position = Vector3.new(5, 3, 0)
    prey:SetAttribute("Health", 10)
    prey.Parent = workspace
    CollectionService:AddTag(prey, "Damageable")
    RateLimitService:ClearPlayer(player)
    local playerSpecies = SpeciesConfig[state.SpeciesId]
    local playerAttack = playerSpecies.Abilities.PrimaryAttack
    Assert.truthy(CombatService:RequestAttack(player, playerAttack, prey), "attack succeeds")
    Assert.truthy(prey:GetAttribute("Health") < 10, "real damage reduces health")

    ensureCarcassAsset()
    local preyModel = Instance.new("Model")
    preyModel.Name = "LoopPreyNPC"
    local preyRoot = Instance.new("Part")
    preyRoot.Name = "Root"
    preyRoot.Size = Vector3.new(2, 2, 2)
    preyRoot.Position = Vector3.new(3, 3, 0)
    preyRoot.Parent = preyModel
    preyModel.PrimaryPart = preyRoot
    preyModel.Parent = workspace
    local registered, record = NPCService:Register(preyModel, "Prey")
    Assert.truthy(registered, "NPC prey registered")
    Assert.truthy(CollectionService:HasTag(preyModel, "Damageable"), "registered NPC is damageable for player attacks")
    NPCService:TickNPCs({ player })
    Assert.equals(record.State, "Flee", "prey flees player")

    record.Health = 1
    state.Stamina = 100
    root.Position = preyRoot.Position + Vector3.new(2, 0, 0)
    RateLimitService:ClearPlayer(player)
    Assert.truthy(CombatService:RequestAttack(player, playerAttack, preyModel), "player can attack registered dinosaur NPC")
    Assert.equals(record.State, "Dead", "player attack kills NPC prey")
    Assert.notNil(record.Carcass, "player-killed NPC leaves carcass")
    Assert.truthy(CollectionService:HasTag(record.Carcass, "FoodSource"), "player-killed NPC carcass is food")
    root.Position = record.Carcass:GetPivot().Position + Vector3.new(0, 0, -3)
    state.Hunger = 30
    RateLimitService:ClearPlayer(player)
    Assert.truthy(FoodWaterService:RequestEat(player, record.Carcass), "carnivore player eats NPC carcass")
    Assert.truthy(state.Hunger > 30, "NPC carcass restores hunger")
    Assert.equals(record.Carcass:GetAttribute("LastFoodState"), "Depleted", "eaten carcass depletes into remains")
    Assert.equals(record.Carcass:GetAttribute("CarcassConsumed"), true, "player-eaten carcass enters consumed state")
    Assert.falsy(CollectionService:HasTag(record.Carcass, "FoodSource"), "consumed carcass is no longer edible")
    local bonesName = record.Carcass:GetAttribute("BonesReplacement")
    Assert.truthy((bonesName or "") ~= "", "depleted carcass records bones replacement")
    Assert.notNil(workspace:FindFirstChild(bonesName, true), "depleted carcass leaves readable bone remains in world")

    Assert.truthy(CityDiscoveryService:Discover(player, "ApocalypticCity"), "city discovered")
    local fossil = Instance.new("Part")
    fossil.Position = Vector3.new(2, 3, 0)
    fossil:SetAttribute("FossilReward", 2)
    fossil.Parent = workspace
    CollectionService:AddTag(fossil, "Fossil")
    RateLimitService:ClearPlayer(player)
    Assert.truthy(FossilService:RequestCollect(player, fossil), "fossil reward collected")
    Assert.equals(PlayerDataService:Get(player).Fossils, 2, "save reward applied")

    SurvivalService:Kill(player, "LoopTest")
    Assert.equals(state.Dead, true, "death recorded")
    Assert.equals(state.DeathState, "Dying", "death is readable as dying")
    Assert.equals(state.DiedAtAgeSeconds, state.AgeSeconds, "death records final age")
    local respawned = SurvivalService:Respawn(player)
    Assert.equals(respawned.Hatched, false, "respawn returns egg")
    Assert.equals(PlayerDataService:Get(player).Fossils, 2, "saved reward survives respawn")

    if record.Carcass then record.Carcass:Destroy() end
    eggFood:Destroy(); water:Destroy(); prey:Destroy(); preyModel:Destroy(); fossil:Destroy()
    resetNPCs()
end })

return suite
