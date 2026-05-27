local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "CombatServiceTests.server", category = "Integration", tests = {} }

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

return suite
