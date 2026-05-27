local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)

TestRunner.clearSuites()
require(script.Parent.G018FinalGateSuite)

local results = TestRunner.run({ category = "G018FinalGate", milestone = "G018FinalGate" })
script:SetAttribute("Total", results.total)
script:SetAttribute("Passed", results.passed)
script:SetAttribute("Failed", results.failed)
script:SetAttribute("Timestamp", results.timestamp)

if results.failed > 0 then
    local messages = {}
    for _, failure in ipairs(results.failures) do
        table.insert(messages, tostring(failure.test) .. ": " .. tostring(failure.message))
    end
    error("G018FinalGate failed: " .. table.concat(messages, " | "), 0)
end
