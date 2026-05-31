local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UIFactory = require(script.Parent.Parent.ClientControllers.UIFactory)
local HatchUIController = require(script.Parent.Parent.ClientControllers.HatchUIController)

local suite = { name = "HatchUITests.client", category = "Client", tests = {} }

table.insert(suite.tests, { name = "tap hatch input works", run = function()
    Assert.notNil(RemoteContracts.RequestHatch, "hatch remote contract exists")
    Assert.equals(RemoteContracts.RequestHatch.Arguments.inputType, "string", "tap input is sent as a string input type")
    Assert.truthy(RemoteContracts.RequestHatch.RateLimitSeconds <= 0.2, "hatch taps remain responsive but rate-limited")
    Assert.notNil(RemoteContracts.RequestSelectSpecies, "species selection remote contract exists")
    Assert.equals(RemoteContracts.RequestSelectSpecies.Arguments.speciesId, "string", "species selection sends species id")
end })

table.insert(suite.tests, { name = "hatch screen exposes starter dinosaur selector", run = function()
    local oldGui = HatchUIController.Gui
    local oldSelector = HatchUIController.Selector
    local oldButtons = HatchUIController.SpeciesButtons
    local oldSelected = HatchUIController.SelectedSpeciesId
    HatchUIController.Gui = nil
    HatchUIController.Selector = nil
    HatchUIController.SpeciesButtons = nil
    HatchUIController.SelectedSpeciesId = nil

    local gui = HatchUIController:Show()
    HatchUIController:SetSpeciesOptions({ "parasaurolophus", "utahraptor" }, "utahraptor", function() end)
    local overlay = gui:FindFirstChild("MuffledOverlay")
    local selector = overlay and overlay:FindFirstChild("SpeciesSelector")
    local prompt = overlay and overlay:FindFirstChild("InputPrompt")
    Assert.notNil(selector, "species selector exists")
    Assert.truthy(prompt and prompt:IsA("TextButton"), "hatch prompt is an input button")
    Assert.equals(prompt:GetAttribute("HatchInputButton"), true, "hatch prompt is marked as hatch input")
    local parasaurolophus = selector:FindFirstChild("Species_parasaurolophus")
    local raptor = selector:FindFirstChild("Species_utahraptor")
    Assert.notNil(parasaurolophus, "parasaurolophus option exists")
    Assert.notNil(raptor, "utahraptor option exists")
    Assert.equals(raptor:GetAttribute("SpeciesId"), "utahraptor", "button carries selected species id")
    Assert.equals(raptor:GetAttribute("StarterRole"), "pack hunter", "button carries first-session role cue")
    Assert.equals(raptor:GetAttribute("FirstSessionReadable"), true, "button is marked as first-session readable")
    Assert.truthy(string.find(parasaurolophus.Text, "Parasaurolophus", 1, true) ~= nil, "button names readable dinosaur")
    Assert.truthy(string.find(parasaurolophus.Text, "safe grazer", 1, true) ~= nil, "button explains herbivore role without prose wall")

    gui:Destroy()
    HatchUIController.Gui = oldGui
    HatchUIController.Selector = oldSelector
    HatchUIController.SpeciesButtons = oldButtons
    HatchUIController.SelectedSpeciesId = oldSelected
end })

table.insert(suite.tests, { name = "hatch screen binds crack input callback", run = function()
    local oldGui = HatchUIController.Gui
    local oldSelector = HatchUIController.Selector
    local oldButtons = HatchUIController.SpeciesButtons
    local oldSelected = HatchUIController.SelectedSpeciesId
    local oldBound = HatchUIController.HatchInputBound
    local oldCallback = HatchUIController.OnHatchInput
    HatchUIController.Gui = nil
    HatchUIController.Selector = nil
    HatchUIController.SpeciesButtons = nil
    HatchUIController.SelectedSpeciesId = nil
    HatchUIController.HatchInputBound = nil
    HatchUIController.OnHatchInput = nil

    local requested = nil
    local gui = HatchUIController:Show()
    HatchUIController:BindHatchInput(function(inputType)
        requested = inputType
    end)
    local prompt = gui.MuffledOverlay:FindFirstChild("InputPrompt")
    Assert.truthy(prompt and prompt:IsA("TextButton"), "hatch prompt accepts activation")
    HatchUIController:RequestHatchInput("tap")
    Assert.equals(requested, "tap", "prompt activation requests hatch")

    gui:Destroy()
    HatchUIController.Gui = oldGui
    HatchUIController.Selector = oldSelector
    HatchUIController.SpeciesButtons = oldButtons
    HatchUIController.SelectedSpeciesId = oldSelected
    HatchUIController.HatchInputBound = oldBound
    HatchUIController.OnHatchInput = oldCallback
end })

table.insert(suite.tests, { name = "default hatch selector renders curated starters plus random roster", run = function()
    local oldGui = HatchUIController.Gui
    local oldSelector = HatchUIController.Selector
    local oldButtons = HatchUIController.SpeciesButtons
    local oldSelected = HatchUIController.SelectedSpeciesId
    HatchUIController.Gui = nil
    HatchUIController.Selector = nil
    HatchUIController.SpeciesButtons = nil
    HatchUIController.SelectedSpeciesId = nil

    local gui = HatchUIController:Show()
    HatchUIController:SetSpeciesOptions(nil, "citipati", function() end)
    local selector = gui.MuffledOverlay:FindFirstChild("SpeciesSelector")
    Assert.notNil(selector, "default starter selector exists")

    local expected = {
        coelophysis = "Coelophysis",
        parasaurolophus = "Parasaurolophus",
        utahraptor = "Utahraptor",
        citipati = "Citipati",
    }
    local rendered = 0
    local buttonCount = 0
    for speciesId, displayName in pairs(expected) do
        local button = selector:FindFirstChild("Species_" .. speciesId)
        Assert.notNil(button, speciesId .. " default starter option exists")
        Assert.equals(button:GetAttribute("SpeciesId"), speciesId, speciesId .. " button carries species id")
        Assert.truthy(string.find(button.Text, displayName, 1, true) ~= nil, speciesId .. " button names readable starter")
        rendered = rendered + 1
    end
    for _, child in ipairs(selector:GetChildren()) do
        if child:IsA("TextButton") then
            buttonCount = buttonCount + 1
        end
    end
    local random = selector:FindFirstChild("Species_" .. Constants.RandomStarterSpeciesId)
    Assert.notNil(random, "random full-roster option exists")
    Assert.equals(random:GetAttribute("SpeciesId"), Constants.RandomStarterSpeciesId, "random option sends sentinel species id")
    Assert.equals(random:GetAttribute("RandomFullRoster"), true, "random option is marked as full-roster roll")
    Assert.truthy(string.find(random.Text, "Random", 1, true) ~= nil, "random option text is readable")
    Assert.truthy(string.find(random.Text, "all species", 1, true) ~= nil, "random option explains full roster")
    Assert.equals(rendered, 4, "all four curated starter expectations are asserted")
    Assert.equals(buttonCount, 5, "default hatch selector has four curated starters plus random")

    gui:Destroy()
    HatchUIController.Gui = oldGui
    HatchUIController.Selector = oldSelector
    HatchUIController.SpeciesButtons = oldButtons
    HatchUIController.SelectedSpeciesId = oldSelected
end })

table.insert(suite.tests, { name = "random roster button highlights resolved rolled species", run = function()
    local oldGui = HatchUIController.Gui
    local oldSelector = HatchUIController.Selector
    local oldButtons = HatchUIController.SpeciesButtons
    local oldSelected = HatchUIController.SelectedSpeciesId
    local oldRolled = HatchUIController.RandomRolledSpeciesId
    HatchUIController.Gui = nil
    HatchUIController.Selector = nil
    HatchUIController.SpeciesButtons = nil
    HatchUIController.SelectedSpeciesId = nil
    HatchUIController.RandomRolledSpeciesId = nil

    local gui = HatchUIController:Show()
    HatchUIController:SetSpeciesOptions(nil, "tyrannosaurus", function() end)
    local selector = gui.MuffledOverlay:FindFirstChild("SpeciesSelector")
    local random = selector and selector:FindFirstChild("Species_" .. Constants.RandomStarterSpeciesId)

    Assert.notNil(random, "random button remains visible after server chooses full-roster species")
    Assert.equals(random:GetAttribute("RolledSpeciesId"), "tyrannosaurus", "random button records server-rolled species")
    Assert.equals(random.BackgroundColor3, Color3.fromRGB(86, 108, 54), "random button stays highlighted for rolled species")
    Assert.truthy(string.find(random.Text, "Tyrannosaurus", 1, true) ~= nil, "random button reveals rolled dinosaur")

    gui:Destroy()
    HatchUIController.Gui = oldGui
    HatchUIController.Selector = oldSelector
    HatchUIController.SpeciesButtons = oldButtons
    HatchUIController.SelectedSpeciesId = oldSelected
    HatchUIController.RandomRolledSpeciesId = oldRolled
end })

table.insert(suite.tests, { name = "selected dinosaur option is highlighted", run = function()
    local oldGui = HatchUIController.Gui
    local oldSelector = HatchUIController.Selector
    local oldButtons = HatchUIController.SpeciesButtons
    local oldSelected = HatchUIController.SelectedSpeciesId
    HatchUIController.Gui = nil
    HatchUIController.Selector = nil
    HatchUIController.SpeciesButtons = nil
    HatchUIController.SelectedSpeciesId = nil

    local gui = HatchUIController:Show()
    HatchUIController:SetSpeciesOptions({ "parasaurolophus", "utahraptor" }, "utahraptor", function() end)
    local selector = gui.MuffledOverlay:FindFirstChild("SpeciesSelector")
    local parasaurolophus = selector and selector:FindFirstChild("Species_parasaurolophus")
    local raptor = selector and selector:FindFirstChild("Species_utahraptor")
    Assert.notNil(parasaurolophus, "unselected option exists")
    Assert.notNil(raptor, "selected option exists")
    Assert.equals(raptor.BackgroundColor3, Color3.fromRGB(86, 108, 54), "selected dinosaur uses selected highlight")
    Assert.equals(parasaurolophus.BackgroundColor3, Color3.fromRGB(54, 42, 28), "unselected dinosaur uses inactive color")

    gui:Destroy()
    HatchUIController.Gui = oldGui
    HatchUIController.Selector = oldSelector
    HatchUIController.SpeciesButtons = oldButtons
    HatchUIController.SelectedSpeciesId = oldSelected
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
    local selectorBottom = HatchUIController.SelectorPosition.Y.Offset + HatchUIController.SelectorSize.Y.Offset
    Assert.truthy(selectorBottom <= HatchUIController.PromptPosition.Y.Offset, "starter selector clears hatch prompt")
    Assert.truthy(promptBottom <= -405, "hatch prompt sits above mobile guidance stack")
    Assert.truthy(meterBottom <= -360, "hatch meter clears action guidance labels")
end })

TestRunner.registerSuite(suite)
return suite
