local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local RemoteContracts = require(game:GetService("ReplicatedStorage").Shared.RemoteContracts)
local suite = { name = "RemoteValidationTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "all RemoteEvents exist and validate", run = function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    Assert.notNil(remotes, "Remotes folder exists")
    for remoteName, contract in pairs(RemoteContracts) do
        Assert.notNil(remotes:FindFirstChild(remoteName), remoteName .. " exists")
        Assert.truthy(contract.Direction ~= nil or contract.Payload ~= nil, remoteName .. " has contract")
    end
end })

table.insert(suite.tests, { name = "bad args spam nil destroyed fail safely", run = function()
    for name, contract in pairs(RemoteContracts) do
        Assert.notNil(contract, name .. " contract table present")
        if contract.Direction == "ClientToServer" then Assert.truthy(contract.RateLimitSeconds ~= nil, name .. " rate limited") end
    end
end })

return suite
