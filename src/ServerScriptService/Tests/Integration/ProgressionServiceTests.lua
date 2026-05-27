local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local ProgressionService = require(game:GetService("ServerScriptService").Services.ProgressionService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
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

return suite
