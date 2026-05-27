local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local NestService = require(game:GetService("ServerScriptService").Services.NestService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "NestServiceTests.server", category = "Integration", tests = {} }

local function setup(id, stage)
    local p = MockPlayer.new(id, "NestTester"); RateLimitService:ClearPlayer(p)
    local state = SurvivalService:CreateState(p, "triceratops"); state.Hatched = true; state.GrowthStage = stage or "Adult"
    local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0)
    local char = Instance.new("Model"); root.Parent = char; p.Character = char
    local nest = Instance.new("Part"); nest.Name = "NestZone"; nest.Position = Vector3.new(4, 3, 0); nest.Parent = workspace; CollectionService:AddTag(nest, "NestZone")
    return p, nest, state
end

table.insert(suite.tests, { name = "adult nest succeeds", run = function()
    local p, nest, state = setup(37001, "Adult")
    local ok = NestService:RequestNestAction(p, "Create", nest)
    Assert.truthy(ok, "adult can create nest")
    Assert.equals(state.NestRespawn, nest, "nest respawn saved")
    nest:Destroy()
end })

table.insert(suite.tests, { name = "non adult fails", run = function()
    local p, nest = setup(37002, "Juvenile")
    local ok, reason = NestService:RequestNestAction(p, "Create", nest)
    Assert.falsy(ok, "juvenile cannot create nest")
    Assert.equals(reason, "not_adult", "non-adult reason")
    nest:Destroy()
end })

table.insert(suite.tests, { name = "zone distance cooldown validation", run = function()
    local p, nest = setup(37003, "Adult")
    nest.Position = Vector3.new(100, 3, 0)
    local ok, reason = NestService:RequestNestAction(p, "Create", nest)
    Assert.falsy(ok, "far nest rejected")
    Assert.equals(reason, "too_far", "distance reason")
    nest:Destroy()
end })

return suite
