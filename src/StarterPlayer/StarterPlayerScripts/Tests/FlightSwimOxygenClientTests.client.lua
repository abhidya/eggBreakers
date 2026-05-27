local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local suite = { name = "FlightSwimOxygenClientTests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "US31 client has flight remote contract", run = function()
    Assert.notNil(RemoteContracts.RequestFlight, "RequestFlight contract exists")
    Assert.equals(RemoteContracts.RequestFlight.Direction, "ClientToServer", "flight request is client to server")
    Assert.equals(RemoteContracts.RequestFlight.Arguments.enabled, "boolean", "flight toggle sends boolean")
    Assert.truthy(RemoteContracts.RequestFlight.RateLimitSeconds <= 0.5, "flight input remains responsive")
end })

table.insert(suite.tests, { name = "US32 client has swim and oxygen stat contracts", run = function()
    Assert.notNil(RemoteContracts.RequestSwim, "RequestSwim contract exists")
    Assert.equals(RemoteContracts.RequestSwim.Arguments.waterInstance, "Instance", "swim request sends water target")
    Assert.truthy(table.find(RemoteContracts.StatUpdate.Payload, "oxygen") ~= nil, "StatUpdate includes oxygen")
    Assert.truthy(table.find(RemoteContracts.StatUpdate.Payload, "swimming") ~= nil, "StatUpdate includes swimming")
    Assert.truthy(table.find(RemoteContracts.StatUpdate.Payload, "flying") ~= nil, "StatUpdate includes flying")
end })

TestRunner.registerSuite(suite)
return suite
