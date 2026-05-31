local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local suite = { name = "DataSchemaTests", category = "Unit", tests = {} }

table.insert(suite.tests, { name = "default data has required fields", run = function()
    local data = PlayerDataService.DefaultData(123)
    Assert.equals(data.SchemaVersion, 1)
    Assert.equals(data.DNA, 0)
    Assert.equals(data.Fossils, 0)
    Assert.truthy(data.UnlockedSpecies.coelophysis)
    Assert.truthy(data.UnlockedSpecies.parasaurolophus)
    Assert.truthy(data.UnlockedSpecies.utahraptor)
    Assert.truthy(data.UnlockedSpecies.citipati)
    Assert.equals(data.UnlockedSpecies.gallimimus, nil)
    Assert.equals(data.UnlockedSpecies.triceratops, nil)
    Assert.equals(data.UnlockedSpecies.velociraptor, nil)
    Assert.equals(data.UnlockedSpecies.carnotaurus, nil)
    Assert.notNil(data.CosmeticsOwned)
    Assert.notNil(data.EquippedCosmetics)
    Assert.notNil(data.Settings)
    Assert.equals(data.LastPlayedAt, 123)
end })

table.insert(suite.tests, { name = "load migrates retired species unlocks", run = function()
    local oldStore = PlayerDataService.Store
    local player = { UserId = 777, Name = "MigrationTester" }
    local ok, err = pcall(function()
        PlayerDataService.Store = {
            GetAsync = function()
                return {
                    UnlockedSpecies = {
                        gallimimus = true,
                        triceratops = true,
                    },
                }
            end,
        }

        local data = PlayerDataService:Load(player)
        Assert.equals(data.UnlockedSpecies.gallimimus, nil, "gallimimus unlock removed")
        Assert.equals(data.UnlockedSpecies.triceratops, nil, "triceratops unlock removed")
        Assert.truthy(data.UnlockedSpecies.coelophysis, "replacement starter unlocked")
        Assert.truthy(data.UnlockedSpecies.utahraptor, "replacement predator unlocked")
    end)
    PlayerDataService.Store = oldStore
    PlayerDataService:Clear(player)
    if not ok then error(err) end
end })

return TestRunner.registerSuite(suite)
