local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "CombatServiceTests.server", category = "Integration", tests = {} }


local function ensureCarcassAsset()
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("ImportedAssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "ImportedAssetLibrary"
        library.Parent = game:GetService("ReplicatedStorage")
    end
    local asset = library:FindFirstChild("CombatServiceTestCarcass")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "CombatServiceTestCarcass"
        asset.Size = Vector3.new(4, 1, 2)
        asset.Parent = library
    end
    return asset
end

local function makeNPC(name, position)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(2, 2, 2)
    root.Position = position or Vector3.new(5, 3, 0)
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = workspace
    return model
end

local function setup(id)
    local p = MockPlayer.new(id, "CombatTester"); RateLimitService:ClearPlayer(p)
    local state = SurvivalService:CreateState(p, "carnotaurus"); state.Hatched = true
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local target = Instance.new("Part"); target.Name = "DamageTarget"; target.Position = Vector3.new(5, 3, 0); target.Parent = workspace; CollectionService:AddTag(target, "Damageable")
    return p, target, state
end

table.insert(suite.tests, { name = "server applies damage only", run = function()
    local p, target, state = setup(34001)
    local ok = CombatService:RequestAttack(p, "Bite", target)
    Assert.truthy(ok, "server validates attack")
    Assert.equals(target:GetAttribute("LastServerDamage"), state.Health and 9 or 9, "hatchling damage applied from config")
    Assert.equals(target:GetAttribute("DamageableHealth"), 16, "real damage reduces target health")
    target:Destroy()
end })

table.insert(suite.tests, { name = "cooldown stamina death/carcass flow", run = function()
    local p, target, state = setup(34002)
    state.Stamina = 0
    local ok, reason = CombatService:RequestAttack(p, "Bite", target)
    Assert.falsy(ok, "no stamina rejects")
    Assert.equals(reason, "no_stamina", "stamina reason")
    RateLimitService:ClearPlayer(p); state.Stamina = 100; state.Hatched = false
    ok, reason = CombatService:RequestAttack(p, "Bite", target)
    Assert.falsy(ok, "egg player cannot attack")
    Assert.equals(reason, "not_alive_hatched", "egg attack reason")
    RateLimitService:ClearPlayer(p); state.Hatched = true; state.Dead = true
    ok, reason = CombatService:RequestAttack(p, "Bite", target)
    Assert.falsy(ok, "dead player cannot attack")
    Assert.equals(reason, "not_alive_hatched", "dead reason")
    target:Destroy()
end })


table.insert(suite.tests, { name = "player attack damages registered dinosaur NPC and creates carcass", run = function()
    NPCService.NPCs = {}
    ensureCarcassAsset()
    local p, unusedTarget, state = setup(34003)
    local npc = makeNPC("CombatTargetPreyNPC", Vector3.new(5, 3, 0))
    local ok, record = NPCService:Register(npc, "Prey")
    Assert.truthy(ok, "prey NPC registered")
    Assert.truthy(CollectionService:HasTag(npc, "Damageable"), "registered NPC is combat targetable")
    record.Hatched = true
    record.Health = 9
    npc:SetAttribute("Health", 9)

    local attackOk = CombatService:RequestAttack(p, "Bite", npc)
    Assert.truthy(attackOk, "player attack accepts registered dinosaur NPC target")
    Assert.equals(record.State, "Dead", "NPC record dies from player attack")
    Assert.equals(npc:GetAttribute("Dead"), true, "NPC target marked dead")
    Assert.equals(npc:GetAttribute("LastServerDamage"), SpeciesConfig.carnotaurus.BaseStats.Hatchling.Damage, "species damage stamped")
    Assert.notNil(record.Carcass, "NPC death creates carcass")
    Assert.truthy(CollectionService:HasTag(record.Carcass, "FoodSource"), "created carcass is food")
    Assert.equals(record.Carcass:GetAttribute("Diet"), "Carnivore", "created carcass feeds carnivores")

    npc:Destroy(); record.Carcass:Destroy(); unusedTarget:Destroy(); state.Stamina = 100
end })

return suite
