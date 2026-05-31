local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local ProgressionService = require(game:GetService("ServerScriptService").Services.ProgressionService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local suite = { name = "ProgressionServiceTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "DNA fossil rewards persist", run = function()
    local p = MockPlayer.new(38001, "ProgressTester")
    local before = PlayerDataService:Get(p).DNA
    Assert.truthy(ProgressionService:OnHatched(p), "hatch reward grants")
    Assert.equals(PlayerDataService:Get(p).DNA, before + 25, "DNA persisted in server data")
end })

table.insert(suite.tests, { name = "unlock cost server deducted", run = function()
    local p = MockPlayer.new(38002, "ProgressTester2")
    PlayerDataService:GrantDNA(p, 300, "test")
    Assert.truthy(PlayerDataService:UnlockSpecies(p, "testSpecies", 250), "unlock with enough DNA succeeds")
    Assert.equals(PlayerDataService:Get(p).DNA, 50, "unlock cost deducted")
end })

table.insert(suite.tests, { name = "city discovery once", run = function()
    local p = MockPlayer.new(38003, "ProgressTester3")
    local ok1 = ProgressionService:OnBiomeDiscovered(p, "ApocalypticCity")
    local ok2 = ProgressionService:OnBiomeDiscovered(p, "ApocalypticCity")
    Assert.truthy(ok1, "first city reward grants")
    Assert.falsy(ok2, "duplicate city reward blocked")
end })

table.insert(suite.tests, { name = "growth stage rewards are deterministic and once-only", run = function()
    local p = MockPlayer.new(38004, "ProgressGrowthTester")
    PlayerDataService:Clear(p)
    ProgressionService:Clear(p)
    local before = PlayerDataService:Get(p).DNA
    local okJuvenile = ProgressionService:OnGrowthStage(p, "Juvenile")
    local okJuvenileDuplicate = ProgressionService:OnGrowthStage(p, "Juvenile")
    local okSubAdult = ProgressionService:OnGrowthStage(p, "SubAdult")
    local okAdult = ProgressionService:OnGrowthStage(p, "Adult")
    local okUnknown, unknownReason = ProgressionService:OnGrowthStage(p, "Elder")

    Assert.truthy(okJuvenile, "juvenile reward grants")
    Assert.falsy(okJuvenileDuplicate, "duplicate juvenile reward blocked")
    Assert.truthy(okSubAdult, "sub-adult reward grants")
    Assert.truthy(okAdult, "adult reward grants")
    Assert.falsy(okUnknown, "unknown stage reward rejected")
    Assert.equals(unknownReason, "no_reward", "unknown stage reason")
    Assert.equals(PlayerDataService:Get(p).DNA, before + 40 + 80 + 150, "stage DNA rewards add once")

    ProgressionService:Clear(p)
    PlayerDataService:Clear(p)
end })

table.insert(suite.tests, { name = "growth alpha transition marks maturity without stale markers", run = function()
    local p = MockPlayer.new(38005, "AlphaGrowthTester")
    local state = SurvivalService:CreateState(p, "carnotaurus")
    state.Hatched = true

    Assert.truthy(SurvivalService:AddGrowth(p, 25), "growth to juvenile succeeds")
    Assert.equals(state.GrowthStage, "Juvenile", "juvenile threshold reached")
    Assert.equals(state.JustMaturedTo, "Juvenile", "maturity marker set")
    Assert.truthy(SurvivalService:AddGrowth(p, 1), "non-stage growth succeeds")
    Assert.equals(state.JustMaturedTo, nil, "maturity marker clears on non-stage tick")

    SurvivalService:AddGrowth(p, 49)
    Assert.equals(state.GrowthStage, "Adult", "adult threshold reached")
    Assert.equals(state.AlphaEligible, true, "adult becomes alpha eligible")
    local adultDamage = SurvivalService:GetEffectiveDamage(p)
    local ok = SurvivalService:PromoteToAlpha(p)
    Assert.truthy(ok, "adult promotes to alpha")
    Assert.equals(state.IsAlpha, true, "alpha flag set")
    Assert.truthy(state.Health > 200, "alpha health buff applied")
    Assert.truthy(SurvivalService:GetEffectiveDamage(p) > adultDamage, "alpha damage buff applied")
end })

table.insert(suite.tests, { name = "needs tick couples hunger damage without refilling underwater oxygen", run = function()
    local p = MockPlayer.new(38006, "SurvivalCouplingTester")
    local state = SurvivalService:CreateState(p, "gallimimus")
    state.Hatched = true
    state.Hunger = 0
    state.Thirst = 50
    state.Health = 45
    state.Oxygen = 12
    state.Underwater = true

    local ok = SurvivalService:ApplyNeedsTick(p, 1)
    Assert.truthy(ok, "needs tick applies")
    Assert.truthy(state.Health < 45, "empty hunger damages health")
    Assert.equals(state.Oxygen, 12, "needs loop does not refill oxygen while underwater")

    state.Underwater = false
    SurvivalService:ApplyNeedsTick(p, 1)
    Assert.truthy(state.Oxygen > 12, "oxygen recovers after surfacing")
end })

return suite
