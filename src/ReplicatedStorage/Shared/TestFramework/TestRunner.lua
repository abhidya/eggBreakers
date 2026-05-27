local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TestUtils = require(ReplicatedStorage.Shared.TestFramework.TestUtils)

local TestRunner = {}
TestRunner.Categories = { "Unit", "Integration", "Placement", "E2E", "Security", "Performance", "Client" }
TestRunner._registeredSuites = {}
TestRunner._registeredByName = {}

function TestRunner.registerSuite(suite)
    assert(type(suite) == "table", "suite must be a table")
    assert(type(suite.name) == "string", "suite.name required")
    assert(type(suite.tests) == "table", "suite.tests required")
    assert(type(suite.category) == "string", "suite.category required")
    if not TestRunner._registeredByName[suite.name] then
        table.insert(TestRunner._registeredSuites, suite)
        TestRunner._registeredByName[suite.name] = true
    end
    return suite
end

function TestRunner.clearSuites()
    TestRunner._registeredSuites = {}
    TestRunner._registeredByName = {}
end

function TestRunner:_matchesCategory(suite, category)
    return not category or category == "All" or suite.category == category
end

function TestRunner:_runSuite(suite, context, results)
    if type(suite.tests) ~= "table" or #suite.tests == 0 then
        results.failed = results.failed + 1
        table.insert(results.failures, { module = suite.name or "unknown", test = "suite_not_empty", message = "suite has no tests" })
        return
    end
    for _, testCase in ipairs(suite.tests) do
        results.total = results.total + 1
        local passed, err = pcall(testCase.run, context)
        if passed then
            results.passed = results.passed + 1
        else
            results.failed = results.failed + 1
            table.insert(results.failures, { module = suite.name, test = testCase.name, message = tostring(err) })
        end
    end
end

function TestRunner:LoadSuitesFrom(container)
    local loaded = 0
    local failures = {}
    if not container then
        table.insert(failures, { module = "TestRunner", test = "container", message = "missing test container" })
        return { loaded = loaded, failures = failures }
    end
    for _, descendant in ipairs(container:GetDescendants()) do
        if descendant:IsA("ModuleScript") then
            local loadTarget = descendant:Clone()
            loadTarget.Name = descendant.Name .. "_FreshLoad"
            loadTarget.Parent = descendant.Parent
            local ok, suiteOrErr = pcall(require, loadTarget)
            loadTarget:Destroy()
            if ok then
                loaded = loaded + 1
                if type(suiteOrErr) == "table" and suiteOrErr.name and suiteOrErr.tests then
                    self.registerSuite(suiteOrErr)
                end
            else
                table.insert(failures, { module = descendant:GetFullName(), test = "require", message = tostring(suiteOrErr) })
            end
        end
    end
    return { loaded = loaded, failures = failures }
end

function TestRunner:CoverageSummary()
    local byCategory = {}
    for _, category in ipairs(self.Categories) do
        byCategory[category] = 0
    end
    for _, suite in ipairs(self._registeredSuites) do
        byCategory[suite.category] = (byCategory[suite.category] or 0) + 1
    end
    return byCategory
end

function TestRunner:_appendCoverageFailures(results)
    local byCategory = self:CoverageSummary()
    for _, category in ipairs(self.Categories) do
        if category ~= "Client" and (byCategory[category] or 0) == 0 then
            results.failed = results.failed + 1
            table.insert(results.failures, { module = "TestRunner", test = "category_coverage", message = "missing registered " .. category .. " suites" })
        end
    end
    if results.total == 0 then
        results.failed = results.failed + 1
        table.insert(results.failures, { module = "TestRunner", test = "non_empty_run", message = "no tests executed" })
    end
end

function TestRunner:_collectModules(root, category)
    local modules = {}
    if not root then return modules end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("ModuleScript") then
            local parentName = descendant.Parent and descendant.Parent.Name or ""
            if not category or category == "All" or parentName == category then
                table.insert(modules, descendant)
            end
        end
    end
    table.sort(modules, function(a, b) return a:GetFullName() < b:GetFullName() end)
    return modules
end

function TestRunner:discover(options)
    options = options or {}
    local serverTests = game:GetService("ServerScriptService"):FindFirstChild("Tests")
    local before = #self._registeredSuites
    for _, moduleScript in ipairs(self:_collectModules(serverTests, options.category)) do
        local loadTarget = moduleScript:Clone()
        loadTarget.Name = moduleScript.Name .. "_FreshDiscover"
        loadTarget.Parent = moduleScript.Parent
        local ok, suiteOrErr = pcall(require, loadTarget)
        loadTarget:Destroy()
        if not ok then
            table.insert(self._registeredSuites, {
                name = moduleScript:GetFullName(),
                category = options.category or "LoadFailure",
                tests = { { name = "module loads", run = function() error(tostring(suiteOrErr)) end } },
            })
        elseif type(suiteOrErr) == "table" and suiteOrErr.name and suiteOrErr.tests then
            self.registerSuite(suiteOrErr)
        end
    end
    return #self._registeredSuites - before
end

function TestRunner.runRegistered(options)
    options = options or {}
    local context = {
        milestone = options.milestone or "Unspecified",
        isStudio = RunService:IsStudio(),
        isServer = RunService:IsServer(),
        isClient = RunService:IsClient(),
    }
    TestRunner:discover(options)
    local results = {
        timestamp = TestUtils.timestamp(),
        milestone = context.milestone,
        category = options.category or "All",
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        failures = {},
        suites = #TestRunner._registeredSuites,
        coverage = TestRunner:CoverageSummary(),
    }
    for _, suite in ipairs(TestRunner._registeredSuites) do
        if TestRunner:_matchesCategory(suite, options.category) then
            TestRunner:_runSuite(suite, context, results)
        end
    end
    if options.allowEmpty ~= true and (not options.category or options.category == "All") then
        TestRunner:_appendCoverageFailures(results)
    end
    results.suites = #TestRunner._registeredSuites
    results.coverage = TestRunner:CoverageSummary()
    return results
end

TestRunner.run = TestRunner.runRegistered

return TestRunner
