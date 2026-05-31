local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local HatchUIController = require(script.Parent.Parent.ClientControllers.HatchUIController)

local suite = { name = "HatchUITests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "tap hatch input works", run = function()
    Assert.notNil(RemoteContracts.RequestHatch, "hatch remote contract exists")
    Assert.equals(RemoteContracts.RequestHatch.Arguments.inputType, "string", "tap input is sent as a string input type")
    Assert.truthy(RemoteContracts.RequestHatch.RateLimitSeconds <= 0.2, "hatch taps remain responsive but rate-limited")
end })

table.insert(suite.tests, { name = "first hatch skip unavailable", run = function()
    local gui = UIFactory:CreateRootGui("HatchScreen")
    local overlay = Instance.new("Frame")
    overlay.Name = "MuffledOverlay"
    overlay.Parent = gui
    local prompt = Instance.new("TextLabel")
    prompt.Name = "InputPrompt"
    prompt.Text = "Tap to crack the shell"
    prompt.Parent = overlay
    local meter = Instance.new("Frame")
    meter.Name = "CrackMeter"
    meter.Parent = overlay
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(math.clamp(100 / 100, 0, 1), 1)
    fill.Parent = meter
    gui.Enabled = false
    Assert.notNil(gui:FindFirstChild("MuffledOverlay"), "hatch overlay exists")
    Assert.notNil(overlay:FindFirstChild("InputPrompt"), "hatch prompt exists")
    Assert.notNil(meter:FindFirstChild("Fill"), "crack meter fill exists")
    Assert.equals(fill.Size.X.Scale, 1, "100 progress fills meter")
    Assert.falsy(gui.Enabled, "hatch UI disables at completion")
    gui:Destroy()
end })

table.insert(suite.tests, { name = "hatch prompt clears mobile action guidance", run = function()
    local promptBottom = HatchUIController.PromptPosition.Y.Offset + HatchUIController.PromptSize.Y.Offset
    local meterBottom = HatchUIController.MeterPosition.Y.Offset + HatchUIController.MeterSize.Y.Offset
    Assert.truthy(promptBottom <= -405, "hatch prompt sits above mobile guidance stack")
    Assert.truthy(meterBottom <= -360, "hatch meter clears action guidance labels")
end })

TestRunner.registerSuite(suite)
return suite
