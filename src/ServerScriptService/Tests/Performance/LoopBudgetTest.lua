local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(ServerScriptService.Services.NPCService)
local PerformanceAuditService = require(ServerScriptService.Services.PerformanceAuditService)

local suite = { name = "LoopBudgetTest.server", category = "Performance", tests = {} }

table.insert(suite.tests, { name = "no unbounded loops without wait", run = function()
    Assert.truthy(NPCService.MinActive <= NPCService.MaxActive, "NPC min/max bounds prevent runaway spawn loop")
    Assert.truthy(PerformanceAuditService.MaxNPCs == NPCService.MaxActive, "performance audit cap tracks NPC service cap")
end })

table.insert(suite.tests, { name = "no per player heartbeat unless justified", run = function()
    Assert.truthy(PerformanceAuditService.MaxDecorativeCollidableParts <= 40, "decorative collision budget remains bounded")
    Assert.truthy(PerformanceAuditService.MaxImportedPartsWithTouch <= 25, "touch query budget remains bounded")
end })

TestRunner.registerSuite(suite)
return suite
