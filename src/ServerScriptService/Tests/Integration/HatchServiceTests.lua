local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "HatchServiceTests.server", category = "Integration", tests = {} }

local function player(id)
    local p = MockPlayer.new(id or 31001, "HatchTester")
    SurvivalService.States[p] = nil
    RateLimitService:ClearPlayer(p)
    return p
end

table.insert(suite.tests, { name = "new player egg state and hatch threshold", run = function()
    local p = player()
    local state = SurvivalService:CreateState(p, "gallimimus")
    Assert.equals(state.Hatched, false, "new player starts as egg")
    for _ = 1, 5 do Assert.truthy(SurvivalService:RequestHatch(p, "tap"), "valid hatch input accepted") end
    Assert.equals(SurvivalService:GetState(p).Hatched, true, "hatch completes at threshold")
end })

table.insert(suite.tests, { name = "hatch rejects invalid state/input", run = function()
    local p = player(31002)
    local ok, reason = SurvivalService:RequestHatch(p, 42)
    Assert.falsy(ok, "non-string hatch input rejected")
    Assert.equals(reason, "bad_input", "bad input reason")
    for _ = 1, 5 do SurvivalService:RequestHatch(p, "tap") end
    ok, reason = SurvivalService:RequestHatch(p, "tap")
    Assert.falsy(ok, "already-hatched player rejected")
    Assert.equals(reason, "invalid_hatch_state", "already hatched reason")
end })

table.insert(suite.tests, { name = "dinosaur/tutorial after hatch", run = function()
    local p = player(31003)
    local state = SurvivalService:CreateState(p, "triceratops")
    for _ = 1, 5 do SurvivalService:RequestHatch(p, "tap") end
    Assert.equals(state.SpeciesId, "triceratops", "species assignment retained")
    Assert.equals(state.Diet, "Herbivore", "diet state available for tutorial/HUD")
end })

return suite
