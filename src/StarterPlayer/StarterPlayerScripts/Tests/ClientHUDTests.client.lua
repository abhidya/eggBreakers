local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)

local suite = { name = "ClientHUDTests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "stat update renders HUD bars", run = function()
    local root = Instance.new("Frame")
    local fill = UIFactory:CreateBar(root, "Health", 12)
    Assert.equals(fill.Name, "Fill", "bar exposes fill frame")
    Assert.notNil(root:FindFirstChild("HealthLabel"), "label created")
    Assert.notNil(root:FindFirstChild("HealthBar"), "bar created")
    fill.Size = UDim2.fromScale(math.clamp(75 / 100, 0, 1), 1)
    Assert.equals(fill.Size.X.Scale, 0.75, "75 health maps to 75% bar fill")
    root:Destroy()
end })

table.insert(suite.tests, { name = "small screen readability gate", run = function()
    local payload = RemoteContracts.StatUpdate.Payload
    Assert.truthy(table.find(payload, "health") ~= nil, "StatUpdate includes health")
    Assert.truthy(table.find(payload, "hunger") ~= nil, "StatUpdate includes hunger")
    Assert.truthy(table.find(payload, "thirst") ~= nil, "StatUpdate includes thirst")
    Assert.truthy(table.find(payload, "stamina") ~= nil, "StatUpdate includes stamina")
    Assert.truthy(table.find(payload, "growthStage") ~= nil, "StatUpdate includes growth stage")
end })

TestRunner.registerSuite(suite)
return suite
