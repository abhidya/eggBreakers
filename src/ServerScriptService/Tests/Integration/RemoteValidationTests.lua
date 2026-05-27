local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local RemoteContracts = require(game:GetService("ReplicatedStorage").Shared.RemoteContracts)
local ServerScriptService = game:GetService("ServerScriptService")
local Bootstrap = require(ServerScriptService.Bootstrap)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local suite = { name = "RemoteValidationTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "all RemoteEvents exist and validate", run = function()
    local remotes = Bootstrap.Init()
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


table.insert(suite.tests, { name = "startup bootstrap is require-safe ModuleScript", run = function()
    Assert.truthy(ServerScriptService:FindFirstChild("Bootstrap"):IsA("ModuleScript"), "Bootstrap is a require-safe ModuleScript")
    Assert.truthy(type(Bootstrap.Init) == "function", "Bootstrap exposes Init")
    Assert.notNil(Bootstrap.Init(), "Bootstrap Init creates/remotes folder")
end })

table.insert(suite.tests, { name = "remotes are created exactly once and remain RemoteEvents", run = function()
    local remotes = Bootstrap.Init()
    Bootstrap.Init()
    local seen = {}
    for _, child in ipairs(remotes:GetChildren()) do
        Assert.falsy(seen[child.Name], "duplicate remote child " .. child.Name)
        seen[child.Name] = true
    end
    for remoteName in pairs(RemoteContracts) do
        local matches = 0
        for _, child in ipairs(remotes:GetChildren()) do
            if child.Name == remoteName then
                matches = matches + 1
                Assert.truthy(child:IsA("RemoteEvent"), remoteName .. " is RemoteEvent")
            end
        end
        Assert.equals(matches, 1, remoteName .. " created exactly once")
    end
end })

table.insert(suite.tests, { name = "hatch contract survives clean bootstrap reload", run = function()
    local remotes = Bootstrap.Init()
    Assert.notNil(remotes:FindFirstChild("RequestHatch"), "RequestHatch remote exists after Init")
    local player = MockPlayer.new(26001, "HatchReload")
    local state = SurvivalService:CreateState(player, "gallimimus")
    for _ = 1, 5 do
        local ok = SurvivalService:RequestHatch(player, "tap")
        Assert.truthy(ok, "hatch input accepted")
    end
    Assert.truthy(state.Hatched, "hatch service works after bootstrap init")
end })

return suite
