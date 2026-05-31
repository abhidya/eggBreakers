local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
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
    local asset = library:FindFirstChild("PlayableLoopCarcass")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "PlayableLoopCarcass"
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

table.insert(suite.tests, { name = "fresh player egg to death respawn loop is server authoritative", run = function()
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
end })

return suite
