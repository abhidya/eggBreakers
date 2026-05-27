local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local NPCSpawnService = require(game:GetService("ServerScriptService").Services.NPCSpawnService)

local suite = { name = "NPCCountBudgetTest", category = "Performance", tests = {} }

table.insert(suite.tests, { name = "active NPC cap and target are configured", run = function()
    Assert.equals(NPCService.MaxActive, 30)
    Assert.equals(NPCSpawnService.TargetActive, 12)
    Assert.truthy(NPCSpawnService.TargetActive <= NPCService.MaxActive)
end })


table.insert(suite.tests, { name = "minimum active NPC maintenance reaches 12", run = function()
    NPCService.NPCs = {}
    local active = NPCSpawnService:MaintainMinimumActive()
    Assert.equals(active, 12, "maintains exactly target active NPCs")
    Assert.equals(#NPCService.NPCs, 12, "registered NPC count")
end })

return TestRunner.registerSuite(suite)
