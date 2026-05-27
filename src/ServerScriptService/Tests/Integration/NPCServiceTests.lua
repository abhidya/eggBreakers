local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)

local suite = { name = "NPCServiceTests.server", category = "Integration", tests = {} }

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

local function makeTaggedPart(name, tagName, position)
    local part = Instance.new("Part")
    part.Name = name
    part.Position = position or Vector3.new(4, 3, 0)
    part.Parent = workspace
    CollectionService:AddTag(part, tagName)
    return part
end

local function ensureCarcassAsset()
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = ReplicatedStorage
    end
    local asset = library:FindFirstChild("NPCServiceTestBoneCarcass")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "NPCServiceTestBoneCarcass"
        asset.Size = Vector3.new(4, 1, 2)
        asset.Parent = library
    end
    return asset
end

local function resetNPCs()
    NPCService.NPCs = {}
end

table.insert(suite.tests, { name = "NPC hatches at nest then seeks needs and eats/drinks", run = function()
    resetNPCs()
    local npc = makeNPC("NeedsPreyNPC", Vector3.new(0, 3, 0))
    local food = makeTaggedPart("NeedsFern", "FoodSource", Vector3.new(4, 3, 0))
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 30)
    local water = makeTaggedPart("NeedsWater", "WaterSource", Vector3.new(5, 3, 0))
    local ok, record = NPCService:Register(npc, "Prey")

    Assert.truthy(ok, "prey registers")
    Assert.equals(record.State, "HatchAtNest", "starts as nest egg/hatch state")
    Assert.truthy(NPCService:TickBrain(record, {}, 1), "first tick hatches")
    Assert.equals(record.Hatched, true, "record hatched")
    Assert.equals(npc:GetAttribute("Hatched"), true, "instance hatched attribute")

    record.Thirst = 20
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Drink", "thirsty NPC drinks nearby water")
    Assert.truthy(record.Thirst > 20, "drink restores thirst")

    record.Hunger = 20
    record.Thirst = 90
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "hungry NPC eats nearby matching food")
    Assert.equals(food:GetAttribute("Depleted"), true, "NPC depletes food source")

    npc:Destroy(); food:Destroy(); water:Destroy()
end })


table.insert(suite.tests, { name = "hungry herbivore seeks food with target and facing orientation", run = function()
    resetNPCs()
    local npc = makeNPC("GrazingPreyNPC", Vector3.new(0, 3, 0))
    local food = makeTaggedPart("DistantGrazingFern", "FoodSource", Vector3.new(30, 3, 0))
    food:SetAttribute("Diet", "Herbivore")
    food:SetAttribute("Nutrition", 30)
    local ok, record = NPCService:Register(npc, "Prey")
    record.Hatched = true
    record.Hunger = 20
    record.Thirst = 90

    Assert.truthy(ok, "prey registers")
    NPCService:TickBrain(record, {}, 1)

    Assert.equals(record.State, "SeekFood", "hungry herbivore seeks matching plant food")
    Assert.equals(record.FoodTarget, food, "record tracks concrete food target")
    Assert.equals(npc:GetAttribute("FoodTarget"), "DistantGrazingFern", "food target name is visible on NPC")
    Assert.equals(npc:GetAttribute("FoodTargetDiet"), "Herbivore", "food target diet is visible on NPC")
    Assert.equals(npc:GetAttribute("LastBrainAction"), "SeekFood", "seek-food action is visible on NPC")
    Assert.equals(npc:GetAttribute("BrainTargetName"), "DistantGrazingFern", "brain target names the food source")
    Assert.equals(npc:GetAttribute("BrainActionTarget"), "30.0,3.0,0.0", "brain target position recorded")
    local directionToFood = (food.Position - NPCService:GetRecordPosition(record)).Unit
    Assert.truthy(npc:GetPivot().LookVector:Dot(directionToFood) > 0.95, "NPC faces the food target while grazing")

    npc:Destroy(); food:Destroy()
end })

table.insert(suite.tests, { name = "predator chases attacks and prey death leaves carcass", run = function()
    resetNPCs()
    ensureCarcassAsset()
    local predator = makeNPC("BrainPredatorNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("BrainPreyNPC", Vector3.new(6, 3, 0))
    local predatorOk, predatorRecord = NPCService:Register(predator, "Predator")
    local preyOk, preyRecord = NPCService:Register(prey, "Prey")
    predatorRecord.Hatched = true
    preyRecord.Hatched = true
    preyRecord.Health = 20

    Assert.truthy(predatorOk and preyOk, "predator and prey register")
    NPCService:TickBrain(predatorRecord, {}, 1)
    Assert.equals(predatorRecord.State, "Attack", "predator attacks close prey")
    Assert.equals(preyRecord.State, "Dead", "prey dies from attack")
    Assert.notNil(preyRecord.Carcass, "dead prey leaves carcass")
    Assert.truthy(CollectionService:HasTag(preyRecord.Carcass, "FoodSource"), "carcass is food source")

    predator:Destroy(); prey:Destroy(); preyRecord.Carcass:Destroy()
end })

table.insert(suite.tests, { name = "prey flees then hides when badly hurt", run = function()
    resetNPCs()
    local predator = makeNPC("HidePredatorNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("HidePreyNPC", Vector3.new(5, 3, 0))
    local _, predatorRecord = NPCService:Register(predator, "Predator")
    local _, preyRecord = NPCService:Register(prey, "Prey")
    predatorRecord.Hatched = true
    preyRecord.Hatched = true

    NPCService:TickBrain(preyRecord, {}, 1)
    Assert.equals(preyRecord.State, "Flee", "healthy prey flees predator")
    preyRecord.Health = 20
    NPCService:TickBrain(preyRecord, {}, 1)
    Assert.equals(preyRecord.State, "Hide", "hurt prey hides from predator")
    Assert.equals(prey:GetAttribute("Hidden"), true, "hide state visible on instance")

    predator:Destroy(); prey:Destroy()
end })

table.insert(suite.tests, { name = "apex NPC stamps territory event and scares nearby herd", run = function()
    resetNPCs()
    local apex = makeNPC("ApexTyrannosaurusNPC", Vector3.new(0, 3, 0))
    local prey = makeNPC("ApexScaredPreyNPC", Vector3.new(20, 3, 0))
    local apexOk, apexRecord = NPCService:Register(apex, "Apex")
    local preyOk = NPCService:Register(prey, "Prey")
    apexRecord.Hatched = true

    Assert.truthy(apexOk and preyOk, "apex and prey register")
    NPCService:TickBrain(apexRecord, {}, 1)
    Assert.equals(apexRecord.State, "ApexEvent", "apex territory event state")
    Assert.equals(apex:GetAttribute("ApexCategory"), true, "apex flag on instance")
    Assert.equals(apex:GetAttribute("ApexEventActive"), true, "apex event stamped")
    Assert.truthy(apex:GetAttribute("ApexEventAffected") >= 1, "nearby NPC affected")
    Assert.equals(prey:GetAttribute("LastApexThreat"), "ApexTyrannosaurusNPC", "prey sees apex threat")

    apex:Destroy(); prey:Destroy()
end })

table.insert(suite.tests, { name = "herding omnivore eats plant and carcass diets", run = function()
    resetNPCs()
    local omnivore = makeNPC("OviraptorOmnivoreNPC", Vector3.new(0, 3, 0))
    local herdMate = makeNPC("OviraptorHerdMateNPC", Vector3.new(8, 3, 0))
    local plant = makeTaggedPart("MixedFern", "FoodSource", Vector3.new(4, 3, 0))
    plant:SetAttribute("Diet", "Herbivore")
    plant:SetAttribute("Nutrition", 25)
    local carcass = makeTaggedPart("MixedCarcass", "FoodSource", Vector3.new(30, 3, 0))
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("Nutrition", 25)
    local _, record = NPCService:Register(omnivore, "Omnivore")
    local _, mateRecord = NPCService:Register(herdMate, "Omnivore")
    record.Hatched = true
    mateRecord.Hatched = true

    Assert.equals(record.Diet, "Omnivore", "omnivore profile diet")
    record.Hunger = 20
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "omnivore eats nearby plant food")
    Assert.equals(plant:GetAttribute("Depleted"), true, "plant food depleted by omnivore")

    record.Hunger = 20
    carcass:SetAttribute("Depleted", false)
    carcass.Position = Vector3.new(4, 3, 0)
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(record.State, "Eat", "omnivore eats nearby carcass food")
    Assert.equals(carcass:GetAttribute("Depleted"), true, "carcass food depleted by omnivore")

    record.Hunger = 90
    record.Thirst = 90
    NPCService:TickBrain(record, {}, 1)
    Assert.equals(omnivore:GetAttribute("HerdingEnabled"), true, "herding flag on omnivore")
    Assert.truthy((omnivore:GetAttribute("HerdSize") or 0) >= 2, "omnivore herd size stamped")

    omnivore:Destroy(); herdMate:Destroy(); plant:Destroy(); carcass:Destroy()
end })

return suite
