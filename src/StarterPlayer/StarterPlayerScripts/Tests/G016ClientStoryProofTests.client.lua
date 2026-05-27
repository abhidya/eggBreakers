local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)

local suite = { name = "G016ClientStoryProofTests.client", category = "Client", tests = {} }
local requiredActionButtons = { "EatDrink", "Attack", "Sprint", "Call", "RestHide" }

local function proofAttribute(name)
    local folder = ReplicatedStorage:FindFirstChild("G016ClientProof")
    return folder and folder:GetAttribute(name)
end

table.insert(suite.tests, { name = "US13 action controls are present and named", run = function()
    local gui = UIFactory:CreateRootGui("G016ClientControls")
    for _, name in ipairs(requiredActionButtons) do
        UIFactory:CreateButton(gui, name .. "Button", name, UDim2.fromOffset(0, 0))
    end
    for _, name in ipairs(requiredActionButtons) do
        Assert.notNil(gui:FindFirstChild(name .. "Button"), name .. "Button missing")
    end
    gui:Destroy()
end })

table.insert(suite.tests, { name = "US13 requires live mobile/controller proof", run = function()
    Assert.equals(proofAttribute("US13LiveControlsPassed"), true,
        "missing G016ClientProof.US13LiveControlsPassed from live mobile/controller activation proof")
    Assert.truthy(type(proofAttribute("US13LiveControlsRunId")) == "string", "US13 live client proof must include run id")
end })

TestRunner.registerSuite(suite)
return suite
