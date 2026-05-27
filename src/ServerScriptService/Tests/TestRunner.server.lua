local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)

if RunService:IsStudio() then
    task.defer(function()
        task.wait(1)
        TestRunner.clearSuites()
        local loadResult = TestRunner:LoadSuitesFrom(script.Parent)
        local results = TestRunner.run({ milestone = script:GetAttribute("Milestone") or "LocalStudio" })
        print(("[eggBreakers Tests] suites=%d loaded=%d total=%d passed=%d failed=%d skipped=%d timestamp=%s"):format(
            results.suites,
            loadResult.loaded,
            results.total,
            results.passed,
            results.failed,
            results.skipped,
            results.timestamp
        ))
        for _, failure in ipairs(loadResult.failures) do
            warn(("[eggBreakers Tests] %s %s: %s"):format(failure.module, failure.test or "load", failure.message))
        end
        for _, failure in ipairs(results.failures) do
            warn(("[eggBreakers Tests] %s %s: %s"):format(failure.module, failure.test or "run", failure.message))
        end
        assert(#loadResult.failures == 0 and results.failed == 0, "eggBreakers Studio QA gate failed")
    end)
end
