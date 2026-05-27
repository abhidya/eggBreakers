local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)

TestRunner.clearSuites()
require(script.Parent.G013FinalGate)
local results = TestRunner.run({ category = "E2E", milestone = "G013FinalGate" })
script:SetAttribute("Total", results.total)
script:SetAttribute("Passed", results.passed)
script:SetAttribute("Failed", results.failed)
if results.failed > 0 then
    local first = results.failures[1]
    error("G013FinalGate failed: " .. tostring(first and first.message or results.failed), 0)
end
