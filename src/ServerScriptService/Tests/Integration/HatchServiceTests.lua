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

table.insert(suite.tests, { name = "rapid tap cadence stays playable under hatch cooldown", run = function()
    local p = player(31004)
    local accepted = 0
    local now = 100
    for _ = 1, 5 do
        if RateLimitService:Check(p, "RequestHatch", 0.08, now) then
            accepted = accepted + 1
        end
        now = now + 0.09
    end
    Assert.equals(accepted, 5, "five deliberate taps at 0.09s cadence are accepted")

    RateLimitService:ClearPlayer(p)
    Assert.truthy(RateLimitService:Check(p, "RequestHatch", 0.08, 200), "first tap accepted")
    Assert.falsy(RateLimitService:Check(p, "RequestHatch", 0.08, 200.04), "true spam below cooldown still rejected")
end })

table.insert(suite.tests, { name = "rejected hatch taps do not strand egg below threshold", run = function()
    local p = player(31005)
    SurvivalService:CreateState(p, "gallimimus")
    local accepted = 0
    local tapTimes = { 300, 300.04, 300.09, 300.13, 300.18, 300.22, 300.27, 300.31, 300.36 }

    for _, now in ipairs(tapTimes) do
        if RateLimitService:Check(p, "RequestHatch", 0.08, now) then
            local ok = SurvivalService:RequestHatch(p, "tap")
            Assert.truthy(ok, "accepted server hatch input applies")
            accepted = accepted + 1
        end
    end

    local state = SurvivalService:GetState(p)
    Assert.equals(accepted, 5, "mixed rapid/local taps still leaves five accepted server inputs")
    Assert.equals(state.HatchProgress, 100, "server progress reaches hatch threshold")
    Assert.equals(state.Hatched, true, "server hatches without restart after rejected taps")
end })

table.insert(suite.tests, { name = "dinosaur/tutorial after hatch", run = function()
    local p = player(31003)
    local state = SurvivalService:CreateState(p, "triceratops")
    for _ = 1, 5 do SurvivalService:RequestHatch(p, "tap") end
    Assert.equals(state.SpeciesId, "triceratops", "species assignment retained")
    Assert.equals(state.Diet, "Herbivore", "diet state available for tutorial/HUD")
end })

return suite
