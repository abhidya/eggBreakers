local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local suite = { name = "ClientInputTests.client", category = "Client", tests = {} }

local expectedRequests = {
    RequestHatch = "string",
    RequestSelectSpecies = "string",
    RequestEat = "Instance",
    RequestDrink = "Instance",
    RequestRest = "boolean",
    RequestAttack = "string",
    RequestCall = "string",
    RequestNestAction = "string",
    RequestCollectFossil = "Instance",
}

table.insert(suite.tests, { name = "client only sends remote requests", run = function()
    for remoteName in pairs(expectedRequests) do
        local contract = RemoteContracts[remoteName]
        Assert.notNil(contract, "contract exists for " .. remoteName)
        Assert.equals(contract.Direction, "ClientToServer", remoteName .. " is client request only")
        Assert.truthy(type(contract.RateLimitSeconds) == "number", remoteName .. " has rate limit")
    end
end })

table.insert(suite.tests, { name = "keyboard/tap request mappings", run = function()
    Assert.equals(RemoteContracts.RequestHatch.Arguments.inputType, "string", "hatch input forwards input type")
    Assert.equals(RemoteContracts.RequestAttack.Arguments.attackType, "string", "attack forwards attack type")
    Assert.equals(RemoteContracts.RequestAttack.Arguments.targetInstance, "Instance?", "attack target may be nil")
    Assert.equals(RemoteContracts.RequestNestAction.Arguments.nestInstance, "Instance", "nest action requires target instance")
end })

table.insert(suite.tests, { name = "species selection forwards species id", run = function()
    Assert.equals(RemoteContracts.RequestSelectSpecies.Arguments.speciesId, "string", "species selection forwards species id")
end })

table.insert(suite.tests, { name = "rest forwards boolean intent", run = function()
    Assert.equals(RemoteContracts.RequestRest.Arguments.enabled, "boolean", "rest sends enabled flag")
end })

TestRunner.registerSuite(suite)
return suite
