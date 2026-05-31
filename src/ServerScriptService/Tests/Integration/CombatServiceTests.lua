local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local CollectionService = game:GetService("CollectionService")
local Bootstrap = require(game:GetService("ServerScriptService").Bootstrap)
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
    local asset = library:FindFirstChild("CombatServiceTestDinosaurCarcass")
    if not asset then
        asset = Instance.new("Part")
        asset.Name = "CombatServiceTestDinosaurCarcass"
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

local function withCritChance(chance, fn)
    local previous = CombatService.CritChance
    CombatService.CritChance = chance
    local ok, resultOrError = pcall(fn)
    CombatService.CritChance = previous
    if not ok then
        error(resultOrError, 2)
    end
    return resultOrError
end

table.insert(suite.tests, { name = "server applies damage only", run = function()
    withCritChance(0, function()
        local p, target, state = setup(34001)
        local ok = CombatService:RequestAttack(p, "Bite", target)
        Assert.truthy(ok, "server validates attack")
        Assert.equals(target:GetAttribute("LastServerDamage"), SpeciesConfig[state.SpeciesId].BaseStats[state.GrowthStage].Damage, "hatchling damage applied from config")
        Assert.equals(target:GetAttribute("DamageableHealth"), 16, "real damage reduces target health")
        target:Destroy()
    end)
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
    withCritChance(0, function()
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
    end)
end })

table.insert(suite.tests, { name = "telegraph payload and remote are deterministic", run = function()
    local p, target = setup(34004)
    Bootstrap.Init()

    Assert.notNil(RemoteContracts.CombatTelegraph, "telegraph remote has canonical contract")
    Assert.equals(RemoteContracts.CombatTelegraph.Direction, "ServerToClient", "telegraph direction")
    local contractPayload = RemoteContracts.CombatTelegraph.Payload
    Assert.truthy(table.find(contractPayload, "kind") ~= nil, "telegraph contract includes kind")
    Assert.truthy(table.find(contractPayload, "attackType") ~= nil, "telegraph contract includes attack type")
    Assert.truthy(table.find(contractPayload, "attackerUserId") ~= nil, "telegraph contract includes attacker id")
    Assert.truthy(table.find(contractPayload, "targetPosition") ~= nil, "telegraph contract includes target position")
    Assert.truthy(table.find(contractPayload, "windupSeconds") ~= nil, "telegraph contract includes windup")
    Assert.truthy(ReplicatedStorage.Remotes:FindFirstChild("CombatTelegraph"):IsA("RemoteEvent"), "bootstrap creates telegraph remote from contract")

    local payload = CombatService:BuildAttackTelegraphPayload(p, "HeavyBite", target)
    Assert.equals(payload.kind, "telegraph", "telegraph kind")
    Assert.equals(payload.attackType, "HeavyBite", "telegraph attack type")
    Assert.equals(payload.attackerUserId, p.UserId, "telegraph attacker id")
    Assert.equals(payload.targetName, target.Name, "telegraph target name")
    Assert.equals(payload.windupSeconds, CombatService.WindupSeconds.HeavyBite, "heavy bite windup")
    Assert.equals(payload.position, Vector3.new(0, 3, 0), "attacker position")
    Assert.equals(payload.targetPosition, target.Position, "target position")

    local windup, firedPayload = CombatService:FireAttackTelegraph(p, "HeavyBite", target)
    Assert.equals(windup, CombatService.WindupSeconds.HeavyBite, "fire returns windup")
    Assert.equals(firedPayload.targetName, target.Name, "fire returns payload")
    target:Destroy()
end })

table.insert(suite.tests, { name = "damage feedback payload mirrors authoritative damage outcome", run = function()
    local target = makeNPC("FeedbackApexTarget", Vector3.new(7, 3, 1))
    target:SetAttribute("Health", 20)
    target:SetAttribute("MaxHealth", 20)
    local record = { Health = 11, MaxHealth = 20, Apex = true }

    local payload = CombatService:BuildCombatFeedbackPayload(target, 9, true, record)
    Assert.equals(payload.kind, "damage", "feedback kind")
    Assert.equals(payload.targetName, target.Name, "feedback target name")
    Assert.equals(payload.damage, 9, "feedback damage")
    Assert.equals(payload.targetHealth, 11, "feedback health uses record")
    Assert.equals(payload.targetMaxHealth, 20, "feedback max health uses record")
    Assert.equals(payload.isCrit, true, "feedback crit flag")
    Assert.equals(payload.isApex, true, "feedback apex flag")
    Assert.equals(payload.position, target.PrimaryPart.Position, "feedback target position")
    target:Destroy()
end })

table.insert(suite.tests, { name = "predation handler creates edible player carcass story proof", run = function()
    ensureCarcassAsset()
    local killer = MockPlayer.new(34005, "PredatorStoryKiller")
    local victim = MockPlayer.new(34006, "PredationStoryVictim")
    local killerState = SurvivalService:CreateState(killer, "carnotaurus")
    killerState.Hatched = true
    local victimState = SurvivalService:CreateState(victim, "gallimimus")
    victimState.Hatched = true

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(6, 3, 2)
    local char = Instance.new("Model")
    root.Parent = char
    victim.Character = char

    local ok, carcass = CombatService:HandlePlayerPredation(killer, killerState, victim, victimState)
    Assert.truthy(ok, "predation handled")
    Assert.notNil(carcass, "player carcass created")
    Assert.truthy(CollectionService:HasTag(carcass, "FoodSource"), "player carcass is food source")
    Assert.truthy(CollectionService:HasTag(carcass, "CarnivoreFoodCandidate"), "player carcass feeds predators")
    Assert.equals(carcass:GetAttribute("PlayerCarcass"), true, "player carcass attribute")
    Assert.equals(carcass:GetAttribute("SourcePlayerUserId"), victim.UserId, "victim user id stamped")
    Assert.equals(carcass:GetAttribute("VictimSpeciesId"), victimState.SpeciesId, "victim species stamped")
    Assert.equals(killerState.Growth, 8, "same-stage predation growth reward")

    carcass:Destroy()
    char:Destroy()
end })

return suite
